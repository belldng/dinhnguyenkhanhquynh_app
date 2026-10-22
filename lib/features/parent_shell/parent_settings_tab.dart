import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/app_providers.dart';
import '../auth/login_screen.dart';
import '../qr_pairing/parent_qr_generator_screen.dart';

class ParentSettingsTab extends ConsumerStatefulWidget {
  const ParentSettingsTab({super.key});

  @override
  ConsumerState<ParentSettingsTab> createState() => _ParentSettingsTabState();
}

class _ParentSettingsTabState extends ConsumerState<ParentSettingsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sosProvider.notifier).fetchActiveAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final sosAsync = ref.watch(sosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt & Cảnh Báo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (authState.user?.fullName.isNotEmpty == true)
                            ? authState.user!.fullName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.user?.fullName ?? 'Nguyễn Văn Phụ Huynh',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authState.user?.email ?? 'parent@demo.com',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Vai trò: Phụ Huynh (Parent)',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Emergency SOS Alerts Section
            const Text(
              'Cảnh Báo Khẩn Cấp (SOS)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            if (sosAsync.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (sosAsync.alerts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          color: AppColors.accentGreen, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Không có cảnh báo khẩn cấp nào. Trẻ em đang an toàn!',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: sosAsync.alerts.map((al) {
                  return Card(
                    color: AppColors.dangerLight,
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded,
                          color: AppColors.danger, size: 36),
                      title: Text(
                        'Cảnh báo từ ${al.childName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                      subtitle: Text(
                        'Toạ độ: (${al.latitude.toStringAsFixed(4)}, ${al.longitude.toStringAsFixed(4)})\nLúc: ${al.createdAt.toLocal().toString().substring(11, 16)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          minimumSize: const Size(80, 36),
                        ),
                        onPressed: () async {
                          await ref
                              .read(sosProvider.notifier)
                              .resolveAlert(al.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã đóng cảnh báo an toàn'),
                            ),
                          );
                        },
                        child: const Text('ĐÃ XỬ LÝ',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            // Actions Section
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('GHÉP NỐI THÊM THIẾT BỊ CỦA CON'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ParentQrGeneratorScreen()),
                );
              },
            ),
            const SizedBox(height: 14),

            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              label: const Text(
                'ĐĂNG XUẤT KHỎI HỆ THỐNG',
                style: TextStyle(color: AppColors.danger),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
              ),
              onPressed: () async {
                final nav = Navigator.of(context);
                await ref.read(authProvider.notifier).logout();
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
