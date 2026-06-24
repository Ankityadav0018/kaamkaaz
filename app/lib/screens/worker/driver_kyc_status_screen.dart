import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class DriverKycStatusScreen extends ConsumerWidget {
  const DriverKycStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null || !user.isDriver) {
      return Scaffold(
        appBar: AppBar(title: Text('driverKycStatusAppBar'.tr())),
        body: Center(child: Text('notAvailable'.tr())),
      );
    }

    final status = user.driverProfile?.kycStatus ?? 'not_submitted';
    String message = '';
    IconData icon = Icons.info_outline_rounded;
    Color color = AppColors.textMedium;

    if (status == 'verified') {
          'kycVerifiedMsg'.tr();
      icon = Icons.check_circle_rounded;
      color = AppColors.success;
    } else if (status == 'pending') {
          'kycPendingMsg'.tr();
      icon = Icons.hourglass_top_rounded;
      color = AppColors.info;
    } else if (status == 'rejected') {
          'kycRejectedMsg'.tr(args: [user.driverProfile?.kycRejectionReason ?? 'Invalid documents']);
      icon = Icons.error_outline_rounded;
      color = AppColors.danger;
    } else {
          'kycNotSubmittedMsg'.tr();
      icon = Icons.upload_file_rounded;
      color = AppColors.warning;
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('driverKycStatusTitle'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 24),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textDark),
            ),
            const SizedBox(height: 40),
            if (status != 'verified' && status != 'pending')
              ElevatedButton.icon(
                onPressed: () => context.push('/driver/profile'),
                icon: const Icon(Icons.edit_document),
                label: Text('updateProfileDocs'.tr()),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            if (status == 'verified')
              ElevatedButton.icon(
                onPressed: () {
                  // Pop to home and perhaps change category to driving
                  context.go('/worker');
                },
                icon: const Icon(Icons.search_rounded),
                label: Text('findDrivingJobsBtn'.tr()),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
