import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tải biến môi trường từ assets/.env
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (e) {
    debugPrint('Không thể tải .env, sử dụng cấu hình mặc định: $e');
  }

  // Khởi tạo Supabase Client an toàn nếu có cấu hình trong .env
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl != null &&
      supabaseAnonKey != null &&
      supabaseAnonKey.trim().isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl.trim(),
        publishableKey: supabaseAnonKey.trim(),
      );
      debugPrint('>>> Khởi tạo Supabase Client thành công! <<<');
    } catch (e) {
      debugPrint('Lỗi khởi tạo Supabase: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: FamilySafetyApp(),
    ),
  );
}

class FamilySafetyApp extends StatelessWidget {
  const FamilySafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Safety - Quản lý Điện thoại Trẻ em',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
