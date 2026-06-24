import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/api_config.dart';
import '../../services/api_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class RecruiterVerificationScreen extends StatefulWidget {
  const RecruiterVerificationScreen({super.key});
  @override
  State<RecruiterVerificationScreen> createState() =>
      _RecruiterVerificationScreenState();
}

class _RecruiterVerificationScreenState
    extends State<RecruiterVerificationScreen> {
  List<dynamic> _pending = [];
  List<dynamic> _verified = [];
  List<dynamic> _suspended = [];
  bool _loading = true;
  bool _processing = false;
  String _currentStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('${ApiConfig.adminPendingRecruiters}?status=pending'),
        ApiService.get('${ApiConfig.adminPendingRecruiters}?status=verified'),
        ApiService.get('${ApiConfig.adminPendingRecruiters}?status=suspended'),
      ]);

      if (mounted) {
        setState(() {
          _pending = results[0]['data'] ?? [];
          _verified = results[1]['data'] ?? [];
          _suspended = results[2]['data'] ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify(String userId) async {
    setState(() => _processing = true);
    try {
      final res = await ApiService.patch(
          '${ApiConfig.adminVerifyRecruiter}/$userId/verify',
          {'action': 'verify'});
      if (res['success'] == true) {
        _showSnack('✅ Recruiter verified!', AppColors.success);
        _load();
      } else {
        _showSnack(res['message'] ?? 'Failed', AppColors.danger);
      }
    } catch (e) {
      _showSnack(e.toString(), AppColors.danger);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _suspend(String userId) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('suspendRecruiter'.tr(),
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('provideReasonMin10'.tr(),
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          VoiceTextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'suspectActivityHint'.tr(),
              filled: true,
              fillColor: AppColors.inputBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancelBtn'.tr())),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().length < 10) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _processing = true);
      try {
        final res = await ApiService.patch(
            '${ApiConfig.adminVerifyRecruiter}/$userId/verify',
            {'action': 'suspend', 'reason': ctrl.text.trim()});
        if (res['success'] == true) {
          _showSnack('🚫 Recruiter suspended.', AppColors.warning);
          _load();
        } else {
          _showSnack(res['message'] ?? 'Failed', AppColors.danger);
        }
      } catch (e) {
        _showSnack(e.toString(), AppColors.danger);
      } finally {
        if (mounted) setState(() => _processing = false);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bgLight,
          appBar: AppBar(
            title: Text('recruiterVerificationTitle'.tr(),
                style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                  icon: const Icon(Icons.refresh_rounded), onPressed: _load)
            ],
          ),
          body: Column(children: [
            // Header tabs
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _tabItem('Pending', 'pending', AppColors.warning),
                  const SizedBox(width: 8),
                  _tabItem('Verified', 'verified', AppColors.success),
                  const SizedBox(width: 8),
                  _tabItem('Suspended', 'suspended', AppColors.danger),
                ]),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : Builder(builder: (_) {
                      List<dynamic> list;
                      if (_currentStatus == 'verified') {
                        list = _verified;
                      } else if (_currentStatus == 'suspended') {
                        list = _suspended;
                      } else {
                        list = _pending;
                      }

                      if (list.isEmpty) {
                        return Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              Text(
                                  _currentStatus == 'verified'
                                      ? '🏗️'
                                      : _currentStatus == 'suspended'
                                          ? '🚫'
                                          : '✅',
                                  style: const TextStyle(fontSize: 56)),
                              const SizedBox(height: 12),
                              Text('No $_currentStatus recruiters',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ]));
                      }
                      return RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () async {
                              final result = await context.push(
                                  '/admin/recruiter-kyc-detail',
                                  extra: list[i]);
                              if (result == true) _load();
                            },
                            child: _RecruiterCard(
                              recruiter: list[i],
                              onVerify: _currentStatus == 'pending'
                                  ? () => _verify(list[i]['_id'])
                                  : null,
                              onSuspend: _currentStatus != 'suspended'
                                  ? () => _suspend(list[i]['_id'])
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }),
            ),
          ]),
        ),
        if (_processing)
          Container(
            color: Colors.black26,
            child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ),
      ],
    );
  }

  Widget _tabItem(String label, String status, Color activeColor) {
    final isActive = _currentStatus == status;
    final count = status == 'verified'
        ? _verified.length
        : status == 'suspended'
            ? _suspended.length
            : _pending.length;

    return GestureDetector(
      onTap: () {
        setState(() => _currentStatus = status);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? activeColor : AppColors.inputBg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          '$label ($count)',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : AppColors.textMedium),
        ),
      ),
    );
  }
}

class _RecruiterCard extends StatelessWidget {
  final dynamic recruiter;
  final VoidCallback? onVerify;
  final VoidCallback? onSuspend;

  const _RecruiterCard(
      {required this.recruiter, this.onVerify, this.onSuspend});

  @override
  Widget build(BuildContext context) {
    final v = recruiter['recruiterVerification'] ?? {};
    final createdAt = recruiter['createdAt'] != null
        ? DateFormat('dd MMM yyyy')
            .format(DateTime.parse(recruiter['createdAt']).toLocal())
        : '—';
    final businessType = (v['businessType'] ?? '').toString().toUpperCase();
    final isPending = v['status'] == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
        border: Border.all(
            color: isPending
                ? AppColors.warning.withValues(alpha: 0.3)
                : AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            radius: 24,
            child: Text(
              (recruiter['name'] ?? '?').toString()[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 20,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(recruiter['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                Text('+91 ${recruiter['phone'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMedium)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(businessType,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 14),
        _row(Icons.location_on_rounded, v['areaOfOperation'] ?? '—'),
        if (v['businessName'] != null &&
            v['businessName'].toString().isNotEmpty)
          _row(Icons.business_rounded, v['businessName']),
        if (v['purposeNote'] != null &&
            v['purposeNote'].toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('"${v['purposeNote']}"',
                style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMedium,
                    height: 1.5)),
          ),
        ],
        const SizedBox(height: 8),
        _row(Icons.calendar_today_rounded, 'Registered: $createdAt'),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Row(children: [
          if (v['status'] != 'suspended')
            Expanded(
                child: OutlinedButton.icon(
              onPressed: onSuspend,
              icon: const Icon(Icons.block_rounded,
                  size: 16, color: AppColors.danger),
              label: const Text('Suspend',
                  style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )),
          if (isPending) ...[
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton.icon(
              onPressed: onVerify,
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Verify'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )),
          ],
          if (v['status'] == 'verified') ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_rounded,
                    size: 14, color: AppColors.success),
                SizedBox(width: 6),
                Text('Verified',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ]),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(icon, size: 14, color: AppColors.textLight),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textDark))),
        ]),
      );
}
