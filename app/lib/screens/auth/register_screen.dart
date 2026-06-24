import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import '../../widgets/voice_text_field.dart';
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();

  String _role = 'worker';
  String _workerType = 'general';
  bool _obscurePass = true;
  bool _isLoading = false;
  final List<String> _selectedSkills = [];

  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardFade;
  late Animation<double> _cardSlide;

  List<String> get _availableSkills => [
        LocaleKeys.skillConstruction.tr(),
        LocaleKeys.skillPlumbing.tr(),
        LocaleKeys.skillElectrical.tr(),
        LocaleKeys.skillCarpentry.tr(),
        LocaleKeys.skillPainting.tr(),
        LocaleKeys.skillFarming.tr(),
        LocaleKeys.skillCleaning.tr(),
        LocaleKeys.skillCooking.tr(),
        LocaleKeys.skillLoading.tr(),
        LocaleKeys.skillDriving.tr(),
        LocaleKeys.skillSecurity.tr(),
        LocaleKeys.skillTailoring.tr(),
        LocaleKeys.skillMasonry.tr(),
        LocaleKeys.skillWelding.tr(),
        LocaleKeys.skillACRepair.tr(),
      ];

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeIn);
    _cardSlide = Tween<double>(begin: 50, end: 0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
    _cardController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _villageCtrl.dispose();
    _companyCtrl.dispose();
    _areaCtrl.dispose();
    _aadhaarCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_role == 'worker' && _selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(LocaleKeys.selectAtLeastOneSkill.tr()),
        backgroundColor: AppColors.warning,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final phone = _phoneCtrl.text.trim().replaceAll(' ', '');
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authProvider.notifier).register(
            name: _nameCtrl.text.trim(),
            phone: phone,
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
            role: _role,
            aadhaarNumber: _aadhaarCtrl.text.trim(),
            skills: _role == 'worker' ? _selectedSkills : null,
            village: _role == 'worker' ? _villageCtrl.text.trim() : null,
            companyName: _role == 'recruiter' ? _companyCtrl.text.trim() : null,
            businessArea: _role == 'recruiter' ? _areaCtrl.text.trim() : null,
            workerType: _role == 'worker' ? _workerType : null,
            referralCode: _referralCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(LocaleKeys.registrationSuccessful.tr()),
          backgroundColor: AppColors.success,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(result['message'] ?? LocaleKeys.registrationFailed.tr()),
          backgroundColor: AppColors.danger,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${LocaleKeys.error.tr()}: ${e.toString()}'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
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
        child: Column(
          children: [
            // Premium header bar
            AnimatedBuilder(
              animation: _cardController,
              builder: (_, __) => Opacity(
                opacity: _cardFade.value,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/auth/login');
                        }
                      },
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
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(LocaleKeys.createAccount.tr(),
                              style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900)),
                          Text(LocaleKeys.welcomeSub.tr(),
                              style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color
                                      ?.withValues(alpha: 0.6),
                                  fontSize: 12)),
                        ]),
                  ]),
                ),
              ),
            ),

            // Scrollable form
            Expanded(
              child: AnimatedBuilder(
                animation: _cardController,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _cardSlide.value),
                  child: Opacity(opacity: _cardFade.value, child: child),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(children: [
                    // Glass card
                    Container(
                      padding: const EdgeInsets.all(24),
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
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Role picker
                              _sectionLabel(context, LocaleKeys.iamA.tr()),
                              const SizedBox(height: 10),
                              Row(children: [
                                _roleCard(context, 'worker', '👷',
                                    LocaleKeys.worker.tr(), LocaleKeys.kaamgar.tr()),
                                const SizedBox(width: 12),
                                _roleCard(
                                    context,
                                    'recruiter',
                                    '🏢',
                                    LocaleKeys.recruiter.tr(),
                                    LocaleKeys.kaamDeneWala.tr()),
                              ]),
                              const SizedBox(height: 20),

                              _glassField(context,
                                  controller: _nameCtrl,
                                  label: LocaleKeys.fullName.tr(),
                                  hint: LocaleKeys.fullNameHint.tr(),
                                  icon: Icons.person_rounded,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? LocaleKeys.nameRequired.tr()
                                      : null),
                              const SizedBox(height: 14),

                              _glassField(context,
                                  controller: _phoneCtrl,
                                  label: LocaleKeys.phoneNumber.tr(),
                                  hint: LocaleKeys.phoneHint.tr(),
                                  icon: Icons.phone_rounded,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  prefixText: '+91 ', validator: (v) {
                                if (v == null || v.isEmpty)
                                  return LocaleKeys.phoneRequired.tr();
                                if (v.length != 10)
                                  return LocaleKeys.validPhoneError.tr();
                                return null;
                              }),
                              const SizedBox(height: 14),

                              _glassField(context,
                                  controller: _emailCtrl,
                                  label: LocaleKeys.emailAddress.tr(),
                                  hint: LocaleKeys.emailExampleHint.tr(),
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                if (v == null || v.isEmpty)
                                  return LocaleKeys.emailRequired.tr();
                                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(v.trim()))
                                  return LocaleKeys.invalidEmail.tr();
                                return null;
                              }),
                              const SizedBox(height: 14),

                              _glassField(context,
                                  controller: _aadhaarCtrl,
                                  label: LocaleKeys.aadhaarNumber.tr(),
                                  hint: LocaleKeys.aadhaarHint.tr(),
                                  icon: Icons.badge_rounded,
                                  keyboardType: TextInputType.number,
                                  maxLength: 12, validator: (v) {
                                if (v == null || v.isEmpty)
                                  return LocaleKeys.aadhaarRequired.tr();
                                if (v.length != 12)
                                  return LocaleKeys.validAadhaarError.tr();
                                return null;
                              }),
                              const SizedBox(height: 14),

                              _glassField(context,
                                  controller: _passCtrl,
                                  label: LocaleKeys.password.tr(),
                                  hint: LocaleKeys.passwordHint.tr(),
                                  icon: Icons.lock_rounded,
                                  obscureText: _obscurePass,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        _obscurePass
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: theme.textTheme.bodyLarge?.color
                                            ?.withValues(alpha: 0.6),
                                        size: 20),
                                    onPressed: () => setState(
                                        () => _obscurePass = !_obscurePass),
                                  ), validator: (v) {
                                if (v == null || v.isEmpty)
                                  return LocaleKeys.passwordError.tr();
                                if (v.length < 8)
                                  return LocaleKeys.passwordMinLength.tr();
                                if (!RegExp(r'(?=.*[A-Z])').hasMatch(v))
                                  return LocaleKeys.passwordUppercase.tr();
                                if (!RegExp(r'(?=.*[a-z])').hasMatch(v))
                                  return LocaleKeys.passwordLowercase.tr();
                                if (!RegExp(r'(?=.*\d)').hasMatch(v))
                                  return LocaleKeys.passwordNumber.tr();
                                if (!RegExp(r'(?=.*[\W_])').hasMatch(v))
                                  return LocaleKeys.passwordSpecial.tr();
                                return null;
                              }),

                              // Worker-specific
                              if (_role == 'worker') ...[
                                const SizedBox(height: 20),
                                _sectionLabel(
                                    context, LocaleKeys.whatKindOfWork.tr()),
                                const SizedBox(height: 10),
                                Row(children: [
                                  _typeCard(context, 'general', '🔨',
                                      LocaleKeys.generalWorker.tr()),
                                  const SizedBox(width: 12),
                                  _typeCard(context, 'driver', '🚗', LocaleKeys.driver.tr()),
                                ]),
                                const SizedBox(height: 16),
                                _glassField(context,
                                    controller: _villageCtrl,
                                    label: LocaleKeys.villageCity.tr(),
                                    hint: LocaleKeys.villageHint.tr(),
                                    icon: Icons.location_on_rounded,
                                    textCapitalization:
                                        TextCapitalization.words),
                                const SizedBox(height: 16),
                                _sectionLabel(
                                    context, LocaleKeys.yourSkills.tr()),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _availableSkills.map((skill) {
                                    final isSel =
                                        _selectedSkills.contains(skill);
                                    return GestureDetector(
                                      onTap: () => setState(() => isSel
                                          ? _selectedSkills.remove(skill)
                                          : _selectedSkills.add(skill)),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? cs.primary
                                                  .withValues(alpha: 0.3)
                                              : (isDark
                                                      ? Colors.white
                                                      : theme.primaryColorDark)
                                                  .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: isSel
                                                  ? cs.primary
                                                  : theme.dividerColor),
                                        ),
                                        child: Text(skill,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isSel
                                                  ? theme.textTheme.bodyLarge
                                                      ?.color
                                                  : theme.textTheme.bodyLarge
                                                      ?.color
                                                      ?.withValues(alpha: 0.7),
                                            )),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

                              // Recruiter-specific
                              if (_role == 'recruiter') ...[
                                const SizedBox(height: 16),
                                _glassField(context,
                                    controller: _companyCtrl,
                                    label: LocaleKeys.companyNameLabel.tr(),
                                    hint: LocaleKeys.companyHint.tr(),
                                    icon: Icons.business_rounded,
                                    textCapitalization:
                                        TextCapitalization.words),
                                const SizedBox(height: 14),
                                _glassField(context,
                                    controller: _areaCtrl,
                                    label: LocaleKeys.businessAreaLabel.tr(),
                                    hint: LocaleKeys.businessAreaHint.tr(),
                                    icon: Icons.map_rounded,
                                    textCapitalization:
                                        TextCapitalization.words),
                              ],

                              const SizedBox(height: 16),
                              _glassField(context,
                                  controller: _referralCtrl,
                                  label: LocaleKeys.haveReferralCode.tr(),
                                  hint: LocaleKeys.referralCodeHint.tr(),
                                  icon: Icons.card_giftcard_rounded,
                                  textCapitalization:
                                      TextCapitalization.characters),

                              const SizedBox(height: 20),
                              // Terms
                              Center(
                                  child: Wrap(
                                      alignment: WrapAlignment.center,
                                      children: [
                                    Text('${LocaleKeys.byRegistering.tr()} ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .textTheme.bodyLarge?.color
                                                ?.withValues(alpha: 0.5))),
                                    GestureDetector(
                                      onTap: () => launchUrl(
                                          Uri.parse(
                                              'https://kaamkaaz.org/terms-of-service.html'),
                                          mode: LaunchMode.externalApplication),
                                      child: Text(
                                          LocaleKeys.termsConditions.tr(),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: cs.primary,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Text(' ${LocaleKeys.and.tr()} ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .textTheme.bodyLarge?.color
                                                ?.withValues(alpha: 0.5))),
                                    GestureDetector(
                                      onTap: () => launchUrl(
                                          Uri.parse(
                                              'https://kaamkaaz.org/privacy-policy.html'),
                                          mode: LaunchMode.externalApplication),
                                      child: Text(LocaleKeys.privacyPolicy.tr(),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: cs.primary,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ])),

                              const SizedBox(height: 24),
                              // Submit
                              _GradientButton(
                                onTap: (_isLoading || isLoading)
                                    ? null
                                    : _register,
                                isLoading: _isLoading || isLoading,
                                label: LocaleKeys.registerAndVerify.tr(),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        '${LocaleKeys.alreadyHaveAccount.tr()} ',
                                        style: TextStyle(
                                            color: theme
                                                .textTheme.bodyLarge?.color
                                                ?.withValues(alpha: 0.6))),
                                    GestureDetector(
                                      onTap: () {
                                        if (context.canPop()) {
                                          context.pop();
                                        } else {
                                          context.go('/auth/login');
                                        }
                                      },
                                      child: Text(LocaleKeys.login.tr(),
                                          style: TextStyle(
                                              color: cs.primary,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  ]),
                            ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(text,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.color
              ?.withValues(alpha: 0.7)));

  Widget _roleCard(BuildContext context, String role, String emoji,
      String title, String sub) {
    final isSel = _role == role;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSel
                ? cs.primary.withValues(alpha: 0.5)
                : (isDark ? Colors.white : theme.primaryColorDark)
                    .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSel
                    ? cs.primary
                    : (isDark ? Colors.white : theme.primaryColorDark)
                        .withValues(alpha: 0.2),
                width: 1.5),
            boxShadow: isSel
                ? [
                    BoxShadow(
                        color: cs.primary.withValues(alpha: 0.4),
                        blurRadius: 12)
                  ]
                : [],
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSel
                        ? theme.colorScheme.onPrimary
                        : theme.textTheme.bodyLarge?.color
                            ?.withValues(alpha: 0.7))),
            Text(sub,
                style: TextStyle(
                    fontSize: 11,
                    color: isSel
                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.6)
                        : theme.textTheme.bodyLarge?.color
                            ?.withValues(alpha: 0.38))),
          ]),
        ),
      ),
    );
  }

  Widget _typeCard(
      BuildContext context, String type, String emoji, String title) {
    final isSel = _workerType == type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _workerType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSel
                ? AppColors.driving.withValues(alpha: 0.4)
                : (isDark ? Colors.white : theme.primaryColorDark)
                    .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSel
                    ? AppColors.driving
                    : (isDark ? Colors.white : theme.primaryColorDark)
                        .withValues(alpha: 0.2),
                width: 1.5),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSel
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color
                            ?.withValues(alpha: 0.7))),
          ]),
        ),
      ),
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
    int? maxLength,
    String? prefixText,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefixText,
          hintStyle: TextStyle(
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.35),
              fontSize: 14),
          prefixIcon: Icon(icon,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.54),
              size: 20),
          suffixIcon: suffixIcon,
          counterText: '',
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
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.danger, width: 1.5)),
          errorStyle: const TextStyle(color: AppColors.danger),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
      ),
    ]);
  }
}

// Re-export shared widgets (same file approach – import from login_screen if needed)
class _GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;
  const _GradientButton(
      {required this.onTap, required this.isLoading, required this.label});
  @override
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
