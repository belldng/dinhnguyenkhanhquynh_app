import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/app_providers.dart';
import '../qr_pairing/parent_qr_generator_screen.dart';

class SensorMonitoringTab extends ConsumerStatefulWidget {
  const SensorMonitoringTab({super.key});

  @override
  ConsumerState<SensorMonitoringTab> createState() =>
      _SensorMonitoringTabState();
}

class _SensorMonitoringTabState extends ConsumerState<SensorMonitoringTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(devicesProvider.notifier).fetchMyChildren().then((_) {
      final devState = ref.read(devicesProvider);
      if (devState.devices.isNotEmpty) {
        ref
            .read(sensorProvider.notifier)
            .fetchRealtimeSensor(devState.devices.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sensorState = ref.watch(sensorProvider);
    final devState = ref.watch(devicesProvider);
    final currentDevice =
        devState.selectedDevice ?? devState.devices.firstOrNull;

    // 1. Loading State
    if (devState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cảm Biến Môi Trường')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Empty State khi chưa ghép nối thiết bị con nào
    if (devState.devices.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cảm Biến Môi Trường')),
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
                    Icons.sensors_off_rounded,
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
                  'Bạn chưa liên kết với thiết bị nào của con. Vui lòng tạo mã QR để ghép nối với điện thoại của bé trước khi theo dõi cảm biến môi trường.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
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

    // 3. Có thiết bị đã liên kết
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cảm Biến Môi Trường'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sensors_rounded,
                        color: AppColors.primaryDark, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thiết bị: ${currentDevice?.childNickname ?? "Máy của con"}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Giám sát mức độ tiếng ồn xung quanh và phát hiện vận động qua gia tốc kế',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Noise Level Gauge Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.volume_up_rounded,
                              color: AppColors.primaryDark),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cường Độ Tiếng Ồn Xung Quanh',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (sensorState.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: CircularProgressIndicator(),
                        )
                      else if (sensorState.realtimeSensor == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Icon(Icons.mic_none_rounded,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text(
                                'Chưa Có Dữ Liệu Âm Thanh',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Đang chờ ${currentDevice?.childNickname ?? "thiết bị con"} gửi thông số cảm biến môi trường.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      else
                        Builder(
                          builder: (context) {
                            final sensor = sensorState.realtimeSensor!;
                            final db = sensor.noiseLevelDb;

                            Color gaugeColor;
                            String statusText;
                            IconData statusIcon;

                            if (db < 55) {
                              gaugeColor = AppColors.accentGreen;
                              statusText = 'Yên tĩnh (Phù hợp để học bài)';
                              statusIcon = Icons.check_circle_outline;
                            } else if (db < 75) {
                              gaugeColor = AppColors.accentOrange;
                              statusText =
                                  'Bình thường (Môi trường gia đình/lớp học)';
                              statusIcon = Icons.info_outline;
                            } else {
                              gaugeColor = AppColors.danger;
                              statusText =
                                  'Rất ồn ào! (Nơi đông người hoặc TV lớn)';
                              statusIcon = Icons.warning_amber_rounded;
                            }

                            return Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 150,
                                      height: 150,
                                      child: CircularProgressIndicator(
                                        value: (db / 100.0).clamp(0.0, 1.0),
                                        strokeWidth: 14,
                                        backgroundColor: Colors.grey.shade200,
                                        color: gaugeColor,
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          db.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.bold,
                                            color: gaugeColor,
                                          ),
                                        ),
                                        const Text(
                                          'Decibels (dB)',
                                          style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // Assessment Badge (Flexible to prevent right overflow)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: gaugeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon,
                                          size: 18, color: gaugeColor),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                            color: gaugeColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Motion & Activity State Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.directions_run_rounded,
                              color: AppColors.primaryDark),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Trạng Thái Hoạt Động Của Trẻ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (sensorState.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (sensorState.realtimeSensor == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Chưa nhận được dữ liệu gia tốc kế từ thiết bị của con.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        )
                      else
                        Builder(
                          builder: (context) {
                            final sensor = sensorState.realtimeSensor!;
                            final motion = sensor.motionDescription.isNotEmpty
                                ? sensor.motionDescription
                                : 'Đang ngồi yên';
                            IconData motionIcon = Icons.chair_rounded;
                            if (motion.contains('đi bộ')) {
                              motionIcon = Icons.directions_walk_rounded;
                            }
                            if (motion.contains('chạy')) {
                              motionIcon = Icons.directions_run_rounded;
                            }
                            if (motion.contains('xe')) {
                              motionIcon = Icons.directions_car_rounded;
                            }

                            return Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    motionIcon,
                                    color: AppColors.primaryDark,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        motion,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Cập nhật tự động từ gia tốc kế phần cứng',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
