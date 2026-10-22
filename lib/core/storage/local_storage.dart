import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyFullName = 'full_name';
  static const String keyEmail = 'email';
  static const String keyUserRole = 'user_role';
  static const String keyDeviceId = 'child_device_id';

  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String fullName,
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAccessToken, accessToken);
    await prefs.setString(keyRefreshToken, refreshToken);
    await prefs.setString(keyUserId, userId);
    await prefs.setString(keyFullName, fullName);
    await prefs.setString(keyEmail, email);
    await prefs.setString(keyUserRole, role);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyRefreshToken);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserRole);
  }

  static Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserRole, role);
  }

  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyFullName);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserId);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyEmail);
  }

  static Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyDeviceId);
  }

  static Future<void> setDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyDeviceId, deviceId);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyAccessToken);
    await prefs.remove(keyRefreshToken);
    await prefs.remove(keyUserId);
    await prefs.remove(keyFullName);
    await prefs.remove(keyEmail);
    await prefs.remove(keyUserRole);
  }
}
