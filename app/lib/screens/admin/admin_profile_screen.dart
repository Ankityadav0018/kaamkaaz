import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/locale_keys.g.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.adminProfile.tr(),
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Avatar Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: user.profileImage.isNotEmpty
                        ? CachedNetworkImageProvider(user.profileImage)
                        : null,
                    child: user.profileImage.isEmpty
                        ? const Icon(Icons.admin_panel_settings_rounded,
                            size: 48, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(user.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(user.phone,
                      style: const TextStyle(color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(LocaleKeys.superAdmin.tr(),
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _sectionHeader('ADMIN CONTROLS'),
            _card([
              _actionTile(context, Icons.analytics_outlined,
                  'Platform Analytics', '', onTap: () => context.pop()),
              const Divider(),
              _actionTile(context, Icons.verified_user_outlined,
                  'Worker KYC', '/admin/kyc-pending'),
              const Divider(),
              _actionTile(context, Icons.badge_outlined,
                  'Driver KYC', '/admin/driver-kyc'),
              const Divider(),
              _actionTile(context, Icons.business_outlined,
                  'Recruiter KYC', '/admin/recruiters'),
              const Divider(),
              _actionTile(context, Icons.badge_outlined, 'Skill Badge Requests',
                  '/admin/skill-badges'),
              const Divider(),
              _actionTile(context, Icons.balance_outlined, 'Dispute Management',
                  '/admin/disputes'),
              const Divider(),
              _actionTile(context, Icons.account_balance_wallet_outlined,
                  'Withdrawal Transactions', '/admin/withdrawals'),
            ]),
            const SizedBox(height: 24),

            _card([
              _actionTile(context, Icons.translate_rounded, 'Change Language',
                  '/language'),
              const Divider(),
              _actionTile(context, Icons.bug_report_rounded, 'Report a Problem',
                  '/report-problem'),
              const Divider(),
              _actionTile(context, Icons.lock_rounded, 'appLockPin'.tr(), '/set-pin'),
              const Divider(),
              _actionTile(context, Icons.lock_reset_rounded, 'Change Password',
                  '/change-password'),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.gavel_outlined, color: AppColors.textMedium),
                title: Text(LocaleKeys.legalAndInformation.tr(),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                onTap: () async {
                  final uri = Uri.parse('https://kaamkaaz.org');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ]),
            const SizedBox(height: 32),

            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              tileColor: Colors.white,
              leading:
                  const Icon(Icons.logout_rounded, color: AppColors.danger),
              title: const Text('Logout',
                  style: TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w700)),
              onTap: () => ref.read(authProvider.notifier).logout(),
            ),
            const SizedBox(height: 40),
          ],
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
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow),
        child: Column(children: children),
      );

  Widget _actionTile(
          BuildContext context, IconData icon, String title, String route, {VoidCallback? onTap}) =>
      ListTile(
        leading: Icon(icon, color: AppColors.textMedium),
        title: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
        onTap: onTap ?? () => context.push(route),
      );
}
