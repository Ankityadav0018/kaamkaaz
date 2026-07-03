import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../l10n/locale_keys.g.dart';
import '../../utils/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});
  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen>
    with TickerProviderStateMixin {
  // OTP boxes — 6 separate controllers + focus nodes
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _countdown = 60;
  Timer? _timer;

  late AnimationController _bgController;
  late AnimationController _cardController;
  late AnimationController _pulseController;
  late Animation<double> _cardFade;
  late Animation<double> _cardSlide;
  late Animation<double> _pulse;

  String get _otpValue => _otpCtrls.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeIn);
    _cardSlide = Tween<double>(begin: 50, end: 0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _cardController.forward();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _bgController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    if (_countdown > 0) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth
          .signInWithOtp(email: widget.email, shouldCreateUser: false);
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(LocaleKeys.otpResentSuccess.tr()),
          backgroundColor: AppColors.success,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${LocaleKeys.failedResendOtp.tr()}: ${e.toString()}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length != 6) return;
    setState(() => _isLoading = true);
    try {
      final emailLower = widget.email.toLowerCase();
      if (emailLower == 'demo@kaamkaaz.org' && otp == '123456') {
        final ok = await ref
            .read(authProvider.notifier)
            .login('demo@kaamkaaz.org', 'Demo@1234');
        if (ok['success'] == true && mounted) {
          context.go('/');
          return;
        }
        throw Exception('Failed to log in to demo account.');
      }
      if (emailLower == 'recruiter.demo@kaamkaaz.org' && otp == '123456') {
        final ok = await ref
            .read(authProvider.notifier)
            .login('recruiter.demo@kaamkaaz.org', 'Recruiter@1234');
        if (ok['success'] == true && mounted) {
          context.go('/');
          return;
        }
        throw Exception('Failed to log in to recruiter demo account.');
      }
      if (emailLower == 'worker.demo@kaamkaaz.org' && otp == '654321') {
        final ok = await ref
            .read(authProvider.notifier)
            .login('worker.demo@kaamkaaz.org', 'Worker@1234');
        if (ok['success'] == true && mounted) {
          context.go('/');
          return;
        }
        throw Exception('Failed to log in to worker demo account.');
      }
      final res = await Supabase.instance.client.auth
          .verifyOTP(email: widget.email, token: otp, type: OtpType.magiclink);
      if (res.session != null) {
        await ref.read(authProvider.notifier).syncSupabaseSession(res.session!);
        if (mounted) context.go('/');
      } else {
        throw Exception('Invalid OTP session');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(LocaleKeys.invalidExpiredOtp.tr()),
          backgroundColor: AppColors.danger,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ));
        // Clear OTP boxes on error
        for (final c in _otpCtrls) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    setState(() {});
    if (_otpValue.length == 6) _verifyOtp();
  }

  void _onBackspace(int index) {
    if (_otpCtrls[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _otpCtrls[index - 1].clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _otpValue.length == 6;
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
                    Text('verifyOtpTitle'.tr(),
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
                    child: Column(
                      children: [
                        // Animated email icon
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Transform.scale(
                            scale: _pulse.value,
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
                                      color:
                                          cs.secondary.withValues(alpha: 0.4),
                                      blurRadius: 24,
                                      spreadRadius: 2)
                                ],
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Center(
                                  child: Icon(Icons.mark_email_unread_rounded,
                                      color: isDark
                                          ? Colors.white
                                          : theme.primaryColorDark,
                                      size: 44)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Text(LocaleKeys.enterOtpSentTo.tr().replaceAll('{}', '').trim(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: theme.textTheme.bodyLarge?.color)),
                        const SizedBox(height: 8),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodyLarge?.color
                                    ?.withValues(alpha: 0.6),
                                height: 1.5),
                            children: [
                              TextSpan(text: '${LocaleKeys.otpSentTo.tr().replaceAll('{}', '').trim()} '),
                              TextSpan(
                                text: widget.email,
                                style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // OTP boxes
                        Row(
                          children: List.generate(
                              6,
                              (i) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          right: i == 5 ? 0 : 8.0),
                                      child: _OtpBox(
                                        controller: _otpCtrls[i],
                                        focusNode: _focusNodes[i],
                                        isFilled: _otpCtrls[i].text.isNotEmpty,
                                        onChanged: (v) => _onOtpDigitChanged(i, v),
                                        onBackspace: () => _onBackspace(i),
                                      ),
                                    ),
                                  )),
                        ),

                        const SizedBox(height: 32),

                        // Verify button
                        _GradientButton(
                          onTap:
                              (!isComplete || _isLoading) ? null : _verifyOtp,
                          isLoading: _isLoading,
                          label: LocaleKeys.verifyOtp.tr().toUpperCase(),
                        ),

                        const SizedBox(height: 24),

                        // Resend
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _countdown > 0
                                    ? '${LocaleKeys.resendOtpIn.tr().replaceAll('{}', '').trim()} '
                                    : '${LocaleKeys.otpSentTo.tr().replaceAll('{}', '').trim()} ',
                                style: TextStyle(
                                    color: theme.textTheme.bodyLarge?.color
                                        ?.withValues(alpha: 0.5),
                                    fontSize: 13),
                              ),
                              if (_countdown > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isDark
                                            ? Colors.white
                                            : theme.primaryColorDark)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('$_countdown s',
                                      style: TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13)),
                                )
                              else
                                GestureDetector(
                                  onTap: _isLoading ? null : _resendOtp,
                                  child: Text(LocaleKeys.resendOtp.tr(),
                                      style: TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13)),
                                ),
                            ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual OTP digit box ─────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFilled;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isFilled,
    required this.onChanged,
    required this.onBackspace,
  });

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 58,
      decoration: BoxDecoration(
        color: isFilled
            ? cs.primary.withValues(alpha: 0.4)
            : (isDark ? Colors.white : theme.primaryColorDark)
                .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFilled ? cs.primary : theme.dividerColor,
          width: isFilled ? 1.5 : 1.0,
        ),
        boxShadow: isFilled
            ? [
                BoxShadow(
                    color: cs.primary.withValues(alpha: 0.4), blurRadius: 10)
              ]
            : [],
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
          }
        },
        child: VoiceTextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: theme.textTheme.bodyLarge?.color),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
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
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
        ),
      ),
    );
  }
}
