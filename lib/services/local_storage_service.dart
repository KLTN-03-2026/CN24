import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Theme ---
  static Future<void> saveTheme(String theme) async {
    await _prefs?.setString('theme', theme);
  }

  static String getTheme() {
    return _prefs?.getString('theme') ?? 'light';
  }

  // --- Language ---
  static Future<void> saveLanguage(String lang) async {
    await _prefs?.setString('language', lang);
  }

  static String getLanguage() {
    return _prefs?.getString('language') ?? 'vi';
  }
}
