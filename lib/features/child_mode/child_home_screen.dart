import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../auth/login_screen.dart';
import '../qr_pairing/child_qr_scanner_screen.dart';
import 'widgets/child_simulator_sheet.dart';
import 'widgets/sos_emergency_button.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  final bool _isLocked = false;
  final int _remainingMinutes = 95;

  void _openSimulator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChildSimulatorSheet(
        deviceId: '7f1db81f-e805-4244-b719-ea55b49bc02b',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return Scaffold(
        backgroundColor: const Color(0xFFEF5350),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 84, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'THIẾT BỊ ĐANG KHÓA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Phụ huynh đã tạm khóa màn hình của bạn để bạn tập trung học bài hoặc đi ngủ đúng giờ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 48),
                const SosEmergencyButton(
                  childId: '01a160fe-93f2-79b3-8993-54425838ef46',
                  deviceId: '7f1db81f-e805-4244-b719-ea55b49bc02b',
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hours = _remainingMinutes ~/ 60;
    final mins = _remainingMinutes % 60;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Góc Học Tập & Vui Chơi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Quét QR Phụ huynh',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ChildQrScannerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.science_rounded),
            tooltip: 'Trình giả lập Sensor/GPS',
            onPressed: _openSimulator,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded),
            tooltip: 'Đăng nhập Phụ huynh',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kid Avatar and greeting
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tag_faces_rounded,
                          color: AppColors.primaryDark, size: 32),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, Bé Bo! 🌟',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Hoàn thành bài tập để nhận thêm sao nhé!',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Remaining Screen Time Circle
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: _remainingMinutes / 120.0,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade100,
                            color: AppColors.accentGreen,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${hours}h ${mins}m',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const Text(
                              'Thời gian còn lại',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreenLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '🛡️ Thiết bị đang được bảo vệ an toàn',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Allowed Educational Apps Grid
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ứng Dụng Học Tập Khuyến Khích',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAppShortcut(Icons.translate_rounded, 'Duolingo',
                      Colors.green.shade400),
                  _buildAppShortcut(
                      Icons.videocam_rounded, 'Zoom Lớp', Colors.blue.shade400),
                  _buildAppShortcut(Icons.calculate_rounded, 'Toán Học',
                      Colors.orange.shade400),
                  _buildAppShortcut(Icons.menu_book_rounded, 'Sách Nói',
                      Colors.purple.shade400),
                ],
              ),
              const SizedBox(height: 36),

              // SOS Emergency Big Button at bottom
              const SosEmergencyButton(
                childId: '01a160fe-93f2-79b3-8993-54425838ef46',
                deviceId: '7f1db81f-e805-4244-b719-ea55b49bc02b',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppShortcut(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
