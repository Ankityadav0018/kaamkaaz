import 'package:shared_preferences/shared_preferences.dart';

/// Persists "Remember Me" credentials using [SharedPreferences].
/// And handles Biometric credentials using [FlutterSecureStorage].
class RememberMeService {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyIdentifier = 'saved_phone'; // key kept for compat
  static const String _keyPassword = 'saved_password_prefs';

  /// Save credentials after a successful login when Remember Me is checked.
  static Future<void> saveCredentials({
    required String phoneOrEmail,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, true);
    await prefs.setString(_keyIdentifier, phoneOrEmail);
    await prefs.setString(_keyPassword, password);
  }

  /// Load previously saved credentials.
  ///
  /// Returns a map with:
  /// - `isRemembered` (bool)
  /// - `phoneOrEmail` (String, may be empty)
  /// - `password` (String, may be empty)
  static Future<Map<String, dynamic>> loadCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isRemembered = prefs.getBool(_keyRememberMe) ?? false;
      if (!isRemembered) {
        return {'isRemembered': false, 'phoneOrEmail': '', 'password': ''};
      }
      return {
        'isRemembered': true,
        'phoneOrEmail': prefs.getString(_keyIdentifier) ?? '',
        'password': prefs.getString(_keyPassword) ?? '',
      };
    } catch (_) {
      return {'isRemembered': false, 'phoneOrEmail': '', 'password': ''};
    }
  }

  /// Clear all saved credentials (call when user explicitly logs out
  /// or unchecks Remember Me before logging in).
  static Future<void> clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keyIdentifier);
      await prefs.remove(_keyPassword);
    } catch (_) {
      // ignore
    }
  }
}
