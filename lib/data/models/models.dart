class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Parent',
      avatarUrl: json['avatarUrl'],
    );
  }
}

class DeviceModel {
  final String id;
  final String childId;
  final String childName;
  final String childNickname;
  final String deviceName;
  final String deviceUid;
  final String platform;
  final String osVersion;
  final int batteryLevel;
  final bool isOnline;
  final bool isLockedRemotely;
  final String? lockReason;
  final DateTime lastActiveAt;

  DeviceModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.childNickname,
    required this.deviceName,
    required this.deviceUid,
    required this.platform,
    required this.osVersion,
    required this.batteryLevel,
    required this.isOnline,
    required this.isLockedRemotely,
    this.lockReason,
    required this.lastActiveAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id']?.toString() ?? '',
      childId: json['childId']?.toString() ?? '',
      childName: json['childName'] ?? '',
      childNickname: json['childNickname'] ?? '',
      deviceName: json['deviceName'] ?? '',
      deviceUid: json['deviceUid'] ?? '',
      platform: json['platform'] ?? 'Android',
      osVersion: json['osVersion'] ?? '',
      batteryLevel: json['batteryLevel'] ?? 100,
      isOnline: json['isOnline'] ?? false,
      isLockedRemotely: json['isLockedRemotely'] ?? false,
      lockReason: json['lockReason'],
      lastActiveAt: DateTime.tryParse(json['lastActiveAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class LocationModel {
  final String id;
  final String deviceId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final String? addressText;
  final DateTime recordedAt;

  LocationModel({
    required this.id,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    this.addressText,
    required this.recordedAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.776889,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.700806,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 10.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      addressText: json['addressText'],
      recordedAt: DateTime.tryParse(json['recordedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class SensorModel {
  final String id;
  final String deviceId;
  final double noiseLevelDb;
  final int motionState;
  final String noiseAssessment;
  final String motionDescription;
  final DateTime recordedAt;

  SensorModel({
    required this.id,
    required this.deviceId,
    required this.noiseLevelDb,
    required this.motionState,
    required this.noiseAssessment,
    required this.motionDescription,
    required this.recordedAt,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      id: json['id']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      noiseLevelDb: (json['noiseLevelDb'] as num?)?.toDouble() ?? 45.0,
      motionState: json['motionState'] ?? 1,
      noiseAssessment: json['noiseAssessment'] ?? 'Bình thường',
      motionDescription: json['motionDescription'] ?? 'Đang ngồi yên',
      recordedAt: DateTime.tryParse(json['recordedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class AppRuleModel {
  final String id;
  final String childId;
  final int? categoryId;
  final String? categoryName;
  final String? installedAppId;
  final String? appName;
  final String? packageName;
  final int dailyLimitMinutes;
  final bool isActive;

  AppRuleModel({
    required this.id,
    required this.childId,
    this.categoryId,
    this.categoryName,
    this.installedAppId,
    this.appName,
    this.packageName,
    required this.dailyLimitMinutes,
    required this.isActive,
  });

  factory AppRuleModel.fromJson(Map<String, dynamic> json) {
    return AppRuleModel(
      id: json['id']?.toString() ?? '',
      childId: json['childId']?.toString() ?? '',
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      installedAppId: json['installedAppId']?.toString(),
      appName: json['appName'],
      packageName: json['packageName'],
      dailyLimitMinutes: json['dailyLimitMinutes'] ?? 60,
      isActive: json['isActive'] ?? true,
    );
  }
}

class FocusScheduleModel {
  final String id;
  final String childId;
  final String title;
  final int dayOfWeek;
  final String dayOfWeekName;
  final String startTime;
  final String endTime;
  final int restrictionMode;
  final bool isActive;

  FocusScheduleModel({
    required this.id,
    required this.childId,
    required this.title,
    required this.dayOfWeek,
    required this.dayOfWeekName,
    required this.startTime,
    required this.endTime,
    required this.restrictionMode,
    required this.isActive,
  });

  factory FocusScheduleModel.fromJson(Map<String, dynamic> json) {
    return FocusScheduleModel(
      id: json['id']?.toString() ?? '',
      childId: json['childId']?.toString() ?? '',
      title: json['title'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 1,
      dayOfWeekName: json['dayOfWeekName'] ?? 'Hàng ngày',
      startTime: json['startTime'] ?? '07:30',
      endTime: json['endTime'] ?? '11:30',
      restrictionMode: json['restrictionMode'] ?? 1,
      isActive: json['isActive'] ?? true,
    );
  }
}

class DailySummaryModel {
  final String date;
  final int totalScreenTimeMinutes;
  final int educationMinutes;
  final int entertainmentMinutes;
  final List<AppUsageStatModel> topApps;

  DailySummaryModel({
    required this.date,
    required this.totalScreenTimeMinutes,
    required this.educationMinutes,
    required this.entertainmentMinutes,
    required this.topApps,
  });

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    final list = (json['topApps'] as List<dynamic>?)
            ?.map((e) => AppUsageStatModel.fromJson(e))
            .toList() ??
        [];
    return DailySummaryModel(
      date: json['date']?.toString() ?? '',
      totalScreenTimeMinutes: json['totalScreenTimeMinutes'] ?? 0,
      educationMinutes: json['educationMinutes'] ?? 0,
      entertainmentMinutes: json['entertainmentMinutes'] ?? 0,
      topApps: list,
    );
  }
}

class AppUsageStatModel {
  final String appName;
  final String packageName;
  final String categoryName;
  final int durationMinutes;
  final bool isBlocked;

  AppUsageStatModel({
    required this.appName,
    required this.packageName,
    required this.categoryName,
    required this.durationMinutes,
    required this.isBlocked,
  });

  factory AppUsageStatModel.fromJson(Map<String, dynamic> json) {
    return AppUsageStatModel(
      appName: json['appName'] ?? '',
      packageName: json['packageName'] ?? '',
      categoryName: json['categoryName'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      isBlocked: json['isBlocked'] ?? false,
    );
  }
}

class SosAlertModel {
  final String id;
  final String childId;
  final String childName;
  final String deviceId;
  final String deviceName;
  final double latitude;
  final double longitude;
  final String? audioRecordingUrl;
  final int status;
  final DateTime createdAt;

  SosAlertModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.deviceId,
    required this.deviceName,
    required this.latitude,
    required this.longitude,
    this.audioRecordingUrl,
    required this.status,
    required this.createdAt,
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    return SosAlertModel(
      id: json['id']?.toString() ?? '',
      childId: json['childId']?.toString() ?? '',
      childName: json['childName'] ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      deviceName: json['deviceName'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      audioRecordingUrl: json['audioRecordingUrl'],
      status: json['status'] ?? 1,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
