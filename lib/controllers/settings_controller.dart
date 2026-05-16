import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/local_storage_service.dart';

class SettingsController extends GetxController {
  final RxString _language = 'vi'.obs;
  final RxString _theme = 'light'.obs;

  String get language => _language.value;
  String get theme => _theme.value;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    _language.value = LocalStorageService.getLanguage();
    _theme.value = LocalStorageService.getTheme();
    
    // Apply immediately on load
    _applySettings();
  }

  void _applySettings() {
    // Apply Language
    Get.updateLocale(Locale(_language.value));
    
    // Apply Theme
    Get.changeThemeMode(_theme.value == 'dark' ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> updateLanguage(String langCode) async {
    _language.value = langCode;
    await LocalStorageService.saveLanguage(langCode);
    Get.updateLocale(Locale(langCode));
  }

  Future<void> updateTheme(String themeName) async {
    _theme.value = themeName;
    await LocalStorageService.saveTheme(themeName);
    Get.changeThemeMode(themeName == 'dark' ? ThemeMode.dark : ThemeMode.light);
  }

  bool get isDarkMode => _theme.value == 'dark';
}
