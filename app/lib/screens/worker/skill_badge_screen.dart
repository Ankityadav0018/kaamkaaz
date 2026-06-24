import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import '../../services/secure_upload_service.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/locale_keys.g.dart';

class SkillBadgeScreen extends ConsumerStatefulWidget {
  const SkillBadgeScreen({super.key});

  @override
  ConsumerState<SkillBadgeScreen> createState() => _SkillBadgeScreenState();
}

class _SkillBadgeScreenState extends ConsumerState<SkillBadgeScreen> {
  List<dynamic> _myBadges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final res = await ApiService.get(ApiConfig.myBadges);
      if (res['success'] == true) {
        if (!mounted) return;
        setState(() {
          _myBadges = res['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showRequestSheet(SkillInfo skill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RequestBadgeSheet(
        skill: skill,
        onSuccess: () {
          _loadBadges();

          ref.read(authProvider.notifier).refreshUser();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.skillBadges.tr())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBadges,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(LocaleKeys.myBadges.tr(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildBadgesGrid(),
                    const SizedBox(height: 40),
                    Text(LocaleKeys.requestNewBadge.tr(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildAvailableSkillsGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBadgesGrid() {
    if (_myBadges.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16)),
        child: Text(LocaleKeys.noBadgesYet.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _myBadges.map((badge) {
        final skill = kSkillsList.firstWhere((s) => s.id == badge['skill'],
            orElse: () => const SkillInfo('', '', Icons.handyman_rounded));
        Color color;
        IconData icon;
        switch (badge['status']) {
          case 'verified':
            color = AppColors.success;
            icon = Icons.check_circle_rounded;
            break;
          case 'rejected':
            color = AppColors.danger;
            icon = Icons.cancel_rounded;
            break;
          default:
            color = Colors.amber;
            icon = Icons.hourglass_empty_rounded;
        }

        return GestureDetector(
          onTap: badge['status'] == 'rejected'
              ? () => _showRejectionDialog(badge)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(skill.icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(skill.name,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: color)),
                const SizedBox(width: 4),
                Icon(icon, size: 16, color: color),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showRejectionDialog(dynamic badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.statusRejectedBadge.tr()),
        content: Text(badge['adminNote'] ?? "No reason provided."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocaleKeys.okBtn.tr())),
        ],
      ),
    );
  }

  Widget _buildAvailableSkillsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: kSkillsList.length,
      itemBuilder: (context, index) {
        final skill = kSkillsList[index];
        final badge = _myBadges.firstWhere((b) => b['skill'] == skill.id,
            orElse: () => null);
        final isRequested = badge != null &&
            (badge['status'] == 'pending' || badge['status'] == 'verified');

        return GestureDetector(
          onTap: isRequested ? null : () => _showRequestSheet(skill),
          child: Opacity(
            opacity: isRequested ? 0.5 : 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(skill.icon, size: 32, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(skill.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  if (isRequested)
                    Icon(
                        badge?['status'] == 'verified'
                            ? Icons.verified_rounded
                            : Icons.access_time_rounded,
                        size: 14,
                        color: badge?['status'] == 'verified'
                            ? AppColors.success
                            : Colors.amber),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RequestBadgeSheet extends StatefulWidget {
  final SkillInfo skill;
  final VoidCallback onSuccess;

  const _RequestBadgeSheet({required this.skill, required this.onSuccess});

  @override
  State<_RequestBadgeSheet> createState() => _RequestBadgeSheetState();
}

class _RequestBadgeSheetState extends State<_RequestBadgeSheet> {
  String? _documentPath;
  bool _isSubmitting = false;

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _documentPath = image.path);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      String? docUrl, docPublicId;

      if (_documentPath != null) {
        final uploadRes = await SecureUploadService.uploadImage(
          filePath: _documentPath!,
          uploadType: 'skill_badge',
        );
        if (uploadRes['success']) {
          docUrl = uploadRes['url'];
          docPublicId = uploadRes['public_id'];
        }
      }

      final res = await ApiService.post(ApiConfig.requestBadge, {
        'skill': widget.skill.id,
        if (docUrl != null) 'documentUrl': docUrl,
        if (docPublicId != null) 'documentPublicId': docPublicId,
      });

      if (res['success'] == true) {
        widget.onSuccess();
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception(res['message'] ?? "Request failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.skill.icon, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(widget.skill.name,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(LocaleKeys.selectSkillToVerify.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMedium)),
          const SizedBox(height: 30),
          InkWell(
            onTap: _pickDocument,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.border, style: BorderStyle.solid),
              ),
              child: _documentPath == null
                  ? Column(
                      children: [
                        const Icon(Icons.cloud_upload_outlined,
                            size: 40, color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text(LocaleKeys.uploadDocumentOptional.tr(),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success),
                        const SizedBox(width: 12),
                        Text(LocaleKeys.documentSelected.tr(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(LocaleKeys.submitRequest.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
