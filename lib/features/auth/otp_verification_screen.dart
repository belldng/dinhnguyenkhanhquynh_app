import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/providers/app_providers.dart';
import '../child_mode/child_home_screen.dart';
import '../parent_shell/parent_main_scaffold.dart';
import '../admin/admin_dashboard_screen.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isRegistration;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.isRegistration,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isFetchingOtp = false;

  String get _currentOtpCode => _otpControllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startTimer();
    for (final node in _focusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  void _fillOtpCode(String code) {
    final clean = code.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = i < clean.length ? clean[i] : '';
    }
    setState(() {});
    if (clean.length >= 6) {
      _focusNodes.last.unfocus();
      _handleVerify();
    } else if (clean.isNotEmpty) {
      _focusNodes[clean.length.clamp(0, 5)].requestFocus();
    }
  }

  Future<void> _fetchLatestOtpForTesting() async {
    setState(() => _isFetchingOtp = true);
    try {
      final res = await ApiClient.get(
        '${ApiEndpoints.latestOtp}?email=${Uri.encodeComponent(widget.email)}',
      );
      if (res.success && res.data != null && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final code = data['otpCode']?.toString();
        if (code != null && code.length == 6) {
          _fillOtpCode(code);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã tự động điền mã OTP: $code'),
                backgroundColor: AppColors.accentGreen,
              ),
            );
          }
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty
                ? res.message
                : 'Chưa tìm thấy mã OTP nào đang khả dụng.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy mã OTP: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingOtp = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _currentOtpCode.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 chữ số mã OTP'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    bool success;
    if (widget.isRegistration) {
      success = await ref
          .read(authProvider.notifier)
          .verifyRegistrationOtp(widget.email, code);
    } else {
      success = await ref
          .read(authProvider.notifier)
          .verifyLoginOtp(widget.email, code);
    }

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (success && authState.isAuthenticated) {
      final role = authState.user?.role ?? 'Parent';
      if (role == 'Admin') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (r) => false,
        );
      } else if (role == 'Child') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ChildHomeScreen()),
          (r) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ParentMainScaffold()),
          (r) => false,
        );
      }
    } else {
      final msg = authState.errorMessage ?? 'Mã OTP không đúng hoặc đã hết hạn';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    }
  }

  Widget _buildOtpBoxes() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const spacing = 8.0;
        final boxWidth = ((availableWidth - (spacing * 5)) / 6).clamp(42.0, 52.0);
        const boxHeight = 58.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final isFocused = _focusNodes[index].hasFocus;
            final hasText = _otpControllers[index].text.isNotEmpty;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: spacing / 2),
              width: boxWidth,
              height: boxHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFocused
                      ? AppColors.primary
                      : (hasText ? AppColors.primaryDark : AppColors.cardBorder),
                  width: isFocused ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isFocused ? 0.08 : 0.04),
                    blurRadius: isFocused ? 10 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: index == 0 ? 6 : 1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                    fillColor: Colors.transparent,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    if (value.length > 1) {
                      _fillOtpCode(value);
                      return;
                    }

                    if (value.isNotEmpty) {
                      if (index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else {
                        _focusNodes[index].unfocus();
                        if (_currentOtpCode.length == 6) {
                          _handleVerify();
                        }
                      }
                    } else {
                      if (index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    }
                    setState(() {});
                  },
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Xác Thực OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 48,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isRegistration ? 'Xác thực tài khoản' : 'Xác thực 2FA OTP',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã xác thực 6 số gồm chữ số bảo mật đã được gửi tới:\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),

              // 6-digit Native Flutter OTP Input Boxes (No third-party dependency)
              _buildOtpBoxes(),
              const SizedBox(height: 16),

              // Nút lấy mã OTP trực tiếp từ máy chủ để test nhanh
              InkWell(
                onTap: _isFetchingOtp ? null : _fetchLatestOtpForTesting,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isFetchingOtp)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.flash_on, size: 16, color: AppColors.primaryDark),
                      const SizedBox(width: 6),
                      const Text(
                        'Lấy mã OTP trực tiếp từ máy chủ (Dành cho kiểm thử)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Timer & Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: _secondsRemaining > 0
                        ? AppColors.textSecondary
                        : AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _secondsRemaining > 0
                        ? 'Gửi lại mã sau: $_secondsRemaining giây'
                        : 'Mã đã hết hiệu lực',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _secondsRemaining > 0
                          ? AppColors.textSecondary
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
              if (_secondsRemaining == 0) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _startTimer();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã yêu cầu gửi lại mã OTP mới'),
                      ),
                    );
                  },
                  child: const Text('GỬI LẠI MÃ OTP'),
                ),
              ],
              const SizedBox(height: 32),

              // Verify Button
              ElevatedButton(
                onPressed: authState.isLoading ? null : _handleVerify,
                child: authState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('XÁC NHẬN & ĐĂNG NHẬP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
