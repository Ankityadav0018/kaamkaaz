import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../l10n/locale_keys.g.dart';
import '../../utils/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class AdminOtpScreen extends ConsumerStatefulWidget {
  final String method; // 'email' or 'totp'
  const AdminOtpScreen({super.key, required this.method});
  @override
  ConsumerState<AdminOtpScreen> createState() => _AdminOtpScreenState();
}

class _AdminOtpScreenState extends ConsumerState<AdminOtpScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;

  late AnimationController _cardController;
  late Animation<double> _cardFade;
  late Animation<double> _cardSlide;

  String get _otpValue => _otpCtrls.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeIn);
    _cardSlide = Tween<double>(begin: 50, end: 0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
    _cardController.forward();
  }

  @override
  void dispose() {
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length != 6) return;
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authProvider.notifier).adminVerifyOtp(otp);
      if (success && mounted) {
        context.go('/');
      } else {
        throw Exception(ref.read(authProvider).error ?? 'Invalid OTP');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ));
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
                          color: (isDark ? Colors.white : theme.primaryColorDark)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: (isDark ? Colors.white : theme.primaryColorDark)
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            color: theme.textTheme.bodyLarge?.color, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Admin Identity Check',
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
                        const SizedBox(height: 24),
                        Text('Enter OTP Code',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: theme.textTheme.bodyLarge?.color)),
                        const SizedBox(height: 8),
                        Text(
                          widget.method == 'totp'
                              ? 'Enter the 6-digit code from your Authenticator app.'
                              : 'A 6-digit one-time code has been sent to your admin email.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withValues(alpha: 0.6),
                              height: 1.5),
                        ),
                        const SizedBox(height: 36),
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
                        GestureDetector(
                          onTap: (!isComplete || _isLoading) ? null : _verifyOtp,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 52,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: (!isComplete || _isLoading)
                                  ? LinearGradient(colors: [
                                      theme.disabledColor.withValues(alpha: 0.5),
                                      theme.disabledColor.withValues(alpha: 0.3)
                                    ])
                                  : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [cs.primary, cs.secondary, theme.primaryColorDark]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: (!isComplete || _isLoading)
                                  ? []
                                  : [
                                      BoxShadow(
                                          color: cs.primary.withValues(alpha: 0.5),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8))
                                    ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          strokeWidth: 2.5))
                                  : Text('VERIFY IDENTITY',
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5)),
                            ),
                          ),
                        ),
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
            : (isDark ? Colors.white : theme.primaryColorDark).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFilled ? cs.primary : theme.dividerColor,
          width: isFilled ? 1.5 : 1.0,
        ),
        boxShadow: isFilled
            ? [BoxShadow(color: cs.primary.withValues(alpha: 0.4), blurRadius: 10)]
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
