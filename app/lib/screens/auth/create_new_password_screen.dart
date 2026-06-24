import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import '../../../l10n/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

// ─────────────────────────────────────────────
// ViewModel  (Riverpod StateNotifier = MVVM VM)
// ─────────────────────────────────────────────

enum ResetPasswordStatus { idle, loading, success, error }

class ResetPasswordState {
  final ResetPasswordStatus status;
  final String? errorMessage;

  const ResetPasswordState({
    this.status = ResetPasswordStatus.idle,
    this.errorMessage,
  });

  ResetPasswordState copyWith({
    ResetPasswordStatus? status,
    String? errorMessage,
  }) =>
      ResetPasswordState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );
}

class ResetPasswordViewModel extends StateNotifier<ResetPasswordState> {
  ResetPasswordViewModel() : super(const ResetPasswordState());

  Future<void> updatePassword(String newPassword) async {
    state = state.copyWith(status: ResetPasswordStatus.loading);

    try {
      // 1. Update password in Supabase Auth
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 2. Sync password change to MongoDB backend
      final session = Supabase.instance.client.auth.currentSession;
      final idToken = session?.accessToken;
      if (idToken != null) {
        final res = await ApiService.post(
          ApiConfig.supabaseResetPassword,
          {
            'idToken': idToken,
            'newPassword': newPassword,
          },
          auth: false,
        );
        if (res['success'] != true) {
          throw Exception(
              res['message'] ?? 'Failed to update backend password');
        }
      } else {
        throw Exception('Auth session is missing!');
      }

      state = state.copyWith(status: ResetPasswordStatus.success);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: ResetPasswordStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: ResetPasswordStatus.error,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }
}

final resetPasswordProvider = StateNotifierProvider.autoDispose<
    ResetPasswordViewModel, ResetPasswordState>(
  (_) => ResetPasswordViewModel(),
);

// ─────────────────────────────────────────────
// View
// ─────────────────────────────────────────────

class CreateNewPasswordScreen extends ConsumerStatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  ConsumerState<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState
    extends ConsumerState<CreateNewPasswordScreen> {
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(resetPasswordProvider.notifier)
        .updatePassword(_newPasswordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordProvider);
    final isLoading = state.status == ResetPasswordStatus.loading;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Listen for success state
    ref.listen<ResetPasswordState>(resetPasswordProvider, (previous, next) {
      if (next.status == ResetPasswordStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.passwordUpdatedPleaseLogin.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigate back to login
        context.go('/auth/login');
      } else if (next.status == ResetPasswordStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Error updating password'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        title: const Text(
          'Create New Password',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Title
                Text(
                  'Set New Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your new password must be at least 8 characters long and contain uppercase, lowercase, numbers, and special characters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyLarge?.color
                        ?.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 36),

                // New Password Field
                _label(context, 'New Password'),
                const SizedBox(height: 8),
                VoiceTextField(
                  controller: _newPasswordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: cs.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: theme.textTheme.bodyLarge?.color
                            ?.withValues(alpha: 0.6),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor:
                        theme.cardTheme.color ?? theme.scaffoldBackgroundColor,
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
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'passwordRequired'.tr();
                    if (v.length < 8) return 'passwordMinLength'.tr();
                    if (!RegExp(r'(?=.*[A-Z])').hasMatch(v))
                      return 'passwordUppercase'.tr();
                    if (!RegExp(r'(?=.*[a-z])').hasMatch(v))
                      return 'passwordLowercase'.tr();
                    if (!RegExp(r'(?=.*\d)').hasMatch(v))
                      return 'passwordNumber'.tr();
                    if (!RegExp(r'(?=.*[\W_])').hasMatch(v))
                      return 'passwordSpecial'.tr();
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Confirm Password Field
                _label(context, 'Confirm Password'),
                const SizedBox(height: 8),
                VoiceTextField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: cs.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: theme.textTheme.bodyLarge?.color
                            ?.withValues(alpha: 0.6),
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    filled: true,
                    fillColor:
                        theme.cardTheme.color ?? theme.scaffoldBackgroundColor,
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
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'confirmPasswordRequired'.tr();
                    if (v != _newPasswordCtrl.text)
                      return 'passwordsDoNotMatch'.tr();
                    return null;
                  },
                ),

                const SizedBox(height: 36),

                // Submit button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: cs.onPrimary, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.color
              ?.withValues(alpha: 0.7),
        ),
      );
}
