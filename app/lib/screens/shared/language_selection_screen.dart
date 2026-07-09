import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/locale_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);

    final languages = [
      {
        'locale': const Locale('en'),
        'nativeName': 'English',
        'displayName': 'English',
      },
      {
        'locale': const Locale('hi'),
        'nativeName': 'हिंदी',
        'displayName': 'Hindi',
      },
      {
        'locale': const Locale('bgc'),
        'nativeName': 'हरियाणवी',
        'displayName': 'Haryanvi • हरियाणा',
      },
      {
        'locale': const Locale('raj'),
        'nativeName': 'राजस्थानी',
        'displayName': 'Rajasthani • राजस्थान',
      },
      {
        'locale': const Locale('pa'),
        'nativeName': 'ਪੰਜਾਬੀ',
        'displayName': 'Punjabi',
      },
      {
        'locale': const Locale('mr'),
        'nativeName': 'मराठी',
        'displayName': 'Marathi',
      },
      {
        'locale': const Locale('gu'),
        'nativeName': 'ગુજરાતી',
        'displayName': 'Gujarati',
      },
      {
        'locale': const Locale('bn'),
        'nativeName': 'বাংলা',
        'displayName': 'Bengali',
      },
      {
        'locale': const Locale('ta'),
        'nativeName': 'தமிழ்',
        'displayName': 'Tamil',
      },
      {
        'locale': const Locale('te'),
        'nativeName': 'తెలుగు',
        'displayName': 'Telugu',
      },
      {
        'locale': const Locale('kn'),
        'nativeName': 'ಕನ್ನಡ',
        'displayName': 'Kannada',
      },
      {
        'locale': const Locale('ml'),
        'nativeName': 'മലയാളം',
        'displayName': 'Malayalam',
      },
      {
        'locale': const Locale('or'),
        'nativeName': 'ଓଡ଼ିଆ',
        'displayName': 'Odia',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(LocaleKeys.chooseLanguage.tr(),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.textDark)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: languageState.hasSelectedLanguage
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textDark),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              LocaleKeys.selectLanguage.tr(),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textMedium,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                final locale = lang['locale'] as Locale;
                final isSelected =
                    context.locale.languageCode == locale.languageCode;

                return GestureDetector(
                  onTap: () {
                    ref.read(localeProvider).changeLocale(context, locale);
                    ref.read(languageProvider.notifier).changeLanguage(locale);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Text(LocaleKeys.saved.tr()),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 1),
                      ),
                    );

                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (context.mounted) {
                        context.go('/');
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang['nativeName'] as String,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textDark,
                                ),
                              ),
                              Text(
                                lang['displayName'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 26),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
