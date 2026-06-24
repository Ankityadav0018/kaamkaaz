import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class AddEmailScreen extends ConsumerStatefulWidget {
  const AddEmailScreen({super.key});

  @override
  ConsumerState<AddEmailScreen> createState() => _AddEmailScreenState();
}

class _AddEmailScreenState extends ConsumerState<AddEmailScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailCtrl.text.trim();

    try {
      // Update email in both MongoDB and Supabase Auth securely via our backend endpoint
      final response =
          await ApiService.post(ApiConfig.addEmail, {'email': email});

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to update email');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.emailSavedSuccess.tr()),
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh the user model in AuthProvider so the router unblocks them
      await ref.read(authProvider.notifier).refreshUser();

      if (!mounted) return;
      // Navigate to home screen
      final user = ref.read(authProvider).user;
      if (user?.role == 'worker') {
        context.go('/worker');
      } else if (user?.role == 'recruiter') {
        context.go('/recruiter');
      } else if (user?.role == 'admin') {
        context.go('/admin');
      } else {
        context.go('/worker');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false, // Disables back button
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.mark_email_read_rounded,
                      size: 80, color: cs.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Add Your Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please add your email address.\nIt is required for account security and password recovery.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color
                          ?.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  VoiceTextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: LocaleKeys.enterEmailAddress.tr(),
                      prefixIcon: Icon(Icons.email_rounded, color: cs.primary),
                      filled: true,
                      fillColor: theme.cardTheme.color ??
                          theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.primary, width: 2),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'emailRequired'.tr();
                      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'invalidEmail'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: cs.onPrimary, strokeWidth: 2),
                            )
                          : const Text(
                              'Save Email',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
