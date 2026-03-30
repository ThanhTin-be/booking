import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Init storage
  await GetStorage.init();
  // Load environment variables (bỏ qua nếu file .env trống hoặc thiếu).
  // Khi chuyển môi trường (VM/laptop/macbook/iphone) bạn chỉ cần đổi 1 chỗ:
  //   mobile_app/.env -> API_BASE_URL=http://<IP_MAY_CHAY_BACKEND>:3000/api
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env trống hoặc không tìm thấy → dùng giá trị mặc định trong AppConfig
    debugPrint('⚠️  .env not loaded: $e');
  }
  
  runApp(const MyApp());
}
