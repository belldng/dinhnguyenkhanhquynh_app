import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

class ParentQrGeneratorScreen extends StatefulWidget {
  const ParentQrGeneratorScreen({super.key});

  @override
  State<ParentQrGeneratorScreen> createState() =>
      _ParentQrGeneratorScreenState();
}

class _ParentQrGeneratorScreenState extends State<ParentQrGeneratorScreen> {
  final _nicknameController = TextEditingController(text: 'Bé yêu');
  String? _qrPayload;
  String? _token;
  bool _isLoading = true;
  int _secondsLeft = 900; // 15 phút
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generateQrCode();
  }

  Future<void> _generateQrCode() async {
    setState(() => _isLoading = true);
    final nickname = _nicknameController.text.trim().isNotEmpty
        ? _nicknameController.text.trim()
        : 'Bé yêu';
    final res = await ApiClient.post(ApiEndpoints.generatePairQr, {
      'childNickname': nickname,
    });

    if (res.success && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _qrPayload = data['qrDataPayload'];
        _token = data['pairingToken'];
        _isLoading = false;
        _secondsLeft = 900;
      });
      _startCountdown();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã QR Ghép Nối Thiết Bị'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Quét mã để kết nối máy của con',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mở ứng dụng trên điện thoại của con bạn, chọn "Quét mã QR Phụ huynh" và hướng camera vào mã dưới đây:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Nickname Input
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Biệt danh của con trên máy',
                        hintText: 'Ví dụ: Bé Bo, Con gái...',
                        prefixIcon: Icon(Icons.badge_outlined),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Đổi tên & Tạo mã QR mới',
                    onPressed: _isLoading ? null : _generateQrCode,
                    icon: const Icon(Icons.sync_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // QR Code Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 240,
                        height: 240,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _qrPayload != null
                        ? QrImageView(
                            data: _qrPayload!,
                            version: QrVersions.auto,
                            size: 240.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.primaryDark,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : const SizedBox(
                            width: 240,
                            height: 240,
                            child: Center(
                              child: Text('Lỗi tạo mã QR'),
                            ),
                          ),
              ),
              const SizedBox(height: 24),

              // Token and Expiry timer badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: AppColors.primaryDark, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Hiệu lực còn lại: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_token != null)
                Text(
                  'Mã Token: $_token',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('TẠO MÃ QR MỚI'),
                onPressed: _generateQrCode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
