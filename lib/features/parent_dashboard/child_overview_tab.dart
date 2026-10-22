import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/models.dart';
import '../../data/providers/app_providers.dart';
import '../qr_pairing/parent_qr_generator_screen.dart';

class ChildOverviewTab extends ConsumerStatefulWidget {
  const ChildOverviewTab({super.key});

  @override
  ConsumerState<ChildOverviewTab> createState() => _ChildOverviewTabState();
}

class _ChildOverviewTabState extends ConsumerState<ChildOverviewTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(devicesProvider.notifier).fetchMyChildren().then((_) {
      final devices = ref.read(devicesProvider).devices;
      if (devices.isNotEmpty) {
        final child = devices.first;
        ref.read(analyticsProvider.notifier).fetchDailySummary(child.childId);
      }
    });
  }

  Future<void> _handleInstantLock(DeviceModel device) async {
    final nextLockState = !device.isLockedRemotely;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(nextLockState ? 'Khóa Máy Tức Thì?' : 'Mở Khóa Máy?'),
        content: Text(nextLockState
            ? 'Thiết bị của ${device.childNickname} sẽ bị vô hiệu hóa màn hình ngay lập tức.'
            : 'Mở lại quyền sử dụng bình thường cho ${device.childNickname}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  nextLockState ? AppColors.danger : AppColors.accentGreen,
              minimumSize: const Size(100, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(nextLockState ? 'Khóa Ngay' : 'Mở Khóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(devicesProvider.notifier)
          .toggleDeviceLock(device.id, nextLockState);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nextLockState
              ? 'Đã gửi lệnh khóa máy tới ${device.childNickname}'
              : 'Đã mở khóa thiết bị thành công'),
          backgroundColor:
              nextLockState ? AppColors.danger : AppColors.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final devProv = ref.watch(devicesProvider);
    final anaProv = ref.watch(analyticsProvider);

    if (devProv.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (devProv.devices.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Giám Sát Trẻ Em')),
        body: Center(
          child: Padding(
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
                    Icons.phonelink_setup_rounded,
                    size: 48,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Chưa liên kết thiết bị nào',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hãy tạo mã QR để quét ghép nối với điện thoại của con bạn ngay.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_rounded),
                  label: const Text('TẠO MÃ QR GHÉP NỐI'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ParentQrGeneratorScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentDevice = devProv.selectedDevice ?? devProv.devices.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giám Sát Trẻ Em'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Thêm thiết bị con',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ParentQrGeneratorScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Child Hero Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      currentDevice.isLockedRemotely
                          ? const Color(0xFFEF5350)
                          : AppColors.primary,
                      currentDevice.isLockedRemotely
                          ? const Color(0xFFC62828)
                          : AppColors.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (currentDevice.isLockedRemotely
                              ? AppColors.danger
                              : AppColors.primary)
                          .withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.face_rounded,
                            size: 40,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentDevice.childNickname,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentDevice.deviceName,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: currentDevice.isOnline
                                      ? AppColors.accentGreen
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentDevice.isOnline ? 'Online' : 'Offline',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              currentDevice.batteryLevel > 20
                                  ? Icons.battery_charging_full_rounded
                                  : Icons.battery_alert_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pin: ${currentDevice.batteryLevel}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          currentDevice.isLockedRemotely
                              ? '🔒 ĐANG KHÓA MÁY'
                              : '🔓 Hoạt động bình thường',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Instant Lock Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentDevice.isLockedRemotely
                      ? AppColors.accentGreen
                      : AppColors.danger,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: Icon(
                  currentDevice.isLockedRemotely
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                label: Text(
                  currentDevice.isLockedRemotely
                      ? 'MỞ KHÓA THIẾT BỊ NGAY'
                      : 'KHÓA MÁY TỨC THÌ (INSTANT LOCK)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                onPressed: () => _handleInstantLock(currentDevice),
              ),
              const SizedBox(height: 24),

              // Screen Time Section
              const Text(
                'Thời Lượng Sử Dụng Hôm Nay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (anaProv.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tổng thời gian bật máy',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(anaProv.dailySummary?.totalScreenTimeMinutes ?? 110) ~/ 60}h ${(anaProv.dailySummary?.totalScreenTimeMinutes ?? 110) % 60}m',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.access_time_filled_rounded,
                                size: 32,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 14,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: (anaProv.dailySummary?.educationMinutes ?? 50) > 0
                                      ? (anaProv.dailySummary?.educationMinutes ?? 50)
                                      : 1,
                                  child: Container(color: AppColors.accentGreen),
                                ),
                                Expanded(
                                  flex: (anaProv.dailySummary?.entertainmentMinutes ?? 60) > 0
                                      ? (anaProv.dailySummary?.entertainmentMinutes ?? 60)
                                      : 1,
                                  child: Container(color: AppColors.accentOrange),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.spaceAround,
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                    'Học tập: ${anaProv.dailySummary?.educationMinutes ?? 50}m',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                    'Giải trí: ${anaProv.dailySummary?.entertainmentMinutes ?? 60}m',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Ứng Dụng Mở Nhiều Nhất',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                if (anaProv.dailySummary?.topApps.isEmpty ?? true)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Chưa có thống kê chi tiết từng app.'),
                    ),
                  )
                else
                  ...anaProv.dailySummary!.topApps.map((app) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(
                            app.categoryName.contains('Game')
                                ? Icons.sports_esports
                                : (app.categoryName.contains('Social')
                                    ? Icons.share
                                    : Icons.school),
                            color: AppColors.primaryDark,
                          ),
                        ),
                        title: Text(
                          app.appName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${app.categoryName} • ${app.durationMinutes} phút',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: app.isBlocked
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ĐÃ CHẶN',
                                  style: TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            : const Icon(
                                Icons.check_circle_outline,
                                color: AppColors.accentGreen,
                              ),
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
