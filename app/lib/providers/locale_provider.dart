import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = ChangeNotifierProvider((ref) => LocaleProvider());

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // default English

  Locale get locale => _locale;

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('selected_language') ?? 'en';
    _locale = Locale(langCode);
    notifyListeners();
  }

  Future<void> changeLocale(BuildContext context, Locale newLocale) async {
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', newLocale.languageCode);

    if (context.mounted) {
      await context.setLocale(newLocale);
    }
    notifyListeners();
  }

  bool get isHindi => _locale.languageCode == 'hi';
}
