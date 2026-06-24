import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';
import 'package:intl/intl.dart';

class RecruiterKYCDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recruiter;
  const RecruiterKYCDetailScreen({super.key, required this.recruiter});

  @override
  State<RecruiterKYCDetailScreen> createState() =>
      _RecruiterKYCDetailScreenState();
}

class _RecruiterKYCDetailScreenState extends State<RecruiterKYCDetailScreen> {
  bool _processing = false;
  Map<String, dynamic>? _fullRecruiter;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _processing = true);
    try {
      final res = await ApiService.get(
          '${ApiConfig.adminRecruiterDetails}/${widget.recruiter['_id']}');
      if (res['success'] == true && mounted) {
        setState(() => _fullRecruiter = res['data']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _verify(String userId) async {
    setState(() => _processing = true);
    try {
      await ApiService.patch('${ApiConfig.adminVerifyRecruiter}/$userId/verify',
          {'action': 'verify'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Recruiter verified!'),
          backgroundColor: AppColors.success,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showSuspendDialog(String userId) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('suspendRecruiter'.tr(),
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('provideReasonMin10'.tr(),
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            VoiceTextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'suspendReasonHint'.tr(),
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
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
        await ApiService.patch(
            '${ApiConfig.adminVerifyRecruiter}/$userId/verify', {
          'action': 'suspend',
          'reason': ctrl.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🚫 Recruiter suspended.'),
            backgroundColor: AppColors.warning,
          ));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.danger));
        }
      } finally {
        if (mounted) setState(() => _processing = false);
      }
    }
  }

  void _openFullImage(String imageUrl, String title) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) =>
                      const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image,
                      color: Colors.white, size: 50),
                ),
              ),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final recruiter = _fullRecruiter ?? widget.recruiter;
    final v = recruiter['recruiterVerification'] ?? {};
    final String aadhaarNumberDisplay = v['aadhaarNumber'] ?? 'Not Provided';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bgLight,
          appBar: AppBar(
            title: Text('recruiterKycDetails'.tr(),
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP: recruiter info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => v['selfieUrl'] != null
                                ? _openFullImage(v['selfieUrl'], 'Selfie')
                                : null,
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: v['selfieUrl'] != null
                                  ? CachedNetworkImageProvider(v['selfieUrl'])
                                  : null,
                              child: v['selfieUrl'] == null
                                  ? const Icon(Icons.person,
                                      size: 35, color: AppColors.primary)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(recruiter['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text('+91 ${recruiter['phone'] ?? ''}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textMedium)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                      (v['businessType'] ?? 'Individual')
                                          .toString()
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (v['businessName'] != null ||
                          v['areaOfOperation'] != null) ...[
                        const Divider(height: 32),
                        _infoRow('Business Name', v['businessName'] ?? '—'),
                        _infoRow('Area', v['areaOfOperation'] ?? '—'),
                        _infoRow('Purpose', v['purposeNote'] ?? '—'),
                        _infoRow(
                            'Submitted On',
                            v['kycSubmittedAt'] != null
                                ? DateFormat('dd MMM yyyy')
                                    .format(DateTime.parse(v['kycSubmittedAt']).toLocal())
                                : '—'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('identityVerification'.tr(),
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(aadhaarNumberDisplay,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('documentsLabel'.tr(),
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),

                _buildDocCard('Aadhaar Front', v['aadhaarFrontUrl']),
                _buildDocCard('Aadhaar Back', v['aadhaarBackUrl']),
                _buildDocCard('Live Selfie', v['selfieUrl']),

                const SizedBox(height: 100), // Space for bottom buttons
              ],
            ),
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processing
                        ? null
                        : () => _showSuspendDialog(recruiter['_id']),
                    icon: const Icon(Icons.block_rounded),
                    label: const Text('Suspend'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _processing ? null : () => _verify(recruiter['_id']),
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDocCard(String label, String? url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMedium)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => url != null ? _openFullImage(url, label) : null,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: url != null
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image,
                              size: 40, color: AppColors.textLight)),
                    )
                  : Center(child: Text('noImageUploaded'.tr())),
            ),
          ),
        ],
      ),
    );
  }
}
