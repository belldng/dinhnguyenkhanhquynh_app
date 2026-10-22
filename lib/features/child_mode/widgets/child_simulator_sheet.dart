import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';

class ChildSimulatorSheet extends StatefulWidget {
  final String deviceId;

  const ChildSimulatorSheet({super.key, required this.deviceId});

  @override
  State<ChildSimulatorSheet> createState() => _ChildSimulatorSheetState();
}

class _ChildSimulatorSheetState extends State<ChildSimulatorSheet> {
  double _noiseDb = 55.0;
  int _motionState = 1; // 1: Stationary, 2: Walking, 3: Running, 4: InVehicle
  int _batteryLevel = 85;
  String _locationPreset = 'Trường học';

  final Map<String, Map<String, dynamic>> _locations = {
    'Trường học': {
      'lat': 10.776889,
      'lng': 106.700806,
      'address': 'Trường Tiểu học Chu Văn An, Quận 1',
    },
    'Công viên': {
      'lat': 10.779784,
      'lng': 106.699018,
      'address': 'Công viên 30/4, Quận 1',
    },
    'Nhà riêng': {
      'lat': 10.785000,
      'lng': 106.715000,
      'address': 'Khu dân cư Sala, TP. Thủ Đức',
    },
    'Đang di chuyển': {
      'lat': 10.772000,
      'lng': 106.690000,
      'address': 'Đường Nguyễn Thị Minh Khai',
    },
  };

  bool _isSending = false;

  Future<void> _sendSimulatedData() async {
    setState(() => _isSending = true);

    final deviceId = widget.deviceId.isNotEmpty
        ? widget.deviceId
        : await LocalStorage.getDeviceId() ?? '7f1db81f-e805-4244-b719-ea55b49bc02b';

    final locData = _locations[_locationPreset]!;

    // 1. Send Location GPS
    await ApiClient.post(ApiEndpoints.reportLocation, {
      'deviceId': deviceId,
      'latitude': locData['lat'],
      'longitude': locData['lng'],
      'accuracy': 8.5,
      'speed': _motionState == 2 ? 4.5 : (_motionState == 4 ? 35.0 : 0.0),
      'addressText': locData['address'],
    });

    // 2. Send Sensor Data (Noise & Motion)
    await ApiClient.post(ApiEndpoints.reportSensor, {
      'deviceId': deviceId,
      'noiseLevelDb': _noiseDb,
      'motionState': _motionState,
      'accelerometerX': 0.1,
      'accelerometerY': 0.2,
      'accelerometerZ': 9.8,
    });

    // 3. Send Heartbeat & Battery
    await ApiClient.post(ApiEndpoints.updateHeartbeat(deviceId), {
      'batteryLevel': _batteryLevel,
      'isOnline': true,
    });

    if (!mounted) return;
    setState(() => _isSending = false);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Đã gửi toạ độ "$_locationPreset" và tiếng ồn ${_noiseDb.toInt()}dB lên máy Phụ huynh thành công!'),
        backgroundColor: AppColors.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Bộ Giả Lập Cảm Biến & GPS (Simulator)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Location Presets
            const Text(
              '1. Chọn Toạ độ Vị trí GPS giả lập:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _locations.keys.map((name) {
                final selected = _locationPreset == name;
                return ChoiceChip(
                  label: Text(name),
                  selected: selected,
                  selectedColor: AppColors.primaryLight,
                  onSelected: (val) {
                    if (val) setState(() => _locationPreset = name);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Noise level Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '2. Mức độ tiếng ồn xung quanh:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${_noiseDb.toInt()} dB',
                  style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
            Slider(
              value: _noiseDb,
              min: 30,
              max: 100,
              divisions: 70,
              activeColor: _noiseDb < 60
                  ? AppColors.accentGreen
                  : (_noiseDb < 80 ? AppColors.accentOrange : AppColors.danger),
              onChanged: (val) => setState(() => _noiseDb = val),
            ),
            const SizedBox(height: 14),

            // Motion State
            const Text(
              '3. Trạng thái vận động (Gia tốc kế):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Ngồi yên'),
                  selected: _motionState == 1,
                  selectedColor: AppColors.primaryLight,
                  onSelected: (v) => setState(() => _motionState = 1),
                ),
                ChoiceChip(
                  label: const Text('Đi bộ'),
                  selected: _motionState == 2,
                  selectedColor: AppColors.primaryLight,
                  onSelected: (v) => setState(() => _motionState = 2),
                ),
                ChoiceChip(
                  label: const Text('Chạy nhảy'),
                  selected: _motionState == 3,
                  selectedColor: AppColors.primaryLight,
                  onSelected: (v) => setState(() => _motionState = 3),
                ),
                ChoiceChip(
                  label: const Text('Đi xe máy/ô tô'),
                  selected: _motionState == 4,
                  selectedColor: AppColors.primaryLight,
                  onSelected: (v) => setState(() => _motionState = 4),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Battery Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '4. Phần trăm Pin:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '$_batteryLevel%',
                  style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
            Slider(
              value: _batteryLevel.toDouble(),
              min: 5,
              max: 100,
              divisions: 95,
              activeColor: AppColors.accentGreen,
              onChanged: (val) => setState(() => _batteryLevel = val.toInt()),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSending ? null : _sendSimulatedData,
              child: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('BẮN DỮ LIỆU LÊN SERVER NGAY'),
            ),
          ],
        ),
      ),
    );
  }
}
