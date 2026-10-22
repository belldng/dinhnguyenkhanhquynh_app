import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';

class SosEmergencyButton extends StatefulWidget {
  final String childId;
  final String deviceId;

  const SosEmergencyButton({
    super.key,
    required this.childId,
    required this.deviceId,
  });

  @override
  State<SosEmergencyButton> createState() => _SosEmergencyButtonState();
}

class _SosEmergencyButtonState extends State<SosEmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _holdTimer;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHolding() {
    setState(() => _isHolding = true);
    _animController.forward(from: 0.0);
    HapticFeedback.heavyImpact();

    _holdTimer = Timer(const Duration(seconds: 3), () {
      _triggerSosAlert();
    });
  }

  void _stopHolding() {
    if (_animController.isCompleted) return;
    setState(() => _isHolding = false);
    _animController.reset();
    _holdTimer?.cancel();
  }

  Future<void> _triggerSosAlert() async {
    HapticFeedback.vibrate();

    final deviceId = widget.deviceId.isNotEmpty
        ? widget.deviceId
        : await LocalStorage.getDeviceId() ?? '7f1db81f-e805-4244-b719-ea55b49bc02b';

    final childId = widget.childId.isNotEmpty
        ? widget.childId
        : await LocalStorage.getUserId() ?? '01a160fe-93f2-79b3-8993-54425838ef46';

    await ApiClient.post(ApiEndpoints.triggerSos, {
      'childId': childId,
      'deviceId': deviceId,
      'latitude': 10.776889,
      'longitude': 106.700806,
    });

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.dangerLight,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 32),
            SizedBox(width: 8),
            Text('ĐÃ PHÁT CẢNH BÁO SOS! 🚨',
                style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
        content: const Text(
          'Toạ độ GPS khẩn cấp và thông báo đã được gửi tức thời tới điện thoại Phụ huynh. Hãy giữ bình tĩnh và ở yên vị trí an toàn.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isHolding = false);
              _animController.reset();
            },
            child: const Text('TÔI ĐÃ AN TOÀN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => _startHolding(),
          onTapUp: (_) => _stopHolding(),
          onTapCancel: () => _stopHolding(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Progress Ring
              SizedBox(
                width: 130,
                height: 130,
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _animController.value,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: AppColors.danger,
                    );
                  },
                ),
              ),
              // Big SOS Button
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sos_rounded, color: Colors.white, size: 40),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isHolding ? 'ĐANG KÍCH HOẠT... GIỮ NGUYÊN!' : 'Nhấn & Giữ 3 giây để báo động SOS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _isHolding ? AppColors.danger : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
