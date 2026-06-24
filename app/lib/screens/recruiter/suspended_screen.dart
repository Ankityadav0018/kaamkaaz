import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';

class SuspendedScreen extends StatelessWidget {
  final String? reason;
  const SuspendedScreen({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Center(
                    child: Text('🚫', style: TextStyle(fontSize: 48))),
              ),
              const SizedBox(height: 28),
              Text(LocaleKeys.accountSuspended.tr(),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.danger)),
              const SizedBox(height: 12),
              Text(LocaleKeys.accountSuspendedDesc.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textMedium, height: 1.6)),
              if (reason != null && reason!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(LocaleKeys.reasonLabel.tr(),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.danger)),
                        const SizedBox(height: 6),
                        Text(reason!,
                            style: const TextStyle(fontSize: 14, height: 1.5)),
                      ]),
                ),
              ],
              const SizedBox(height: 32),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow),
                child: Row(children: [
                  const Icon(Icons.support_agent_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(LocaleKeys.needHelp.tr(),
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        Text(LocaleKeys.contactSupportDesc.tr(),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMedium)),
                      ])),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
