import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageState {
  final Locale locale;
  final bool hasSelectedLanguage;

  LanguageState({required this.locale, required this.hasSelectedLanguage});

  LanguageState copyWith({Locale? locale, bool? hasSelectedLanguage}) {
    return LanguageState(
      locale: locale ?? this.locale,
      hasSelectedLanguage: hasSelectedLanguage ?? this.hasSelectedLanguage,
    );
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<LanguageState> {
  LanguageNotifier()
      : super(LanguageState(
            locale: const Locale('en'), hasSelectedLanguage: false)) {
    _loadLanguage();
  }

  // Use same key as locale_provider.dart so both stay in sync
  static const _langKey = 'selected_language';
  static const _firstTimeKey = 'language_selected';

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_langKey);
    final hasSelected = prefs.getBool(_firstTimeKey) ?? false;

    if (langCode != null) {
      state = state.copyWith(
        locale: Locale(langCode),
        hasSelectedLanguage: hasSelected,
      );
    } else {
      state = state.copyWith(hasSelectedLanguage: hasSelected);
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, locale.languageCode);
    await prefs.setBool(_firstTimeKey, true);
    state = state.copyWith(
      locale: locale,
      hasSelectedLanguage: true,
    );
  }
}
