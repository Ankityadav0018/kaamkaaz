import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/app_colors.dart';
import '../../services/remember_me_service.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _rememberMe = false;
  bool _isOtpMode = false;
  bool _isSendingOtp = false;

  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardSlide = Tween<double>(begin: 60, end: 0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeIn));
    _bgAnim = CurvedAnimation(parent: _bgController, curve: Curves.linear);
    _cardController.forward();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final data = await RememberMeService.loadCredentials();
    if (!mounted) return;
    if (data['isRemembered'] == true) {
      final phone = data['phoneOrEmail'] as String;
      final pass = data['password'] as String;
      if (phone.isNotEmpty && pass.isNotEmpty) {
        setState(() {
          _identifierCtrl.text = phone;
          _passCtrl.text = pass;
          _rememberMe = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _identifierCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final identifier = _identifierCtrl.text.trim();
    final pass = _passCtrl.text;
    final success = await ref
        .read(authProvider.notifier)
        .login(identifier, pass, rememberMe: _rememberMe);
    if (!success) {
      if (!mounted) return;
      _showSnack(ref.read(authProvider).error ?? 'Login failed', isError: true);
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _identifierCtrl.text.trim();
    if (!email.contains('@')) {
      _showSnack('Please enter a valid email for OTP login', isError: true);
      return;
    }
    setState(() => _isSendingOtp = true);
    try {
      final emailExists = await AuthService.checkEmail(email);
      if (!mounted) return;
      if (!emailExists) {
        _showSnack('No account found with this email.', isError: true);
        setState(() => _isSendingOtp = false);
        return;
      }
      if ([
        'demo@kaamkaaz.org',
        'recruiter.demo@kaamkaaz.org',
        'worker.demo@kaamkaaz.org'
      ].contains(email.toLowerCase())) {
        _showSnack('A 6-digit code has been sent to your email',
            isError: false);
        context.push('/auth/verify-otp', extra: email);
        setState(() => _isSendingOtp = false);
        return;
      }
      await Supabase.instance.client.auth
          .signInWithOtp(email: email, shouldCreateUser: false);
      if (!mounted) return;
      _showSnack('A 6-digit code has been sent to your email', isError: false);
      context.push('/auth/verify-otp', extra: email);
    } on AuthException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    String msg = message;
    if (msg.startsWith('Exception: '))
      msg = msg.replaceFirst('Exception: ', '');
    if (msg.startsWith('error_')) msg = msg.tr();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onError)),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _changeLang(String code) async {
    if (context.locale.languageCode == code) return;
    await ref.read(localeProvider.notifier).changeLocale(context, Locale(code));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // Logo + title block
                  AnimatedBuilder(
                    animation: _cardController,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _cardSlide.value * 0.5),
                      child: Opacity(
                        opacity: _cardFade.value,
                        child: Column(
                          children: [
                            // 3D-look logo container
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.6),
                                      blurRadius: 30,
                                      spreadRadius: 2),
                                  BoxShadow(
                                      color: theme.shadowColor
                                          .withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(-3, -3)),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Image.asset(
                                  'assets/images/kaamkaaz_app_icon.png',
                                  fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 16),
                            Text('KAAMKAAZ',
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: theme.textTheme.bodyLarge?.color,
                                    letterSpacing: 4)),
                            const SizedBox(height: 6),
                            Text(LocaleKeys.welcomeSub.tr(),
                                style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textTheme.bodyLarge?.color
                                        ?.withValues(alpha: 0.65),
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Glass card ──────────────────────────
                  AnimatedBuilder(
                    animation: _cardController,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _cardSlide.value),
                      child: Opacity(opacity: _cardFade.value, child: child),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: theme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                              color: theme.shadowColor.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 12)),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isOtpMode ? LocaleKeys.otpLogin.tr() : LocaleKeys.login.tr(),
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: theme.textTheme.bodyLarge?.color),
                            ),
                            const SizedBox(height: 20),

                            _glassField(
                              context,
                              controller: _identifierCtrl,
                              label: _isOtpMode
                                  ? LocaleKeys.emailAddress.tr()
                                  : 'phoneNumberOrEmail'.tr(),
                              hint: _isOtpMode
                                  ? LocaleKeys.enterYourEmail.tr()
                                  : 'enterPhoneOrEmail'.tr(),
                              icon: _isOtpMode
                                  ? Icons.email_outlined
                                  : Icons.person_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              inputFormatters: _isOtpMode
                                  ? []
                                  : [
                                      TextInputFormatter.withFunction(
                                          (old, nv) {
                                        if (nv.text
                                            .contains(RegExp(r'[a-zA-Z@]')))
                                          return nv;
                                        if (nv.text.length > 10) return old;
                                        return nv;
                                      }),
                                    ],
                              validator: (v) {
                                if (v == null || v.isEmpty) return LocaleKeys.required.tr();
                                if (_isOtpMode) {
                                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(v.trim()))
                                    return LocaleKeys.invalidEmail.tr();
                                }
                                return null;
                              },
                            ),

                            if (!_isOtpMode) ...[
                              const SizedBox(height: 14),
                              _glassField(
                                context,
                                controller: _passCtrl,
                                label: LocaleKeys.password.tr(),
                                hint: LocaleKeys.passwordHint.tr(),
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePass,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _obscurePass
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: theme.textTheme.bodyLarge?.color
                                          ?.withValues(alpha: 0.6),
                                      size: 20),
                                  onPressed: () => setState(
                                      () => _obscurePass = !_obscurePass),
                                ),
                                validator: (v) => (v == null || v.length < 6)
                                    ? LocaleKeys.passwordError.tr()
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              Row(children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.primaryLight,
                                    checkColor: theme.colorScheme.onPrimary,
                                    side: BorderSide(
                                        color: theme.textTheme.bodyLarge?.color
                                                ?.withValues(alpha: 0.38) ??
                                            Colors.transparent),
                                    onChanged: (v) => setState(
                                        () => _rememberMe = v ?? false),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('rememberMe'.tr(),
                                    style: TextStyle(
                                        color: theme.textTheme.bodyLarge?.color
                                            ?.withValues(alpha: 0.7),
                                        fontSize: 13)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => context.push('/forgot-password'),
                                  child: Text('forgotPasswordQ'.tr(),
                                      style: const TextStyle(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ),
                              ]),
                            ],

                            const SizedBox(height: 22),

                            // Primary action button
                            _GradientButton(
                              onTap: isLoading || _isSendingOtp
                                  ? null
                                  : (_isOtpMode
                                      ? _sendOtp
                                      : _loginWithPassword),
                              isLoading: isLoading || _isSendingOtp,
                              label: _isOtpMode
                                  ? 'sendOtpBtn'.tr()
                                  : 'loginBtn'.tr(),
                            ),

                            const SizedBox(height: 12),

                            // Toggle OTP / Password
                            OutlinedButton(
                              onPressed: () =>
                                  setState(() => _isOtpMode = !_isOtpMode),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: theme.scaffoldBackgroundColor
                                    .withValues(alpha: 0.5),
                                side: BorderSide(color: theme.dividerColor),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                _isOtpMode
                                    ? 'loginWithPasswordBtn'.tr()
                                    : 'loginWithOtpBtn'.tr(),
                                style: TextStyle(
                                    color: theme.textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Register link
                  AnimatedBuilder(
                    animation: _cardController,
                    builder: (_, __) => Opacity(
                      opacity: _cardFade.value,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(LocaleKeys.noAccount.tr(),
                                style: TextStyle(
                                    color: theme.textTheme.bodyLarge?.color
                                        ?.withValues(alpha: 0.6),
                                    fontSize: 14)),
                            GestureDetector(
                              onTap: () => context.push('/auth/register'),
                              child: Text(' ${LocaleKeys.register.tr()}',
                                  style: const TextStyle(
                                      color: AppColors.primaryLight,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                            ),
                          ]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Legal footer
                  AnimatedBuilder(
                    animation: _cardController,
                    builder: (_, __) => Opacity(
                      opacity: _cardFade.value * 0.7,
                      child: Column(children: [
                        Divider(color: theme.dividerColor, height: 1),
                        const SizedBox(height: 14),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _footerLink(
                                  Icons.gavel_outlined, LocaleKeys.legalAndInformation.tr(),
                                  () async {
                                await launchUrl(
                                    Uri.parse('https://kaamkaaz.org'),
                                    mode: LaunchMode.externalApplication);
                              }),
                              const SizedBox(width: 24),
                              _footerLink(
                                  Icons.bug_report_outlined,
                                  LocaleKeys.reportProblem.tr(),
                                  () => context.push('/report-problem')),
                            ]),
                        const SizedBox(height: 10),
                        Text('© 2026 Kaamkaaz | India',
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.textTheme.bodyLarge?.color
                                    ?.withValues(alpha: 0.35))),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // Language selector
            Positioned(
              top: 12,
              right: 12,
              child: _glassLangSelector(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerLink(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.primaryLight),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _glassField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7))),
      const SizedBox(height: 8),
      VoiceTextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.35),
              fontSize: 14),
          prefixIcon: Icon(icon,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.54),
              size: 20),
          suffixIcon: suffixIcon,
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
          errorStyle: const TextStyle(color: AppColors.danger),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
      ),
    ]);
  }

  Widget _glassLangSelector() {
    final theme = Theme.of(context);
    final code = context.locale.languageCode;

    // Full names shown in the open dropdown list
    final languages = [
      {'code': 'en',  'label': 'EN',         'fullName': 'English'},
      {'code': 'hi',  'label': 'हिं',         'fullName': 'हिंदी'},
      {'code': 'bgc', 'label': 'हरि',        'fullName': 'हरियाणवी (हरियाणा)'},
      {'code': 'raj', 'label': 'राज',        'fullName': 'राजस्थानी (राजस्थान)'},
      {'code': 'pa',  'label': 'ਪੰ',          'fullName': 'ਪੰਜਾਬੀ'},
      {'code': 'mr',  'label': 'मरा',        'fullName': 'मराठी'},
      {'code': 'gu',  'label': 'ગુ',          'fullName': 'ગુજરાતી'},
      {'code': 'bn',  'label': 'বাং',        'fullName': 'বাংলা'},
      {'code': 'ta',  'label': 'தமி',        'fullName': 'தமிழ்'},
      {'code': 'te',  'label': 'తెలు',       'fullName': 'తెలుగు'},
      {'code': 'kn',  'label': 'ಕನ್ನ',      'fullName': 'ಕನ್ನಡ'},
      {'code': 'ml',  'label': 'മല',         'fullName': 'മലയാളം'},
      {'code': 'or',  'label': 'ଓ',           'fullName': 'ଓଡ଼ିଆ'},
      {'code': 'ur',  'label': 'اردو',       'fullName': 'اردو'},
    ];

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: code,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
              size: 18),
          elevation: 16,
          isDense: true,
          menuMaxHeight: 320,
          dropdownColor: theme.cardTheme.color,
          style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 13),
          // Show the short label on the collapsed button
          selectedItemBuilder: (context) => languages
              .map((lang) => DropdownMenuItem<String>(
                    value: lang['code'],
                    child: Text(
                      lang['label']!,
                      style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) _changeLang(v);
          },
          // Show full native names in the open dropdown list
          items: languages
              .map((lang) => DropdownMenuItem<String>(
                    value: lang['code'],
                    child: Text(
                      lang['fullName']!,
                      style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSocialBtn(String icon, String title) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/$icon.png', height: 22, width: 22),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── Shared 3D-look gradient button ───────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;
  const _GradientButton(
      {required this.onTap, required this.isLoading, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: onTap == null
              ? LinearGradient(colors: [
                  theme.disabledColor.withValues(alpha: 0.5),
                  theme.disabledColor.withValues(alpha: 0.3)
                ])
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                    theme.primaryColorDark
                  ],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap == null
              ? []
              : [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 8)),
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
