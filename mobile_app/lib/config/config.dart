import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConfig {
  static String _normalizeApiBaseUrl(String raw) {
    var v = raw.trim();
    if (v.isEmpty) return v;
    // remove trailing slash
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    // If user provides only origin (http://x:3000), auto-append /api
    if (!v.endsWith('/api')) return '$v/api';
    return v;
  }

  // API Base URL
  // - Ưu tiên 1 chỗ duy nhất: mobile_app/.env -> API_BASE_URL=http://<IP>:3000/api
  // - Fallback theo platform để dev nhanh (nhưng khi chạy thiết bị thật thì nên set .env)
  static String get apiBaseUrl {
    // 1) Ưu tiên --dart-define=API_BASE_URL=...
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return _normalizeApiBaseUrl(defined);

    // 2) Sau đó đọc từ .env (flutter_dotenv)
    final fromEnv = dotenv.env['API_BASE_URL'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) return _normalizeApiBaseUrl(fromEnv);

    // 3) Fallback theo platform
    if (kIsWeb) {
      // Web chạy trong browser: dùng same-origin để tránh CORS khi deploy
      return _normalizeApiBaseUrl(Uri.base.origin);
    }

    // Android Emulator: map localhost host-machine
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';

    // iOS Simulator: localhost trỏ về máy Mac đang chạy app/simulator
    if (Platform.isIOS) return 'http://localhost:3000/api';

    // Desktop/dev khác: dùng localhost (nếu bạn chạy backend cùng máy)
    return 'http://localhost:3000/api';
  }

  /// Server origin (không có /api) – dùng để ghép URL ảnh upload
  /// VD: http://192.168.1.5:3000
  static String get serverOrigin {
    final api = apiBaseUrl;
    if (api.endsWith('/api')) return api.substring(0, api.length - 4);
    return api;
  }

  /// Convert đường dẫn tương đối thành URL đầy đủ
  /// VD: /uploads/courts/abc.jpg → http://192.168.1.5:3000/uploads/courts/abc.jpg
  static String toFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path; // đã là URL đầy đủ
    return '$serverOrigin$path';
  }
}
