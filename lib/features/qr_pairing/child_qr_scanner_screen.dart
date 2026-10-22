import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_storage.dart';
import '../child_mode/child_home_screen.dart';

class ChildQrScannerScreen extends StatefulWidget {
  const ChildQrScannerScreen({super.key});

  @override
  State<ChildQrScannerScreen> createState() => _ChildQrScannerScreenState();
}

class _ChildQrScannerScreenState extends State<ChildQrScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      String pairingToken = rawValue;
      try {
        final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
        if (decoded.containsKey('token')) {
          pairingToken = decoded['token'];
        }
      } catch (_) {
        // Not a JSON string, treat rawValue as plain token
      }

      final res = await ApiClient.post(ApiEndpoints.pairByQr, {
        'pairingToken': pairingToken,
        'deviceUid': 'DEVICE_${DateTime.now().millisecondsSinceEpoch}',
        'deviceName': 'Điện thoại của Con (Flutter)',
        'platform': 'Android',
        'osVersion': 'Android 14',
      });

      if (!mounted) return;

      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final deviceId = data['id']?.toString();
        final childName = data['childName']?.toString() ?? 'Bé yêu';
        final token = data['accessToken']?.toString();
        final childId = data['childId']?.toString() ?? '';

        if (deviceId != null) {
          await LocalStorage.setDeviceId(deviceId);
        }
        await LocalStorage.setUserRole('Child');
        if (token != null && token.isNotEmpty) {
          await LocalStorage.saveAuthData(
            accessToken: token,
            refreshToken: '',
            userId: childId,
            fullName: childName,
            email: '',
            role: 'Child',
          );
        }

        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Ghép Nối Thành Công! 🎉'),
            content: Text(
                'Thiết bị đã được liên kết với tài khoản Phụ huynh cho bé $childName.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const ChildHomeScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('BẮT ĐẦU SỬ DỤNG'),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty
                ? res.message
                : 'Mã QR không hợp lệ hoặc đã hết hạn.'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xử lý: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Mã QR Phụ Huynh'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _cameraController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.amber);
                  default:
                    return const Icon(Icons.flash_auto, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _handleBarcode,
          ),
          // Viewfinder overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          // Prompt card
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Hướng camera vào mã QR trên màn hình điện thoại của Phụ huynh để kết nối tự động',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
