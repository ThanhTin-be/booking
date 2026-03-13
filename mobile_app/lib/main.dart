import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Init storage
  await GetStorage.init();
  // Load environment variables (bỏ qua nếu file .env trống hoặc thiếu)
  try {
    await dotenv.load(fileName: ".env", mergeWith: {
      'API_BASE_URL': 'http://172.20.10.7:3000/api',
    });
  } catch (e) {
    // .env trống hoặc không tìm thấy → dùng giá trị mặc định trong AppConfig
    debugPrint('⚠️  .env not loaded: $e');
  }
  
  runApp(const MyApp());
}
