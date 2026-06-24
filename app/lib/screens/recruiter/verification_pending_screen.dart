import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_colors.dart';
import '../../utils/api_config.dart';
import '../../services/api_service.dart';
import '../../l10n/locale_keys.g.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class VerificationPendingScreen extends ConsumerStatefulWidget {
  const VerificationPendingScreen({super.key});
  @override
  ConsumerState<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState
    extends ConsumerState<VerificationPendingScreen> {
  bool _refreshing = false;
  Map<String, dynamic>? _verification;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final res = await ApiService.get(ApiConfig.recruiterVerificationStatus);
      if (res['success'] == true && mounted) {
        setState(() => _verification = res['data']);
      }
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(authProvider.notifier).refreshUser();

      final user = ref.read(authProvider).user;
      if (user != null) {
        if (user.isRecruiterVerified) {
          if (mounted) context.go('/recruiter');
          return;
        } else if (user.isRecruiterSuspended) {
          if (mounted) context.go('/recruiter/suspended');
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(LocaleKeys.underReviewSnack.tr()),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

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
                    color: AppColors.warning.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: const Center(
                    child: Text('🕐', style: TextStyle(fontSize: 48))),
              ),
              const SizedBox(height: 28),
              Text(LocaleKeys.verificationPending.tr(),
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(
                LocaleKeys.verificationPendingDesc.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textMedium, height: 1.6),
              ),
              const SizedBox(height: 28),
              if (_verification != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row(
                            LocaleKeys.businessType.tr(),
                            _verification!['businessType']
                                    ?.toString()
                                    .toUpperCase()
                                    .tr() ??
                                '—'),
                        const Divider(height: 20),
                        _row(LocaleKeys.areaOfOperation.tr(),
                            _verification!['areaOfOperation'] ?? '—'),
                        if (_verification!['businessName'] != null) ...[
                          const Divider(height: 20),
                          _row(LocaleKeys.businessName.tr(),
                              _verification!['businessName']),
                        ],
                        const Divider(height: 20),
                        _row(LocaleKeys.aadhaarNumber.tr(),
                            _maskAadhaar(_verification!['aadhaarNumber'])),
                        const Divider(height: 20),
                        _row(LocaleKeys.documents.tr(),
                            '✅ ${LocaleKeys.submitted.tr()}'),
                        const Divider(height: 20),
                        _row(LocaleKeys.liveSelfie.tr(),
                            '✅ ${LocaleKeys.submitted.tr()}'),
                        const Divider(height: 20),
                        _row(LocaleKeys.submittedOn.tr(),
                            _formatDate(_verification!['kycSubmittedAt'])),
                      ]),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _refreshing ? null : _refresh,
                  icon: _refreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded),
                  label: Text(LocaleKeys.refreshStatus.tr(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      );

  String _maskAadhaar(dynamic val) {
    if (val == null) return '—';
    final s = val.toString();
    if (s.length < 12) return 'XXXX XXXX XXXX';
    return '****${s.substring(8)}';
  }

  String _formatDate(dynamic val) {
    if (val == null) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(val.toString()).toLocal());
    } catch (_) {
      return val.toString();
    }
  }
}
