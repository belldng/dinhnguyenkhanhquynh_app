import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/jwt_helper.dart';
import '../models/models.dart';

// =============================================================================
// AUTH STATE & NOTIFIER
// =============================================================================

@immutable
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool requiresTwoFactor;
  final String? pendingEmail;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.requiresTwoFactor = false,
    this.pendingEmail,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? requiresTwoFactor,
    String? pendingEmail,
    UserModel? user,
    String? errorMessage,
    bool clearPendingEmail = false,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      requiresTwoFactor: requiresTwoFactor ?? this.requiresTwoFactor,
      pendingEmail: clearPendingEmail ? null : (pendingEmail ?? this.pendingEmail),
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> checkAutoLogin() async {
    state = state.copyWith(isLoading: true);

    final token = await LocalStorage.getAccessToken();
    if (JwtHelper.isTokenValid(token)) {
      final role = await LocalStorage.getUserRole() ?? 'Parent';
      final userId = await LocalStorage.getUserId() ?? '';
      final fullName = await LocalStorage.getFullName() ?? '';
      final email = await LocalStorage.getEmail() ?? '';

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: UserModel(id: userId, fullName: fullName, email: email, role: role),
      );
    } else {
      await LocalStorage.clearAuth();
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<bool> login(String emailOrUsername, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final res = await ApiClient.post(ApiEndpoints.login, {
      'emailOrUsername': emailOrUsername,
      'password': password,
    });

    if (res.success && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      final bool req2fa = data['requiresTwoFactor'] ?? false;
      final String? email = data['email'];

      if (req2fa && email != null) {
        state = state.copyWith(
          isLoading: false,
          requiresTwoFactor: true,
          pendingEmail: email,
        );
        return true;
      } else {
        await _saveAuthResponse(data);
        return true;
      }
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res.message.isNotEmpty ? res.message : 'Đăng nhập thất bại',
      );
      return false;
    }
  }

  Future<bool> verifyLoginOtp(String email, String otpCode) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final res = await ApiClient.post(ApiEndpoints.verifyLoginOtp, {
      'email': email,
      'otpCode': otpCode,
    });

    if (res.success && res.data != null) {
      await _saveAuthResponse(res.data as Map<String, dynamic>);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res.message.isNotEmpty ? res.message : 'Mã OTP không đúng',
      );
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final res = await ApiClient.post(ApiEndpoints.register, {
      'fullName': fullName,
      'email': email,
      'password': password,
      'confirmPassword': password,
      'role': role,
    });

    if (res.success) {
      state = state.copyWith(isLoading: false, pendingEmail: email);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res.message.isNotEmpty ? res.message : 'Đăng ký thất bại',
      );
      return false;
    }
  }

  Future<bool> verifyRegistrationOtp(String email, String otpCode) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final res = await ApiClient.post(ApiEndpoints.verifyRegistrationOtp, {
      'email': email,
      'otpCode': otpCode,
    });

    if (res.success && res.data != null) {
      await _saveAuthResponse(res.data as Map<String, dynamic>);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res.message.isNotEmpty ? res.message : 'Xác thực OTP thất bại',
      );
      return false;
    }
  }

  Future<void> _saveAuthResponse(Map<String, dynamic> data) async {
    final token = data['accessToken'] ?? '';
    final refreshToken = data['refreshToken'] ?? '';
    final userJson = data['user'] as Map<String, dynamic>?;

    final user = userJson != null
        ? UserModel.fromJson(userJson)
        : UserModel(
            id: JwtHelper.getUserId(token) ?? '',
            fullName: JwtHelper.getFullName(token) ?? '',
            email: '',
            role: JwtHelper.getRole(token) ?? 'Parent',
          );

    await LocalStorage.saveAuthData(
      accessToken: token,
      refreshToken: refreshToken,
      userId: user.id,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
    );

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      requiresTwoFactor: false,
      user: user,
      clearPendingEmail: true,
    );
  }

  Future<void> logout() async {
    await LocalStorage.clearAuth();
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// =============================================================================
// DEVICES STATE & NOTIFIER
// =============================================================================

@immutable
class DevicesState {
  final bool isLoading;
  final List<DeviceModel> devices;
  final DeviceModel? selectedDevice;
  final String? errorMessage;

  const DevicesState({
    this.isLoading = false,
    this.devices = const [],
    this.selectedDevice,
    this.errorMessage,
  });

  DevicesState copyWith({
    bool? isLoading,
    List<DeviceModel>? devices,
    DeviceModel? selectedDevice,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DevicesState(
      isLoading: isLoading ?? this.isLoading,
      devices: devices ?? this.devices,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DevicesNotifier extends Notifier<DevicesState> {
  @override
  DevicesState build() => const DevicesState();

  Future<void> fetchMyChildren() async {
    state = state.copyWith(isLoading: true);

    final res = await ApiClient.get(ApiEndpoints.myChildren);
    if (res.success && res.data != null) {
      final devices = (res.data as List<dynamic>)
          .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        isLoading: false,
        devices: devices,
        selectedDevice: devices.isNotEmpty && state.selectedDevice == null
            ? devices.first
            : state.selectedDevice,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res.message,
      );
    }
  }

  void selectDevice(DeviceModel dev) {
    state = state.copyWith(selectedDevice: dev);
  }

  Future<bool> toggleDeviceLock(String deviceId, bool isLocked, {String? reason}) async {
    final res = await ApiClient.post(ApiEndpoints.setDeviceLock(deviceId), {
      'isLocked': isLocked,
      'lockReason': reason ?? (isLocked ? 'Đã tạm khóa từ xa bởi phụ huynh' : null),
    });

    if (res.success) {
      await fetchMyChildren();
      return true;
    }
    return false;
  }
}

final devicesProvider = NotifierProvider<DevicesNotifier, DevicesState>(() {
  return DevicesNotifier();
});

// =============================================================================
// LOCATION STATE & NOTIFIER
// =============================================================================

@immutable
class LocationState {
  final bool isLoading;
  final LocationModel? latestLocation;

  const LocationState({
    this.isLoading = false,
    this.latestLocation,
  });

  LocationState copyWith({
    bool? isLoading,
    LocationModel? latestLocation,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      latestLocation: latestLocation ?? this.latestLocation,
    );
  }
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  Future<void> fetchLatestLocation(String deviceId) async {
    state = state.copyWith(isLoading: true);

    final res = await ApiClient.get(ApiEndpoints.latestLocation(deviceId));
    if (res.success && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        latestLocation: LocationModel.fromJson(res.data as Map<String, dynamic>),
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<List<LocationModel>> fetchHistory(String deviceId, {String? date}) async {
    final query = date != null ? '?date=$date' : '';
    final res = await ApiClient.get('${ApiEndpoints.locationHistory(deviceId)}$query');
    if (res.success && res.data != null) {
      return (res.data as List<dynamic>)
          .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(() {
  return LocationNotifier();
});

// =============================================================================
// SENSOR STATE & NOTIFIER
// =============================================================================

@immutable
class SensorState {
  final bool isLoading;
  final SensorModel? realtimeSensor;

  const SensorState({
    this.isLoading = false,
    this.realtimeSensor,
  });

  SensorState copyWith({
    bool? isLoading,
    SensorModel? realtimeSensor,
  }) {
    return SensorState(
      isLoading: isLoading ?? this.isLoading,
      realtimeSensor: realtimeSensor ?? this.realtimeSensor,
    );
  }
}

class SensorNotifier extends Notifier<SensorState> {
  @override
  SensorState build() => const SensorState();

  Future<void> fetchRealtimeSensor(String deviceId) async {
    state = state.copyWith(isLoading: true);

    final res = await ApiClient.get(ApiEndpoints.realtimeSensor(deviceId));
    if (res.success && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        realtimeSensor: SensorModel.fromJson(res.data as Map<String, dynamic>),
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }
}

final sensorProvider = NotifierProvider<SensorNotifier, SensorState>(() {
  return SensorNotifier();
});

// =============================================================================
// RULES STATE & NOTIFIER
// =============================================================================

@immutable
class RulesState {
  final bool isLoading;
  final List<AppRuleModel> rules;

  const RulesState({
    this.isLoading = false,
    this.rules = const [],
  });

  RulesState copyWith({
    bool? isLoading,
    List<AppRuleModel>? rules,
  }) {
    return RulesState(
      isLoading: isLoading ?? this.isLoading,
      rules: rules ?? this.rules,
    );
  }
}

class RulesNotifier extends Notifier<RulesState> {
  @override
  RulesState build() => const RulesState();

  Future<void> fetchRules(String childId) async {
    state = state.copyWith(isLoading: true);

    final res = await ApiClient.get(ApiEndpoints.childRules(childId));
    if (res.success && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        rules: (res.data as List<dynamic>)
            .map((e) => AppRuleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> createRule({
    required String childId,
    int? categoryId,
    String? installedAppId,
    required int dailyLimitMinutes,
  }) async {
    final res = await ApiClient.post(ApiEndpoints.createRule, {
      'childId': childId,
      'categoryId': categoryId,
      'installedAppId': installedAppId,
      'dailyLimitMinutes': dailyLimitMinutes,
      'isActive': true,
    });
    if (res.success) {
      await fetchRules(childId);
      return true;
    }
    return false;
  }

  Future<bool> deleteRule(String ruleId, String childId) async {
    final res = await ApiClient.delete(ApiEndpoints.deleteRule(ruleId));
    if (res.success) {
      await fetchRules(childId);
      return true;
    }
    return false;
  }
}

final rulesProvider = NotifierProvider<RulesNotifier, RulesState>(() {
  return RulesNotifier();
});

// =============================================================================
// FOCUS SCHEDULE STATE & NOTIFIER
// =============================================================================

@immutable
class FocusState {
  final bool isLoading;
  final List<FocusScheduleModel> schedules;

  const FocusState({
    this.isLoading = false,
    this.schedules = const [],
  });

  FocusState copyWith({
    bool? isLoading,
    List<FocusScheduleModel>? schedules,
  }) {
    return FocusState(
      isLoading: isLoading ?? this.isLoading,
      schedules: schedules ?? this.schedules,
    );
  }
}

class FocusNotifier extends Notifier<FocusState> {
  @override
  FocusState build() => const FocusState();

  Future<void> fetchSchedules(String childId) async {
    state = state.copyWith(isLoading: true);

    final res = await ApiClient.get(ApiEndpoints.focusSchedules(childId));
    if (res.success && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        schedules: (res.data as List<dynamic>)
            .map((e) => FocusScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> createSchedule({
    required String childId,
    required String title,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final res = await ApiClient.post(ApiEndpoints.createFocusSchedule, {
      'childId': childId,
      'title': title,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'restrictionMode': 1,
      'isActive': true,
    });
    if (res.success) {
      await fetchSchedules(childId);
      return true;
    }
    return false;
  }

  Future<bool> toggleSchedule(String scheduleId, String childId) async {
    final res = await ApiClient.put(ApiEndpoints.toggleFocusSchedule(scheduleId), {});
    if (res.success) {
      await fetchSchedules(childId);
      return true;
    }
    return false;
  }

  Future<bool> deleteSchedule(String scheduleId, String childId) async {
    final res = await ApiClient.delete(ApiEndpoints.deleteFocusSchedule(scheduleId));
    if (res.success) {
      await fetchSchedules(childId);
      return true;
    }
    return false;
  }
}

final focusProvider = NotifierProvider<FocusNotifier, FocusState>(() {
  return FocusNotifier();
});

// =============================================================================
// ANALYTICS STATE & NOTIFIER
// =============================================================================

@immutable
class AnalyticsState {
  final bool isLoading;
  final DailySummaryModel? dailySummary;

  const AnalyticsState({
    this.isLoading = false,
    this.dailySummary,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    DailySummaryModel? dailySummary,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      dailySummary: dailySummary ?? this.dailySummary,
    );
  }
}

class AnalyticsNotifier extends Notifier<AnalyticsState> {
  @override
  AnalyticsState build() => const AnalyticsState();

  Future<void> fetchDailySummary(String childId, {String? date}) async {
    state = state.copyWith(isLoading: true);

    final query = date != null ? '?date=$date' : '';
    final res = await ApiClient.get('${ApiEndpoints.dailySummary(childId)}$query');
    if (res.success && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        dailySummary: DailySummaryModel.fromJson(res.data as Map<String, dynamic>),
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }
}

final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsState>(() {
  return AnalyticsNotifier();
});

// =============================================================================
// SOS STATE & NOTIFIER
// =============================================================================

@immutable
class SosState {
  final bool isLoading;
  final List<SosAlertModel> alerts;

  const SosState({
    this.isLoading = false,
    this.alerts = const [],
  });

  SosState copyWith({
    bool? isLoading,
    List<SosAlertModel>? alerts,
  }) {
    return SosState(
      isLoading: isLoading ?? this.isLoading,
      alerts: alerts ?? this.alerts,
    );
  }
}

class SosNotifier extends Notifier<SosState> {
  @override
  SosState build() => const SosState();

  Future<void> fetchActiveAlerts() async {
    state = state.copyWith(isLoading: true);

    final res = await ApiClient.get(ApiEndpoints.activeSos);
    if (res.success && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        alerts: (res.data as List<dynamic>)
            .map((e) => SosAlertModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> resolveAlert(String alertId) async {
    final res = await ApiClient.post(ApiEndpoints.resolveSos(alertId), {});
    if (res.success) {
      await fetchActiveAlerts();
      return true;
    }
    return false;
  }
}

final sosProvider = NotifierProvider<SosNotifier, SosState>(() {
  return SosNotifier();
});
