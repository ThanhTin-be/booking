import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Init storage
  await GetStorage.init();
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}
