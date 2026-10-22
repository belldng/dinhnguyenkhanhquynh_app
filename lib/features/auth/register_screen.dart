import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/app_providers.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'Parent';
  bool _obscure = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();

    final success = await ref.read(authProvider.notifier).register(
          fullName: fullName,
          email: email,
          password: password,
          role: _selectedRole,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            isRegistration: true,
          ),
        ),
      );
    } else {
      final msg = ref.read(authProvider).errorMessage ?? 'Đăng ký thất bại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bắt đầu bảo vệ con trẻ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tạo tài khoản quản lý và nhận mã xác thực OTP qua Email',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên của bạn',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                    if (!v.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role selection (Chỉ 2 role: Phụ huynh & Trẻ em, thiết kế Responsive tránh overflow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn vai trò tài khoản:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedRole = 'Parent'),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'Parent'
                                    ? AppColors.primaryLight.withValues(alpha: 0.5)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedRole == 'Parent'
                                      ? AppColors.primary
                                      : AppColors.cardBorder,
                                  width: _selectedRole == 'Parent' ? 2 : 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.family_restroom_rounded,
                                    color: _selectedRole == 'Parent'
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Phụ huynh',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _selectedRole == 'Parent'
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Quản lý con',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedRole = 'Child'),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'Child'
                                    ? AppColors.primaryLight.withValues(alpha: 0.5)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedRole == 'Child'
                                      ? AppColors.primary
                                      : AppColors.cardBorder,
                                  width: _selectedRole == 'Child' ? 2 : 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.child_care_rounded,
                                    color: _selectedRole == 'Child'
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Trẻ em',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _selectedRole == 'Child'
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Thiết bị con',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                    if (v.length < 6) return 'Mật khẩu phải từ 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleRegister,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('TIẾP TỤC & NHẬN MÃ OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
