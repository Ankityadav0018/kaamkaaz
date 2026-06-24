import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

/// Drop-in widget — embed anywhere in a profile/settings screen.
/// Shows 3 swatches. Tapping one switches the global theme instantly.
class ThemeSelectorWidget extends ConsumerWidget {
  const ThemeSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(children: [
            Icon(Icons.palette_outlined, size: 18,
                color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 8),
            Text('appTheme'.tr(),
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black54,
                  letterSpacing: 0.4,
                )),
          ]),
        ),
        Row(
          children: AppThemeMode.values.map((mode) {
            final isSelected = mode == currentMode;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _ThemeSwatch(
                  mode: mode,
                  isSelected: isSelected,
                  accentColor: cs.primary,
                  onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final AppThemeMode mode;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ThemeSwatch({
    required this.mode,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: mode.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : mode.card,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: accentColor.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini UI preview
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: mode.card,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const SizedBox(width: 8),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: mode.accent),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 4, width: 30, decoration: BoxDecoration(color: mode.accent.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 4),
                      Container(height: 3, width: 20, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 8),

            // Emoji + label
            Text(mode.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              mode.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? mode.accent : Colors.white70,
                letterSpacing: 0.3,
              ),
            ),

            if (isSelected) ...[
              const SizedBox(height: 6),
              Container(
                width: 18, height: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
