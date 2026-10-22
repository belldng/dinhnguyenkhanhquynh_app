import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../storage/local_storage.dart';

class ApiResponseData<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;

  ApiResponseData({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponseData.fromJson(
      Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponseData<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}

class ApiClient {
  static String get baseUrl {
    // 1. Ưu tiên cấu hình BASE_URL trong assets/.env (dành cho thiết bị thật hoặc custom IP)
    final envBaseUrl = dotenv.env['BASE_URL'];
    if (envBaseUrl != null && envBaseUrl.trim().isNotEmpty) {
      return envBaseUrl.trim();
    }

    // 2. Nếu là Android Emulator và không cấu hình BASE_URL -> dùng 10.0.2.2
    final emulatorBaseUrl =
        dotenv.env['EMULATOR_BASE_URL'] ?? 'http://10.0.2.2:5133/api/v1';

    if (!kIsWeb && Platform.isAndroid) {
      return emulatorBaseUrl;
    }
    return 'http://localhost:5133/api/v1';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await LocalStorage.getAccessToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<ApiResponseData<dynamic>> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      return ApiResponseData(
        success: false,
        message: 'Lỗi kết nối tới Server: $e',
      );
    }
  }

  static Future<ApiResponseData<dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      return ApiResponseData(
        success: false,
        message: 'Lỗi kết nối tới Server: $e',
      );
    }
  }

  static Future<ApiResponseData<dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      return ApiResponseData(
        success: false,
        message: 'Lỗi kết nối tới Server: $e',
      );
    }
  }

  static Future<ApiResponseData<dynamic>> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      return ApiResponseData(
        success: false,
        message: 'Lỗi kết nối tới Server: $e',
      );
    }
  }

  static ApiResponseData<dynamic> _processResponse(http.Response response) {
    try {
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return ApiResponseData.fromJson(body, (data) => data);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponseData(
          success: true,
          message: 'Thao tác thành công (${response.statusCode})',
        );
      }
      return ApiResponseData(
        success: false,
        message: 'Lỗi máy chủ (${response.statusCode}): ${response.body}',
      );
    }
  }
}
