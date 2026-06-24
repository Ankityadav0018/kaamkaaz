import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';
import 'package:intl/intl.dart';

class WorkerKYCDetailScreen extends StatefulWidget {
  final Map<String, dynamic> worker;
  const WorkerKYCDetailScreen({super.key, required this.worker});

  @override
  State<WorkerKYCDetailScreen> createState() => _WorkerKYCDetailScreenState();
}

class _WorkerKYCDetailScreenState extends State<WorkerKYCDetailScreen> {
  bool _processing = false;

  Future<void> _approveWorker(String userId) async {
    setState(() => _processing = true);
    try {
      await ApiService.put(
          '${ApiConfig.adminKycReview}/$userId', {'status': 'approved'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ KYC Approved!'),
          backgroundColor: AppColors.success,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showRejectDialog(String userId) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('rejectKyc'.tr(),
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('provideReasonAadhaar'.tr(),
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            VoiceTextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'aadhaarBlurredHint'.tr(),
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
            child: Text('rejectBtn'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _processing = true);
      try {
        await ApiService.put('${ApiConfig.adminKycReview}/$userId', {
          'status': 'rejected',
          'note': ctrl.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🚫 KYC Rejected.'),
            backgroundColor: AppColors.warning,
          ));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ));
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
    final worker = widget.worker;
    final String aadhaarNumberDisplay = worker['aadhaarNumber'] ?? 'Not Provided';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bgLight,
          appBar: AppBar(
            title: Text('workerKycDetails'.tr(),
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP: worker info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => worker['livePhotoUrl'] != null
                            ? _openFullImage(worker['livePhotoUrl'], 'Selfie')
                            : null,
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: worker['livePhotoUrl'] != null
                              ? CachedNetworkImageProvider(
                                  worker['livePhotoUrl'])
                              : null,
                          child: worker['livePhotoUrl'] == null
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
                            Text(worker['name'] ?? 'Unknown',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('+91 ${worker['phone'] ?? ''}',
                                style: const TextStyle(
                                    fontSize: 14, color: AppColors.textMedium)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                  'Reg: ${worker['createdAt'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(worker['createdAt']).toLocal()) : '—'}',
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
                ),
                const SizedBox(height: 24),
                Text('aadhaarVerification'.tr(),
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

                _buildDocCard('Aadhaar Front', worker['aadhaarImage']),
                _buildDocCard('Aadhaar Back', worker['aadhaarBackImage']),
                _buildDocCard('Live Selfie', worker['livePhotoUrl']),

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
                        : () => _showRejectDialog(worker['_id']),
                    icon: const Icon(Icons.cancel_rounded),
                    label: Text('rejectKyc'.tr()),
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
                    onPressed: _processing
                        ? null
                        : () => _approveWorker(worker['_id']),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text('approveKyc'.tr()),
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
