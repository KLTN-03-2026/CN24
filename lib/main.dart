import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_now_khoaluan/controllers/auth_controller.dart';
import 'package:ride_now_khoaluan/routes/app_pages.dart';
import 'package:ride_now_khoaluan/services/ai_service.dart';
import 'package:ride_now_khoaluan/services/translation_service.dart';
import 'package:ride_now_khoaluan/theme/app_theme.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo AuthController
  Get.put(AuthController());

  // Khởi tạo AI Service với Gemini API Key
  const geminiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCEfHf_Kne9N2wL_XdNkc-1uqnmI580yGg',
  );
  AIService().initialize(geminiKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      translations: TranslationService(),
      locale: const Locale('vi'),
      fallbackLocale: const Locale('en'),
    );
  }
}
