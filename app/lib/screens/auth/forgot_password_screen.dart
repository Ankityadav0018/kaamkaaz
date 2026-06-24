import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

enum ForgotPasswordStatus { idle, loading, success, error }

class ForgotPasswordState {
  final ForgotPasswordStatus status;
  final String? errorMessage;
  const ForgotPasswordState(
      {this.status = ForgotPasswordStatus.idle, this.errorMessage});
  ForgotPasswordState copyWith(
          {ForgotPasswordStatus? status, String? errorMessage}) =>
      ForgotPasswordState(
          status: status ?? this.status, errorMessage: errorMessage);
}

class ForgotPasswordViewModel extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordViewModel() : super(const ForgotPasswordState());

  Future<void> sendResetEmail(String email) async {
    final trimmed = email.trim().toLowerCase();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (trimmed.isEmpty || !emailRegex.hasMatch(trimmed)) {
      state = state.copyWith(
          status: ForgotPasswordStatus.error,
          errorMessage: 'Please enter a valid email address');
      return;
    }
    state = state.copyWith(status: ForgotPasswordStatus.loading);
    try {
      await Supabase.instance.client.functions
          .invoke('send-reset-email', body: {'email': trimmed});
      state = state.copyWith(status: ForgotPasswordStatus.success);
    } on FunctionException catch (e) {
      String errorMsg = 'Something went wrong. Please try again.';
      if (e.status == 404 ||
          (e.details ?? '').toString().contains('not registered')) {
        errorMsg = 'This email is not registered. Please sign up first.';
      } else {
        errorMsg = e.details?.toString() ?? errorMsg;
      }
      state = state.copyWith(
          status: ForgotPasswordStatus.error, errorMessage: errorMsg);
    } catch (e) {
      state = state.copyWith(
          status: ForgotPasswordStatus.error,
          errorMessage: 'Network error. Please try again.');
    }
  }

  void reset() => state = const ForgotPasswordState();
}

final forgotPasswordProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordViewModel, ForgotPasswordState>(
  (_) => ForgotPasswordViewModel(),
);

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _bgController;
  late AnimationController _cardController;
  late AnimationController _iconController;
  late Animation<double> _cardFade;
  late Animation<double> _cardSlide;
  late Animation<double> _iconRotate;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _iconController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeIn);
    _cardSlide = Tween<double>(begin: 50, end: 0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
    _iconRotate = Tween<double>(begin: -math.pi / 4, end: 0).animate(
        CurvedAnimation(parent: _iconController, curve: Curves.elasticOut));
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconController, curve: Curves.elasticOut));
    _cardController.forward();
    _iconController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _iconController.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(forgotPasswordProvider.notifier).reset();
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(forgotPasswordProvider.notifier)
        .sendResetEmail(_emailCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);
    final isLoading = state.status == ForgotPasswordStatus.loading;
    final isSuccess = state.status == ForgotPasswordStatus.success;
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AnimatedBuilder(
              animation: _cardController,
              builder: (_, __) => Opacity(
                opacity: _cardFade.value,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              (isDark ? Colors.white : theme.primaryColorDark)
                                  .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: (isDark
                                      ? Colors.white
                                      : theme.primaryColorDark)
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            color: theme.textTheme.bodyLarge?.color, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('forgotPassword'.tr(),
                        style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                  ]),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: AnimatedBuilder(
                  animation: _cardController,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _cardSlide.value),
                    child: Opacity(opacity: _cardFade.value, child: child),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: theme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                            color: theme.shadowColor.withValues(alpha: 0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 12))
                      ],
                    ),
                    child: isSuccess
                        ? _buildSuccess(context)
                        : _buildForm(state, isLoading, context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
      ForgotPasswordState state, bool isLoading, BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(children: [
        // Animated 3D lock icon
        AnimatedBuilder(
          animation: _iconController,
          builder: (_, __) => Transform.rotate(
            angle: _iconRotate.value,
            child: Transform.scale(
              scale: _iconScale.value,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    cs.secondary.withValues(alpha: 0.6),
                    cs.primary.withValues(alpha: 0.4),
                  ]),
                  boxShadow: [
                    BoxShadow(
                        color: cs.secondary.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 2),
                  ],
                  border: Border.all(color: theme.dividerColor),
                ),
                child: const Center(
                    child: Text('🔒', style: TextStyle(fontSize: 40))),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
        Text('resetYourPassword'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: 10),
        Text('enterRegisteredEmailResetLink'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                height: 1.5)),

        const SizedBox(height: 32),

        // Email field
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('emailAddress'.tr(),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color
                      ?.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          VoiceTextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            style: TextStyle(
                color: theme.textTheme.bodyLarge?.color, fontSize: 15),
            decoration: InputDecoration(
              hintText: LocaleKeys.emailHintGmail.tr(),
              hintStyle: TextStyle(
                  color:
                      theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.35),
                  fontSize: 14),
              prefixIcon: Icon(Icons.email_outlined,
                  color:
                      theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.54),
                  size: 20),
              filled: true,
              fillColor: (isDark ? Colors.white : theme.primaryColorDark)
                  .withValues(alpha: 0.1),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: (isDark ? Colors.white : theme.primaryColorDark)
                          .withValues(alpha: 0.15))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.primary, width: 1.5)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.danger)),
              errorStyle: const TextStyle(color: AppColors.danger),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'emailRequired'.tr();
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()))
                return 'invalidEmail'.tr();
              return null;
            },
          ),
        ]),

        // Error box
        if (state.status == ForgotPasswordStatus.error &&
            state.errorMessage != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.danger, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(state.errorMessage!,
                      style: const TextStyle(
                          color: Color(0xFFFF8A80), fontSize: 13))),
            ]),
          ),
        ],

        const SizedBox(height: 28),

        _GradientButton(
            onTap: isLoading ? null : _submit,
            isLoading: isLoading,
            label: 'sendResetLink'.tr()),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.pop(),
          child: Text('backToLogin'.tr(),
              style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ),
      ]),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(children: [
      // Animated success icon
      AnimatedBuilder(
        animation: _iconController,
        builder: (_, __) => Transform.scale(
          scale: _iconScale.value,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.success.withValues(alpha: 0.6),
                AppColors.success.withValues(alpha: 0.3),
              ]),
              boxShadow: [
                BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 2)
              ],
              border: Border.all(color: theme.dividerColor),
            ),
            child:
                const Center(child: Text('✅', style: TextStyle(fontSize: 40))),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text('checkYourEmail'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: theme.textTheme.bodyLarge?.color)),
      const SizedBox(height: 12),
      Text(
        'A password reset link has been sent to\n${_emailCtrl.text.trim()}\n\nPlease check your inbox and spam folder.',
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 13,
            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.65),
            height: 1.6),
      ),
      const SizedBox(height: 32),
      OutlinedButton.icon(
        onPressed: () => ref.read(forgotPasswordProvider.notifier).reset(),
        icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryLight),
        label: Text(LocaleKeys.resendLink.tr(),
            style: const TextStyle(
                color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          side:
              BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.6)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      const SizedBox(height: 14),
      _GradientButton(
          onTap: () => context.go('/auth/login'),
          isLoading: false,
          label: 'goToLogin'.tr()),
    ]);
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;
  const _GradientButton(
      {required this.onTap, required this.isLoading, required this.label});
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: onTap == null
              ? LinearGradient(colors: [
                  theme.disabledColor.withValues(alpha: 0.5),
                  theme.disabledColor.withValues(alpha: 0.3)
                ])
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, cs.secondary, theme.primaryColorDark]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap == null
              ? []
              : [
                  BoxShadow(
                      color: cs.primary.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 8))
                ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 2.5))
              : Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
