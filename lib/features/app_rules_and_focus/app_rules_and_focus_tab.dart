import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/providers/app_providers.dart';
import '../qr_pairing/parent_qr_generator_screen.dart';

class AppRulesAndFocusTab extends ConsumerStatefulWidget {
  const AppRulesAndFocusTab({super.key});

  @override
  ConsumerState<AppRulesAndFocusTab> createState() =>
      _AppRulesAndFocusTabState();
}

class _AppRulesAndFocusTabState extends ConsumerState<AppRulesAndFocusTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppItemDto> _installedApps = [];
  bool _isLoadingApps = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // 1. Luôn đồng bộ danh sách thiết bị trước
    await ref.read(devicesProvider.notifier).fetchMyChildren();
    final devProv = ref.read(devicesProvider);

    if (devProv.devices.isNotEmpty) {
      final child = devProv.devices.first;
      ref.read(rulesProvider.notifier).fetchRules(child.childId);
      ref.read(focusProvider.notifier).fetchSchedules(child.childId);
      await _fetchDeviceApps(child.id);
    }
  }

  Future<void> _fetchDeviceApps(String deviceId) async {
    setState(() => _isLoadingApps = true);
    final res = await ApiClient.get(ApiEndpoints.deviceApps(deviceId));
    if (res.success && res.data != null) {
      final list = (res.data as List<dynamic>)
          .map((e) => AppItemDto.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _installedApps = list;
        _isLoadingApps = false;
      });
    } else {
      setState(() => _isLoadingApps = false);
    }
  }

  Future<void> _handleToggleAppBlock(AppItemDto app, bool isBlocked) async {
    if (app.id == null) return;

    // Cập nhật trạng thái lạc quan trên UI
    setState(() {
      final idx = _installedApps.indexWhere((a) => a.id == app.id);
      if (idx != -1) {
        _installedApps[idx] = app.copyWith(isBlocked: isBlocked);
      }
    });

    final res = await ApiClient.post(ApiEndpoints.toggleAppBlock(app.id!), {});
    if (!mounted) return;

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBlocked
              ? 'Đã chặn ứng dụng "${app.appName}"'
              : 'Đã mở khóa ứng dụng "${app.appName}"'),
          backgroundColor:
              isBlocked ? AppColors.danger : AppColors.accentGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Revert nếu API thất bại
      setState(() {
        final idx = _installedApps.indexWhere((a) => a.id == app.id);
        if (idx != -1) {
          _installedApps[idx] = app.copyWith(isBlocked: !isBlocked);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty
              ? res.message
              : 'Không thể cập nhật trạng thái ứng dụng.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showAddFocusDialog(String childId) {
    final titleController = TextEditingController(text: 'Giờ học trên trường');
    int selectedDay = 1;
    TimeOfDay startTime = const TimeOfDay(hour: 7, minute: 30);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 30);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Thêm Lịch Học Tập (Focus Mode)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề thời khóa biểu',
                      hintText: 'Ví dụ: Học thêm Tiếng Anh tối',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chọn thứ trong tuần:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (int d = 1; d <= 7; d++)
                        ChoiceChip(
                          label: Text(d == 7 ? 'CN' : 'T${d + 1}'),
                          selected: selectedDay == d,
                          selectedColor: AppColors.primaryLight,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedDay = d);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: context, initialTime: startTime);
                            if (picked != null) {
                              setModalState(() => startTime = picked);
                            }
                          },
                          child: Text('Bắt đầu: ${startTime.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: context, initialTime: endTime);
                            if (picked != null) {
                              setModalState(() => endTime = picked);
                            }
                          },
                          child: Text('Kết thúc: ${endTime.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  minimumSize: const Size(100, 44),
                ),
                onPressed: () async {
                  final formattedStart =
                      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                  final formattedEnd =
                      '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

                  await ref.read(focusProvider.notifier).createSchedule(
                        childId: childId,
                        title: titleController.text.trim(),
                        dayOfWeek: selectedDay,
                        startTime: formattedStart,
                        endTime: formattedEnd,
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Lưu Lịch'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final devProv = ref.watch(devicesProvider);
    final currentDevice = devProv.devices.firstOrNull;
    final focProv = ref.watch(focusProvider);

    // 1. Loading state
    if (devProv.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quy Tắc & Chế Độ Học')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Empty State khi chưa có thiết bị ghép nối
    if (devProv.devices.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quy Tắc & Chế Độ Học')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phonelink_erase_rounded,
                    size: 48,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Chưa Có Thiết Bị Kết Nối',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn cần ghép nối với điện thoại của con qua mã QR để quản lý danh sách ứng dụng bị chặn và thiết lập lịch tập trung học tập.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_rounded, color: Colors.white),
                  label: const Text('TẠO MÃ QR GHÉP NỐI'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentQrGeneratorScreen(),
                      ),
                    ).then((_) => _loadData());
                  },
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tải lại dữ liệu'),
                  onPressed: _loadData,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Đã có thiết bị ghép nối
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quy Tắc & Chế Độ Học'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          indicatorColor: AppColors.accentOrange,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.apps_rounded), text: 'Chặn / Giới Hạn App'),
            Tab(
                icon: Icon(Icons.school_rounded),
                text: 'Lịch Tập Trung (Focus)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Sub-Tab 1: App Blocking & Limits
          _isLoadingApps
              ? const Center(child: CircularProgressIndicator())
              : _installedApps.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.apps_outage_rounded,
                                size: 54, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            const Text(
                              'Chưa có danh sách ứng dụng trên thiết bị',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Danh sách sẽ tự động xuất hiện khi thiết bị con kết nối. Bấm nút dưới để đồng bộ lại.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh_rounded,
                                  color: Colors.white),
                              label: const Text('Tải lại danh sách'),
                              onPressed: _loadData,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _installedApps.length,
                        itemBuilder: (ctx, idx) {
                          final app = _installedApps[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primaryLight,
                                    child: Icon(
                                      app.categoryId == 1
                                          ? Icons.sports_esports
                                          : (app.categoryId == 2
                                              ? Icons.share
                                              : Icons.apps),
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app.appName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          app.packageName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Switch(
                                        value: app.isBlocked,
                                        activeThumbColor: AppColors.danger,
                                        onChanged: (val) =>
                                            _handleToggleAppBlock(app, val),
                                      ),
                                      Text(
                                        app.isBlocked ? 'Đã Chặn' : 'Cho phép',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: app.isBlocked
                                              ? AppColors.danger
                                              : AppColors.accentGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

          // Sub-Tab 2: Smart Focus Schedules
          focProv.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Scaffold(
                  floatingActionButton: FloatingActionButton.extended(
                    backgroundColor: AppColors.accentOrange,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Thêm Giờ Học',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    onPressed: () {
                      if (currentDevice != null) {
                        _showAddFocusDialog(currentDevice.childId);
                      }
                    },
                  ),
                  body: focProv.schedules.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_outlined,
                                  size: 54, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'Chưa có lịch học tập trung nào',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tạo lịch để tự động khóa các app giải trí khi đến giờ học.',
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            if (currentDevice != null) {
                              await ref
                                  .read(focusProvider.notifier)
                                  .fetchSchedules(currentDevice.childId);
                            }
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: focProv.schedules.length,
                            itemBuilder: (ctx, idx) {
                              final sc = focProv.schedules[idx];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: sc.isActive
                                        ? AppColors.accentGreenLight
                                        : Colors.grey.shade200,
                                    child: Icon(
                                      Icons.school,
                                      color: sc.isActive
                                          ? AppColors.accentGreen
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    sc.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${sc.dayOfWeekName}: ${sc.startTime} - ${sc.endTime}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: sc.isActive,
                                        activeThumbColor: AppColors.accentGreen,
                                        onChanged: (_) {
                                          if (currentDevice != null) {
                                            ref
                                                .read(focusProvider.notifier)
                                                .toggleSchedule(sc.id,
                                                    currentDevice.childId);
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: AppColors.danger),
                                        onPressed: () {
                                          if (currentDevice != null) {
                                            ref
                                                .read(focusProvider.notifier)
                                                .deleteSchedule(sc.id,
                                                    currentDevice.childId);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
        ],
      ),
    );
  }
}

class AppItemDto {
  final String? id;
  final String packageName;
  final String appName;
  final int categoryId;
  final bool isBlocked;

  AppItemDto({
    this.id,
    required this.packageName,
    required this.appName,
    required this.categoryId,
    required this.isBlocked,
  });

  AppItemDto copyWith({
    String? id,
    String? packageName,
    String? appName,
    int? categoryId,
    bool? isBlocked,
  }) {
    return AppItemDto(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      categoryId: categoryId ?? this.categoryId,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  factory AppItemDto.fromJson(Map<String, dynamic> json) {
    return AppItemDto(
      id: json['id']?.toString(),
      packageName: json['packageName'] ?? '',
      appName: json['appName'] ?? '',
      categoryId: json['categoryId'] ?? 5,
      isBlocked: json['isBlocked'] ?? false,
    );
  }
}
