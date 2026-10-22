import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool get isInitialized => client != null;

  /// Lắng nghe vị trí GPS thời gian thực của thiết bị con qua Supabase Realtime
  static Stream<List<Map<String, dynamic>>>? streamLocation(String deviceId) {
    final supa = client;
    if (supa == null) return null;

    try {
      return supa
          .from('LocationLogs')
          .stream(primaryKey: ['Id'])
          .eq('DeviceId', deviceId)
          .order('RecordedAt', ascending: false)
          .limit(1);
    } catch (e) {
      debugPrint('Lỗi stream LocationLogs Supabase: $e');
      return null;
    }
  }

  /// Lắng nghe dữ liệu cảm biến (âm thanh dB, gia tốc kế) thời gian thực
  static Stream<List<Map<String, dynamic>>>? streamSensor(String deviceId) {
    final supa = client;
    if (supa == null) return null;

    try {
      return supa
          .from('SensorLogs')
          .stream(primaryKey: ['Id'])
          .eq('DeviceId', deviceId)
          .order('RecordedAt', ascending: false)
          .limit(1);
    } catch (e) {
      debugPrint('Lỗi stream SensorLogs Supabase: $e');
      return null;
    }
  }

  /// Lắng nghe cảnh báo SOS khẩn cấp từ trẻ em
  static Stream<List<Map<String, dynamic>>>? streamActiveSos(String childId) {
    final supa = client;
    if (supa == null) return null;

    try {
      return supa
          .from('SosAlerts')
          .stream(primaryKey: ['Id'])
          .eq('ChildId', childId)
          .eq('IsResolved', false)
          .order('CreatedAt', ascending: false);
    } catch (e) {
      debugPrint('Lỗi stream SosAlerts Supabase: $e');
      return null;
    }
  }
}
