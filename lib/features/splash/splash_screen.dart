import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/jwt_helper.dart';
import '../auth/login_screen.dart';
import '../child_mode/child_home_screen.dart';
import '../parent_shell/parent_main_scaffold.dart';
import '../admin/admin_dashboard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    final nav = Navigator.of(context);
    await Future.delayed(const Duration(milliseconds: 1800));
    final token = await LocalStorage.getAccessToken();
    if (!mounted) return;
    if (JwtHelper.isTokenValid(token)) {
      final role = await LocalStorage.getUserRole() ?? 'Parent';
      if (role == 'Admin') {
        nav.pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else if (role == 'Child') {
        nav.pushReplacement(
          MaterialPageRoute(builder: (_) => const ChildHomeScreen()),
        );
      } else {
        nav.pushReplacement(
          MaterialPageRoute(builder: (_) => const ParentMainScaffold()),
        );
      }
    } else {
      nav.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLight,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Family Safety',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bảo vệ & Quản lý Sử dụng Điện thoại Trẻ em',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
