import '../../l10n/locale_keys.g.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/secure_upload_service.dart';
import '../../utils/api_config.dart';
import '../../widgets/voice_text_field.dart';

class ReportProblemScreen extends ConsumerStatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  ConsumerState<ReportProblemScreen> createState() =>
      _ReportProblemScreenState();
}

class _ReportProblemScreenState extends ConsumerState<ReportProblemScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  File? _image;
  bool _loading = false;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('fillTitleDesc'.tr())));
      return;
    }

    setState(() => _loading = true);

    try {
      String? imageUrl;
      if (_image != null) {
        final uploadRes = await SecureUploadService.uploadImage(
            filePath: _image!.path, uploadType: 'other');
        if (uploadRes['success'] == true) {
          imageUrl = uploadRes['url'];
        }
      }

      final res = await ApiService.post(ApiConfig.reports, {
        'title': title,
        'description': desc,
        if (imageUrl != null) 'screenshot': imageUrl,
      });

      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('reportSubmitted'.tr()),
            backgroundColor: AppColors.success,
          ));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message'] ?? LocaleKeys.failedToSubmitReport.tr()),
            backgroundColor: AppColors.danger,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.reportTitle.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocaleKeys.describeIssue.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                LocaleKeys.provideDetailToFix.tr(),
                style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
            const SizedBox(height: 24),
            VoiceTextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'problemTitleHint'.tr(),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            VoiceTextField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'detailedDescBug'.tr(),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Text(LocaleKeys.screenshotOptional.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.border, style: BorderStyle.none),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_image!, fit: BoxFit.cover))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded,
                              size: 40,
                              color: AppColors.primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text(LocaleKeys.addScreenshot.tr(),
                              style: const TextStyle(color: AppColors.textLight)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(LocaleKeys.submitReport.tr(),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
