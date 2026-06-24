import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class RaiseDisputeScreen extends ConsumerStatefulWidget {
  final String jobId;
  const RaiseDisputeScreen({super.key, required this.jobId});

  @override
  ConsumerState<RaiseDisputeScreen> createState() => _RaiseDisputeScreenState();
}

class _RaiseDisputeScreenState extends ConsumerState<RaiseDisputeScreen> {
  String? _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();
  bool _loading = false;

  List<Map<String, String>> get _categories {
    final role = ref.read(authProvider).user?.role ?? 'worker';
    if (role == 'recruiter') {
      return [
        {'id': 'worker_no_show', 'icon': '🚫'},
        {'id': 'work_quality_issue', 'icon': '⚠️'},
        {'id': 'unprofessional_behavior', 'icon': '😠'},
        {'id': 'property_damage', 'icon': '🔨'},
        {'id': 'other', 'icon': '🔧'},
      ];
    } else {
      return [
        {'id': 'payment_not_received', 'icon': '💰'},
        {'id': 'wrong_job_description', 'icon': '📋'},
        {'id': 'unsafe_conditions', 'icon': '🦺'},
        {'id': 'unprofessional_behavior', 'icon': '😠'},
        {'id': 'other', 'icon': '🔧'},
      ];
    }
  }

  String _getCategoryLabel(String id) {
    switch (id) {
      case 'payment_not_received':
        return LocaleKeys.paymentNotReceived.tr();
      case 'worker_no_show':
        return LocaleKeys.workerNoShow.tr();
      case 'wrong_job_description':
        return LocaleKeys.wrongJobDesc.tr();
      case 'work_quality_issue':
        return LocaleKeys.workQualityIssue.tr();
      case 'unsafe_conditions':
        return LocaleKeys.unsafeConditions.tr();
      case 'unprofessional_behavior':
        return 'Unprofessional Behavior';
      case 'property_damage':
        return 'Property Damage';
      default:
        return LocaleKeys.otherText.tr();
    }
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) return;
    if (_descriptionController.text.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.disputeMinChar.tr())),
      );
      return;
    }

    setState(() => _loading = true);
    final res = await ApiService.post(ApiConfig.disputes, {
      'jobId': widget.jobId,
      'category': _selectedCategory,
      'description': _descriptionController.text,
    });

    if (mounted) {
      setState(() => _loading = false);
      if (res['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(LocaleKeys.disputeSubmitted.tr()),
            content: Text(LocaleKeys.disputeSuccessMsg.tr()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                child: Text('okBtn'.tr()),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to submit dispute')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.raiseDispute.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocaleKeys.disputeCategory.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ..._categories.map((cat) {
              final isSelected = _selectedCategory == cat['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedCategory = cat['id']);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text(cat['icon']!,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 15),
                        Text(_getCategoryLabel(cat['id']!),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textDark,
                            )),
                        if (isSelected) const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 25),
            Text(LocaleKeys.disputeDesc.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            VoiceTextField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: LocaleKeys.describeWhatHappened.tr(),
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                    _loading || _selectedCategory == null ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(LocaleKeys.submitDispute.tr(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
