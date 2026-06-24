import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final res = await ApiService.put(ApiConfig.changePassword, {
        'oldPassword': _oldPasswordCtrl.text.trim(),
        'newPassword': _newPasswordCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(res['message'] ?? LocaleKeys.passwordChangedSuccess.tr()),
          backgroundColor: AppColors.success,
        ));
        Navigator.pop(context);
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
        title: Text(LocaleKeys.changePassword.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded,
                        color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        LocaleKeys.passwordRequirementWarning.tr(),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMedium),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(LocaleKeys.oldPassword.tr(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              VoiceTextField(
                controller: _oldPasswordCtrl,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? LocaleKeys.required.tr() : null,
              ),
              const SizedBox(height: 20),

              Text(LocaleKeys.newPassword.tr(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              VoiceTextField(
                controller: _newPasswordCtrl,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                validator: (v) {
                  if (v!.isEmpty) return LocaleKeys.required.tr();
                  if (v.length < 6) return LocaleKeys.atLeast6Char.tr();
                  // Basic strength check
                  bool hasLetter = v.contains(RegExp(r'[a-zA-Z]'));
                  bool hasDigit = v.contains(RegExp(r'[0-9]'));
                  if (!hasLetter || !hasDigit) {
                    return LocaleKeys.mixLettersNumbers.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Text(LocaleKeys.confirmPassword.tr(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              VoiceTextField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                validator: (v) {
                  if (v != _newPasswordCtrl.text) {
                    return LocaleKeys.passwordMismatch.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(LocaleKeys.changePassword.tr().toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
