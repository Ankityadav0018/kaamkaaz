import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class KycUploadScreen extends ConsumerStatefulWidget {
  const KycUploadScreen({super.key});

  @override
  ConsumerState<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends ConsumerState<KycUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _aadhaarFront;
  File? _aadhaarBack;
  File? _livePhoto;
  File? _licenceFront;
  File? _licenceBack;

  final _aadhaarController = TextEditingController();
  final _expController = TextEditingController();

  int _currentStep = 0;
  bool _isSubmitting = false;
  String _submitStatus = 'Uploading documents...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        if (user.aadhaarNumber.isNotEmpty &&
            !user.aadhaarNumber.startsWith('X')) {
          _aadhaarController.text = user.aadhaarNumber;
        }
        // experienceYears is a non-nullable int (default 0), check driverProfile first
        final driverExp = user.driverProfile?.experienceYears;
        final exp = driverExp != null && driverExp > 0
            ? driverExp
            : (user.experienceYears > 0 ? user.experienceYears : null);
        if (exp != null) {
          _expController.text = exp.toString();
        }
      }
    });
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _expController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type, ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1200,
    );

    if (image != null) {
      if (!mounted) return;
      setState(() {
        switch (type) {
          case 'aadhaarFront':
            _aadhaarFront = File(image.path);
            break;
          case 'aadhaarBack':
            _aadhaarBack = File(image.path);
            break;
          case 'livePhoto':
            _livePhoto = File(image.path);
            break;
          case 'licenceFront':
            _licenceFront = File(image.path);
            break;
          case 'licenceBack':
            _licenceBack = File(image.path);
            break;
        }
      });
    }
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _submitStatus = msg);
  }

  Future<void> _submit() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    if (_aadhaarFront == null || _aadhaarBack == null || _livePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(LocaleKeys.uploadAllDocs.tr()),
            backgroundColor: AppColors.danger),
      );
      return;
    }

    if (user.isDriver &&
        (_licenceFront == null ||
            _licenceBack == null ||
            _expController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(LocaleKeys.uploadAllDocs.tr()),
            backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitStatus = 'Preparing upload...';
    });

    try {
      _setStatus('Uploading Aadhaar front (1/3)...');
      final res = await ref.read(authProvider.notifier).updateKyc(
            aadhaarFront: _aadhaarFront!.path,
            aadhaarBack: _aadhaarBack!.path,
            livePhoto: _livePhoto!.path,
            licenceFront: _licenceFront?.path,
            licenceBack: _licenceBack?.path,
            aadhaarNumber: _aadhaarController.text,
            experienceYears: int.tryParse(_expController.text),
          );

      if (mounted) {
        if (res['success'] == true) {
          if (user.isRecruiter) {
            context.go('/recruiter');
          } else {
            context.go('/worker');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(LocaleKeys.verificationDocsSubmitted.tr()),
                backgroundColor: AppColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(res['message'] ?? LocaleKeys.error.tr()),
                backgroundColor: AppColors.danger,
                duration: const Duration(seconds: 6)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${LocaleKeys.error.tr()}: ${e.toString()}'),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 6)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isDriver = user?.isDriver ?? false;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(LocaleKeys.kycUploadTitle.tr(),
            style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimary)),
        backgroundColor: cs.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: Icon(Icons.logout, color: cs.onPrimary),
          )
        ],
      ),
      body: _isSubmitting
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_submitStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(LocaleKeys.thisMayTakeAMinute.tr(),
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 12)),
              ],
            ))
          : Column(
              children: [
                if (user?.kycStatus == 'rejected' && user!.kycNote.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.danger),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleKeys.kycRejectedAdmin.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.danger,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${LocaleKeys.rejectReason.tr()}: ${user.kycNote}",
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Stepper(
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepContinue: () {
                      if (_currentStep < (isDriver ? 2 : 1)) {
                        setState(() => _currentStep++);
                      } else {
                        _submit();
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) setState(() => _currentStep--);
                    },
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(_currentStep == (isDriver ? 2 : 1)
                                    ? LocaleKeys.submitKyc.tr()
                                    : LocaleKeys.continueText.tr()),
                              ),
                            ),
                            if (_currentStep > 0) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: details.onStepCancel,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: Text(LocaleKeys.back.tr()),
                                ),
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                    steps: [
                      // Step 1: Aadhaar
                      Step(
                        isActive: _currentStep >= 0,
                        state: _currentStep > 0
                            ? StepState.complete
                            : StepState.indexed,
                        title: Text(LocaleKeys.aadhaarFront.tr(),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        content: Column(
                          children: [
                            _buildAadhaarNotice(context),
                            _buildDocPicker(
                              context: context,
                              label: LocaleKeys.aadhaarFront.tr(),
                              file: _aadhaarFront,
                              onTap: () => _pickImage(
                                  'aadhaarFront', ImageSource.gallery),
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildDocPicker(
                              context: context,
                              label: LocaleKeys.aadhaarBack.tr(),
                              file: _aadhaarBack,
                              onTap: () => _pickImage(
                                  'aadhaarBack', ImageSource.gallery),
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 16),
                            VoiceTextField(
                              controller: _aadhaarController,
                              keyboardType: TextInputType.number,
                              maxLength: 12,
                              decoration: InputDecoration(
                                labelText: LocaleKeys.aadhaarNumber.tr(),
                                hintText: LocaleKeys.aadhaarHint.tr(),
                                counterText: "",
                                filled: true,
                                fillColor: theme.cardTheme.color ??
                                    theme.scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Step 2: Live Photo
                      Step(
                        isActive: _currentStep >= 1,
                        state: _currentStep > 1
                            ? StepState.complete
                            : StepState.indexed,
                        title: Text(LocaleKeys.livePhoto.tr(),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        content: _buildDocPicker(
                          context: context,
                          label: LocaleKeys.livePhoto.tr(),
                          file: _livePhoto,
                          onTap: () =>
                              _pickImage('livePhoto', ImageSource.camera),
                          icon: Icons.camera_alt_outlined,
                          isSelfie: true,
                        ),
                      ),
                      // Step 3: Driver specific
                      if (isDriver)
                        Step(
                          isActive: _currentStep >= 2,
                          title: Text(LocaleKeys.drivingLicence.tr(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          content: Column(
                            children: [
                              _buildDocPicker(
                                context: context,
                                label: 'licenceFrontLabel'.tr(),
                                file: _licenceFront,
                                onTap: () => _pickImage(
                                    'licenceFront', ImageSource.gallery),
                                icon: Icons.contact_mail_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildDocPicker(
                                context: context,
                                label: 'licenceBackLabel'.tr(),
                                file: _licenceBack,
                                onTap: () => _pickImage(
                                    'licenceBack', ImageSource.gallery),
                                icon: Icons.contact_mail_outlined,
                              ),
                              const SizedBox(height: 16),
                              VoiceTextField(
                                controller: _expController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: LocaleKeys.expYears.tr(),
                                  filled: true,
                                  fillColor: theme.cardTheme.color ??
                                      theme.scaffoldBackgroundColor,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAadhaarNotice(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.blue.shade900 : Colors.blue.shade50)
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 18, color: isDark ? Colors.blue.shade200 : Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              LocaleKeys.aadhaarNotice.tr(),
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.blue.shade100 : Colors.blueGrey,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocPicker({
    required BuildContext context,
    required String label,
    File? file,
    required VoidCallback onTap,
    required IconData icon,
    bool isSelfie = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ??
              Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: file != null ? AppColors.success : AppColors.border,
              width: 2),
          boxShadow: AppColors.softShadow,
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(file, fit: BoxFit.cover),
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
}
