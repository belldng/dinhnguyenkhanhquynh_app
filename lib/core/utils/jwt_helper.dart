import 'package:jwt_decoder/jwt_decoder.dart';

class JwtHelper {
  static bool isTokenValid(String? token) {
    if (token == null || token.isEmpty) return false;
    try {
      return !JwtDecoder.isExpired(token);
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic>? decode(String token) {
    try {
      return JwtDecoder.decode(token);
    } catch (_) {
      return null;
    }
  }

  static String? getRole(String token) {
    final decoded = decode(token);
    if (decoded == null) return null;
    return decoded['role'] ??
        decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
  }

  static String? getUserId(String token) {
    final decoded = decode(token);
    if (decoded == null) return null;
    return decoded['sub'];
  }

  static String? getFullName(String token) {
    final decoded = decode(token);
    if (decoded == null) return null;
    return decoded['fullName'];
  }
}
