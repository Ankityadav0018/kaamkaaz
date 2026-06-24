import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/router_service.dart'; // uses the existing sharedPrefsProvider
import '../utils/app_theme.dart';

const _kThemeKey = 'selected_theme';

// ── Theme notifier ────────────────────────────────────────
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  final dynamic _prefs; // SharedPreferences? from router_service

  ThemeNotifier(this._prefs) : super(_load(_prefs));

  static AppThemeMode _load(dynamic prefs) {
    if (prefs == null) return AppThemeMode.dark;
    final saved = prefs.getString(_kThemeKey) as String?;
    if (saved == null) return AppThemeMode.dark;
    try {
      return AppThemeMode.values.firstWhere(
        (m) => m.key == saved,
        orElse: () => AppThemeMode.dark,
      );
    } catch (_) {
      return AppThemeMode.dark;
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    await _prefs?.setString(_kThemeKey, mode.key);
  }
}

// ── Provider ──────────────────────────────────────────────
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return ThemeNotifier(prefs);
});
