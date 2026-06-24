import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // Existing Dio wrapper

class LanguageService {
  static Future<void> saveLanguage(String langCode) async {
    // 1. Save locally for instant offline booting
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', langCode);

    // 2. Sync with MongoDB via backend API
    try {
      await ApiService.put('/users/profile', {'preferredLanguage': langCode});
    } catch (e) {
      print('Failed to sync language to server: $e');
    }
  }
}
