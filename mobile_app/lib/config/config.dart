import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API Base URL - Ưu tiên đọc từ file .env
  // Nếu không thấy file .env, nó sẽ dùng IP máy tính của bạn làm mặc định
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.236:5000/api';
}
