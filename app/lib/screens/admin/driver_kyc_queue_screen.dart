import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import '../../utils/api_config.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class DriverKycQueueScreen extends ConsumerStatefulWidget {
  const DriverKycQueueScreen({super.key});

  @override
  ConsumerState<DriverKycQueueScreen> createState() =>
      _DriverKycQueueScreenState();
}

class _DriverKycQueueScreenState extends ConsumerState<DriverKycQueueScreen> {
  List<dynamic> _drivers = [];
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get(ApiConfig.driverKycPending);
      if (mounted) {
        setState(() {
          _drivers = res['data'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reviewKyc(String userId, String status,
      {String? reason}) async {
    setState(() => _processing = true);
    try {
      final res =
          await ApiService.patch('${ApiConfig.adminDriverKycReview}/$userId', {
        'status': status,
        if (reason != null) 'reason': reason,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? LocaleKeys.success.tr()),
          backgroundColor:
              status == 'verified' ? AppColors.success : AppColors.danger,
        ));
        _load();
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

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(LocaleKeys.rejectReason.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: VoiceTextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: LocaleKeys.enterRejectionReason.tr(),
            filled: true,
            fillColor: AppColors.inputBg,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocaleKeys.cancel.tr())),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reviewKyc(userId, 'rejected', reason: ctrl.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(LocaleKeys.reject.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bgLight,
          appBar: AppBar(
            title: Text('${LocaleKeys.driverKycQueue.tr()} 🚗',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _load,
              )
            ],
          ),
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _drivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 12),
                          Text(LocaleKeys.noPendingDriverKyc.tr(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _drivers.length,
                      itemBuilder: (_, i) => _DriverKycCard(
                        driver: _drivers[i],
                        onApprove: () =>
                            _reviewKyc(_drivers[i]['_id'], 'verified'),
                        onReject: () => _showRejectDialog(_drivers[i]['_id']),
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
}

class _DriverKycCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DriverKycCard({
    required this.driver,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final dp = driver['driverProfile'] as Map<String, dynamic>? ?? {};
    final name = driver['name'] as String? ?? '';
    final phone = driver['phone'] as String? ?? '';
    final submittedAt = dp['kycSubmittedAt'] as String?;

    final docs = {
      LocaleKeys.licenceFront.tr(): dp['licenceFrontUrl'],
      LocaleKeys.licenceBack.tr(): dp['licenceBackUrl'],
      LocaleKeys.aadhaar.tr(): dp['aadhaarUrl'],
      LocaleKeys.rcBook.tr(): dp['rcBookUrl'],
      LocaleKeys.policeVerification.tr(): dp['policeVerificationUrl'],
      LocaleKeys.passportPhoto.tr(): dp['passportPhotoUrl'],
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('📞 $phone',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMedium)),
                      if (submittedAt != null)
                        Text(
                          '${LocaleKeys.submitted.tr()}: ${DateTime.tryParse(submittedAt)?.toLocal().toString().substring(0, 16) ?? submittedAt}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textLight),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('⏳ ${LocaleKeys.pending.tr()}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Driver Profile Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LocaleKeys.driverDetails.tr(),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                _detailRow(LocaleKeys.vehicleTypes.tr(),
                    (dp['vehicleTypes'] as List<dynamic>? ?? []).join(', ')),
                _detailRow(LocaleKeys.experience.tr(),
                    '${dp['experienceYears'] ?? 0} ${LocaleKeys.years.tr()}'),
                _detailRow(LocaleKeys.languages.tr(),
                    (dp['languages'] as List<dynamic>? ?? []).join(', ')),
                _detailRow(
                    LocaleKeys.outstation.tr(),
                    dp['willingToOutstation'] == true
                        ? LocaleKeys.yes.tr()
                        : LocaleKeys.no.tr()),
                if (dp['hasOwnVehicle'] == true) ...[
                  _detailRow(LocaleKeys.ownVehicle.tr(),
                      dp['ownVehicleType'] ?? LocaleKeys.yes.tr()),
                  _detailRow(LocaleKeys.regNumber.tr(),
                      dp['ownVehicleRegNumber'] ?? LocaleKeys.notProvided.tr()),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Documents
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LocaleKeys.documents.tr(),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final docLabel = docs.keys.elementAt(i);
                    final docUrl = docs.values.elementAt(i);
                    final hasDoc =
                        docUrl != null && (docUrl as String).isNotEmpty;

                    return GestureDetector(
                      onTap: hasDoc
                          ? () => _showImageDialog(ctx, docUrl, docLabel)
                          : null,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 68,
                            decoration: BoxDecoration(
                              color: hasDoc
                                  ? Colors.transparent
                                  : AppColors.inputBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: hasDoc
                                    ? AppColors.success.withValues(alpha: 0.4)
                                    : AppColors.border,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: hasDoc
                                ? CachedNetworkImage(
                                    imageUrl: docUrl,
                                    fit: BoxFit.cover,
                                    memCacheHeight: 200,
                                    placeholder: (context, url) => Container(
                                        color: AppColors.inputBg,
                                        child: const Center(
                                            child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2)))),
                                    errorWidget: (_, __, ___) => const Icon(
                                        Icons.broken_image_rounded,
                                        color: AppColors.danger),
                                  )
                                : const Center(
                                    child: Icon(
                                        Icons.image_not_supported_rounded,
                                        color: AppColors.textLight)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            docLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: hasDoc
                                  ? AppColors.success
                                  : AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.danger, size: 18),
                    label: Text(LocaleKeys.reject.tr(),
                        style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(LocaleKeys.approve.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Flexible(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) =>
                        Center(child: Text('failedLoadImage'.tr())),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value.isEmpty ? 'N/A' : value,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
