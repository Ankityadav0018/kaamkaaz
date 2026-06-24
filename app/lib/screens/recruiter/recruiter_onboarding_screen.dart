import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_colors.dart';
import '../../utils/api_config.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/secure_upload_service.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class RecruiterOnboardingScreen extends ConsumerStatefulWidget {
  const RecruiterOnboardingScreen({super.key});
  @override
  ConsumerState<RecruiterOnboardingScreen> createState() =>
      _RecruiterOnboardingScreenState();
}

class _RecruiterOnboardingScreenState
    extends ConsumerState<RecruiterOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  String? _businessType;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();
  File? _aadhaarFront;
  File? _aadhaarBack;
  File? _livePhoto;

  String? _aadhaarFrontUrl;
  String? _aadhaarFrontPublicId;
  String? _aadhaarBackUrl;
  String? _aadhaarBackPublicId;
  String? _selfieUrl;
  String? _selfiePublicId;

  final List<Map<String, String>> _businessTypes = [
    {'value': 'individual', 'label': 'Individual', 'emoji': '👤'},
    {'value': 'contractor', 'label': 'Contractor', 'emoji': '🏗️'},
    {'value': 'factory', 'label': 'Factory', 'emoji': '🏭'},
    {'value': 'farm', 'label': 'Farm', 'emoji': '🌾'},
    {'value': 'company', 'label': 'Company', 'emoji': '🏢'},
    {'value': 'household', 'label': 'Household', 'emoji': '🏠'},
    {'value': 'other', 'label': 'Other', 'emoji': '🔧'},
  ];

  Future<void> _pickImage(String type, ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1200,
    );

    if (image != null) {
      if (!mounted) return;
      setState(() => _loading = true);

      try {
        final res = await SecureUploadService.uploadImage(
          filePath: image.path,
          uploadType: 'kyc',
        );

        if (res['success'] == true) {
          setState(() {
            switch (type) {
              case 'aadhaarFront':
                _aadhaarFront = File(image.path);
                _aadhaarFrontUrl = res['url'];
                _aadhaarFrontPublicId = res['public_id'];
                break;
              case 'aadhaarBack':
                _aadhaarBack = File(image.path);
                _aadhaarBackUrl = res['url'];
                _aadhaarBackPublicId = res['public_id'];
                break;
              case 'livePhoto':
                _livePhoto = File(image.path);
                _selfieUrl = res['url'];
                _selfiePublicId = res['public_id'];
                break;
            }
          });
        } else {
          _showSnack(res['message'] ?? LocaleKeys.error.tr());
        }
      } catch (e) {
        _showSnack(e.toString());
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_aadhaarFrontUrl == null ||
        _aadhaarBackUrl == null ||
        _selfieUrl == null) {
      _showSnack(LocaleKeys.error.tr());
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.post(ApiConfig.recruiterOnboarding, {
        'businessType': _businessType,
        'businessName': _businessNameCtrl.text.trim(),
        'areaOfOperation': _areaCtrl.text.trim(),
        'purposeNote': _purposeCtrl.text.trim(),
        'aadhaarNumber': _aadhaarCtrl.text.trim(),
        'aadhaarFrontUrl': _aadhaarFrontUrl,
        'aadhaarFrontPublicId': _aadhaarFrontPublicId,
        'aadhaarBackUrl': _aadhaarBackUrl,
        'aadhaarBackPublicId': _aadhaarBackPublicId,
        'selfieUrl': _selfieUrl,
        'selfiePublicId': _selfiePublicId,
      });

      if (res['success'] == true) {
        await ref.read(authProvider.notifier).refreshUser();
        if (mounted) context.pushReplacement('/recruiter/verification-pending');
      } else {
        _showSnack(res['message'] ?? LocaleKeys.error.tr());
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating));

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _areaCtrl.dispose();
    _purposeCtrl.dispose();
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
          title: Text(LocaleKeys.getVerified.tr(),
              style: const TextStyle(fontWeight: FontWeight.w800))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.04)
                ]),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Text('🏗️', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(LocaleKeys.recruiterVerification.tr(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(LocaleKeys.verificationFormDesc.tr(),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMedium)),
                    ])),
              ]),
            ),
            const SizedBox(height: 28),
            _label('${LocaleKeys.businessType.tr()} *'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _businessType,
              decoration: _inputDec(LocaleKeys.selectBusinessType.tr()),
              items: _businessTypes
                  .map((t) => DropdownMenuItem(
                        value: t['value'],
                        child: Text('${t['emoji']}  ${t['label']?.tr() ?? ''}'),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() => _businessType = v);
              },
              validator: (v) =>
                  v == null ? LocaleKeys.selectBusinessType.tr() : null,
            ),
            const SizedBox(height: 20),
            _label(
                '${LocaleKeys.businessName.tr()} (${LocaleKeys.optional.tr()})'),
            const SizedBox(height: 8),
            VoiceTextField(
                controller: _businessNameCtrl,
                decoration: _inputDec(LocaleKeys.businessNameHint.tr()),
                textCapitalization: TextCapitalization.words),
            const SizedBox(height: 20),
            _label('${LocaleKeys.areaOfOperation.tr()} *'),
            const SizedBox(height: 8),
            VoiceTextField(
                controller: _areaCtrl,
                decoration: _inputDec(LocaleKeys.areaOfOperationHint.tr()),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? LocaleKeys.areaOfOperation.tr()
                    : null),
            const SizedBox(height: 20),
            _label(
                '${LocaleKeys.whyHiring.tr()} (${LocaleKeys.optional.tr()})'),
            const SizedBox(height: 8),
            VoiceTextField(
                controller: _purposeCtrl,
                maxLines: 4,
                maxLength: 200,
                decoration: _inputDec(LocaleKeys.hiringPurposeHint.tr()),
                buildCounter: (_,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    Text('$currentLength/$maxLength',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textLight))),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            Text(LocaleKeys.identityVerification.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _buildAadhaarNotice(),
            const SizedBox(height: 16),
            _label('${LocaleKeys.aadhaarNumber.tr()} *'),
            const SizedBox(height: 8),
            VoiceTextField(
              controller: _aadhaarCtrl,
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: _inputDec(LocaleKeys.aadhaarNumberHint.tr()),
              validator: (v) => (v == null || v.length != 12)
                  ? LocaleKeys.aadhaarNumberHint.tr()
                  : null,
            ),
            const SizedBox(height: 20),
            _buildDocPicker(
              label: LocaleKeys.aadhaarFrontPhoto.tr(),
              file: _aadhaarFront,
              onTap: () => _pickImage('aadhaarFront', ImageSource.gallery),
              icon: Icons.badge_outlined,
              isUploaded: _aadhaarFrontUrl != null,
            ),
            const SizedBox(height: 16),
            _buildDocPicker(
              label: LocaleKeys.aadhaarBackPhoto.tr(),
              file: _aadhaarBack,
              onTap: () => _pickImage('aadhaarBack', ImageSource.gallery),
              icon: Icons.badge_outlined,
              isUploaded: _aadhaarBackUrl != null,
            ),
            const SizedBox(height: 16),
            _buildDocPicker(
              label: LocaleKeys.liveSelfie.tr(),
              file: _livePhoto,
              onTap: () => _pickImage('livePhoto', ImageSource.camera),
              icon: Icons.camera_alt_outlined,
              isSelfie: true,
              isUploaded: _selfieUrl != null,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_loading || !_isFormValid()) ? null : _submit,
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(LocaleKeys.submitOnboarding.tr(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  bool _isFormValid() {
    return _businessType != null &&
        _areaCtrl.text.isNotEmpty &&
        _aadhaarCtrl.text.length == 12 &&
        _aadhaarFrontUrl != null &&
        _aadhaarBackUrl != null &&
        _selfieUrl != null;
  }

  Widget _buildAadhaarNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
            child: Text(
          LocaleKeys.aadhaarNotice.tr(),
          style: const TextStyle(
              fontSize: 13, color: Colors.blueGrey, height: 1.4),
        )),
      ]),
    );
  }

  Widget _buildDocPicker({
    required String label,
    File? file,
    required VoidCallback onTap,
    required IconData icon,
    bool isSelfie = false,
    bool isUploaded = false,
  }) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isUploaded ? AppColors.success : AppColors.border,
              width: 2),
          boxShadow: AppColors.softShadow,
        ),
        child: isUploaded && file != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: isSelfie
                        ? Center(
                            child: CircleAvatar(
                                radius: 60, backgroundImage: FileImage(file)))
                        : Image.file(file,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                          isSelfie
                              ? '✅ ${LocaleKeys.selfieCaptured.tr()}'
                              : '✅ ${LocaleKeys.uploaded.tr()}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: AppColors.textLight),
                  const SizedBox(height: 8),
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMedium)),
                  const SizedBox(height: 4),
                  Text(
                      isSelfie
                          ? LocaleKeys.tapToTakePhoto.tr()
                          : LocaleKeys.tapToUpload.tr(),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight)),
                ],
              ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textMedium));
  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      );
}
