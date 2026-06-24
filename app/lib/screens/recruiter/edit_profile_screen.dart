import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../services/secure_upload_service.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class RecruiterEditProfileScreen extends ConsumerStatefulWidget {
  const RecruiterEditProfileScreen({super.key});

  @override
  ConsumerState<RecruiterEditProfileScreen> createState() =>
      _RecruiterEditProfileScreenState();
}

class _RecruiterEditProfileScreenState
    extends ConsumerState<RecruiterEditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _profileImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _companyCtrl.text = user.companyName;
      _emailCtrl.text = user.email == 'None' ? '' : user.email;
      _phoneCtrl.text = user.phone;
      _profileImageUrl = user.profileImage;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final res = await SecureUploadService.uploadImage(
        filePath: image.path,
        uploadType: 'profile',
      );

      if (res['success'] == true) {
        setState(() => _profileImageUrl = res['url']);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message'] ?? LocaleKeys.error.tr()),
            backgroundColor: AppColors.danger,
          ));
        }
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    final fields = {
      'name': _nameCtrl.text.trim(),
      'companyName': _companyCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      if (_profileImageUrl != null) 'profileImage': _profileImageUrl,
    };

    final success = await ref.read(authProvider.notifier).updateProfile(fields);
    if (mounted) {
      if (success) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ${LocaleKeys.profileUpdated.tr()}'),
          backgroundColor: AppColors.success,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ref.read(authProvider).error ?? LocaleKeys.error.tr()),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.editProfile.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _save,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(LocaleKeys.save.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: _profileImageUrl != null &&
                              _profileImageUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(_profileImageUrl!)
                          : null,
                      child: _isUploading
                          ? const CircularProgressIndicator(
                              color: AppColors.primary)
                          : (_profileImageUrl == null ||
                                  _profileImageUrl!.isEmpty)
                              ? const Icon(Icons.business,
                                  size: 40, color: AppColors.primary)
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _card([
              _field(
                  LocaleKeys.fullName.tr(),
                  VoiceTextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        InputDecoration(hintText: LocaleKeys.fullName.tr()),
                  )),
              const SizedBox(height: 16),
              _field(
                  LocaleKeys.companyName.tr(),
                  VoiceTextField(
                    controller: _companyCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        InputDecoration(hintText: LocaleKeys.companyName.tr()),
                  )),
              const SizedBox(height: 16),
              _field(
                  'Email',
                  VoiceTextField(
                    controller: _emailCtrl,
                    readOnly: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'enterYourEmail'.tr(),
                      filled: true,
                      fillColor: AppColors.inputBg.withValues(alpha: 0.5),
                    ),
                    style: const TextStyle(color: AppColors.textMedium),
                  )),
              const SizedBox(height: 16),
              _field(
                  'Phone Number',
                  VoiceTextField(
                    controller: _phoneCtrl,
                    readOnly: true,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'enterPhoneNumber'.tr(),
                      filled: true,
                      fillColor: AppColors.inputBg.withValues(alpha: 0.5),
                    ),
                    style: const TextStyle(color: AppColors.textMedium),
                  )),
            ]),
            const SizedBox(height: 24),

            if (ref.watch(authProvider).user?.role != 'admin')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(context, ref),
                    icon: const Icon(Icons.delete_forever_rounded,
                        color: Colors.white, size: 20),
                    label: Text(LocaleKeys.deleteMyAccount.tr(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocaleKeys.deleteAccountTitle.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(LocaleKeys.deleteAccountDesc.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LocaleKeys.cancel.tr().toUpperCase())),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await ref.read(authProvider.notifier).deleteAccount();
              if (success && context.mounted) context.go('/auth/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(LocaleKeys.yesDelete.tr().toUpperCase(),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _field(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          field,
        ],
      );
}
