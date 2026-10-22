import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/models.dart';
import '../../data/providers/app_providers.dart';
import '../qr_pairing/parent_qr_generator_screen.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  final MapController _mapController = MapController();
  List<LocationModel> _routeHistory = [];
  bool _showRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(devicesProvider.notifier).fetchMyChildren().then((_) {
      final devProv = ref.read(devicesProvider);
      if (devProv.devices.isNotEmpty) {
        final deviceId = devProv.devices.first.id;
        ref.read(locationProvider.notifier).fetchLatestLocation(deviceId);
      }
    });
  }

  Future<void> _toggleRouteHistory() async {
    final devProv = ref.read(devicesProvider);
    final deviceId = devProv.devices.firstOrNull?.id;
    if (deviceId == null) return;

    if (!_showRoute) {
      final history =
          await ref.read(locationProvider.notifier).fetchHistory(deviceId);
      if (!mounted) return;
      setState(() {
        _routeHistory = history;
        _showRoute = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Đang hiển thị lộ trình di chuyển (${history.length} điểm ghi nhận)'),
          backgroundColor: AppColors.primaryDark,
        ),
      );
    } else {
      setState(() {
        _showRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locProv = ref.watch(locationProvider);
    final devProv = ref.watch(devicesProvider);
    final currentDevice = devProv.devices.firstOrNull;

    // 1. Loading State
    if (devProv.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Định Vị GPS Trẻ Em')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Empty State khi chưa có thiết bị ghép nối
    if (devProv.devices.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Định Vị GPS Trẻ Em')),
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
                    Icons.location_off_rounded,
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
                  'Bạn chưa liên kết thiết bị nào của con. Vui lòng tạo mã QR để quét ghép nối điện thoại của con trước khi theo dõi vị trí GPS thời gian thực.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary, height: 1.4),
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

    // 3. Có thiết bị liên kết: Hiển thị bản đồ thực tế
    final hasRealLocation = locProv.latestLocation != null;
    final defaultPoint = const LatLng(10.776889, 106.700806);
    final LatLng centerPoint = hasRealLocation
        ? LatLng(locProv.latestLocation!.latitude,
            locProv.latestLocation!.longitude)
        : defaultPoint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Định Vị GPS Trẻ Em'),
        actions: [
          if (hasRealLocation)
            IconButton(
              icon: Icon(
                _showRoute ? Icons.route : Icons.polyline_outlined,
                color: _showRoute
                    ? AppColors.accentOrange
                    : AppColors.primaryDark,
              ),
              tooltip: _showRoute ? 'Ẩn lộ trình' : 'Xem lộ trình hôm nay',
              onPressed: _toggleRouteHistory,
            ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Cập nhật vị trí',
            onPressed: () {
              _loadData();
              if (hasRealLocation) {
                _mapController.move(centerPoint, 15.0);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPoint,
              initialZoom: hasRealLocation ? 15.0 : 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.familysafety.app',
              ),
              if (_showRoute && _routeHistory.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeHistory
                          .map((l) => LatLng(l.latitude, l.longitude))
                          .toList(),
                      strokeWidth: 4.5,
                      color: AppColors.accentOrange,
                    ),
                  ],
                ),
              // Chỉ vẽ Marker khi có dữ liệu tọa độ thực tế từ thiết bị
              if (hasRealLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: centerPoint,
                      width: 70,
                      height: 70,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primaryDark, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.child_care_rounded,
                              color: AppColors.primaryDark,
                              size: 28,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              currentDevice?.childNickname ?? 'Bé yêu',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Banner thông báo nếu thiết bị chưa gửi tọa độ GPS đầu tiên
          if (!hasRealLocation)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đang chờ thiết bị ${currentDevice?.childNickname ?? "của bé"} cập nhật tọa độ GPS đầu tiên...',
                        style: TextStyle(
                            fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primaryDark,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentDevice?.childNickname ??
                                    'Thiết bị của con',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasRealLocation
                                    ? (locProv.latestLocation?.addressText ??
                                        'Toạ độ: ${centerPoint.latitude.toStringAsFixed(4)}, ${centerPoint.longitude.toStringAsFixed(4)}')
                                    : 'Chưa có tọa độ thời gian thực',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            hasRealLocation
                                ? 'Độ chính xác: ~${locProv.latestLocation?.accuracy.toInt() ?? 10} mét'
                                : 'Đang dò GPS...',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            hasRealLocation
                                ? 'Tốc độ: ${locProv.latestLocation?.speed.toInt() ?? 0} km/h'
                                : 'Tốc độ: 0 km/h',
                            style: TextStyle(
                              fontSize: 12,
                              color: hasRealLocation
                                  ? AppColors.accentGreen
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
