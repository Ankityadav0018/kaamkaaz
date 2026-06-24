import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';

class RecruiterProfileScreen extends ConsumerWidget {
  const RecruiterProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.companyProfile.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/recruiter/profile/edit'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(authProvider.notifier).refreshUser(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(user.name[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                    const SizedBox(height: 12),
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('+91 ${user.phone}',
                        style: const TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w600)),
                    if (user.email.isNotEmpty && user.email.toLowerCase() != 'none' && user.email.toLowerCase() != 'null') ...[
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _sectionHeader('VERIFICATION & KYC'),
              _card([
                _infoTile(
                  Icons.shield_outlined,
                  'KYC Status',
                  user.kycStatus.toUpperCase(),
                  iconColor: user.isKycApproved
                      ? AppColors.success
                      : (user.isKycRejected ? AppColors.danger : Colors.orange),
                ),
                const Divider(),
                _infoTile(
                  Icons.verified_outlined,
                  'Recruiter Verification',
                  user.recruiterVerification?['status']
                          ?.toString()
                          .toUpperCase() ??
                      'NOT SUBMITTED',
                  iconColor: user.isRecruiterVerified
                      ? AppColors.success
                      : Colors.orange,
                ),
              ]),
              const SizedBox(height: 16),

              _sectionHeader(LocaleKeys.businessInfo.tr()),
              _card([
                _infoTile(
                    Icons.business_outlined,
                    LocaleKeys.companyName.tr(),
                    user.companyName.isEmpty
                        ? LocaleKeys.notSet.tr()
                        : user.companyName),
                const Divider(),
                _infoTile(Icons.star_rounded, LocaleKeys.recruiterRating.tr(),
                    '${user.rating.average} (${user.rating.count} reviews)',
                    iconColor: Colors.amber),
                const Divider(),
                _infoTile(Icons.badge_outlined, LocaleKeys.role.tr(),
                    LocaleKeys.recruiter.tr()),
              ]),
              const SizedBox(height: 16),

              _sectionHeader(LocaleKeys.preferences.tr()),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language_rounded,
                          color: AppColors.primary),
                      title: Text(LocaleKeys.changeLanguage.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(context.locale.languageCode.toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textLight),
                      onTap: () => context.push('/language'),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.gavel_rounded,
                          color: AppColors.danger),
                      title: Text(LocaleKeys.myDisputes.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textLight),
                      onTap: () => context.push('/disputes/my'),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textLight,
                letterSpacing: 1.2)),
      );

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _infoTile(IconData icon, String label, String value,
          {Color? iconColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );
}
