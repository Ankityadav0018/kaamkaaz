import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/app_lock_provider.dart';
import '../services/pin_service.dart';
import '../utils/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../main.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _rotateController;
  late AnimationController _particleController;
  late AnimationController _textController;
  late AnimationController _exitController;

  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoElevation;
  late Animation<double> _rotateY;
  late Animation<double> _ring1Rotate;
  late Animation<double> _ring2Rotate;
  late Animation<double> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _taglineFade;
  late Animation<double> _exitScale;

  final _particleData = <_Particle>[];
  final _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _generateParticles();
    _initAnimations();
    _startSequence();
  }

  void _generateParticles() {
    for (int i = 0; i < 22; i++) {
      _particleData.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 5 + 2,
        speed: _random.nextDouble() * 0.4 + 0.1,
        opacity: _random.nextDouble() * 0.5 + 0.15,
        color: i % 3 == 0
            ? AppColors.primaryLight
            : i % 3 == 1
                ? Colors.white
                : AppColors.accent,
      ));
    }
  }

  void _initAnimations() {
    // Faster animations to reduce initial screen time
    _bgController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _rotateController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _exitController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

    _bgFade = CurvedAnimation(parent: _bgController, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));
    _logoElevation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    
    // Disable initial 90-degree invisible rotation so logo is visible instantly
    _rotateY = Tween<double>(begin: 0.0, end: 0.0).animate(_rotateController); 
    
    _ring1Rotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(CurvedAnimation(parent: _particleController, curve: Curves.linear));
    _ring2Rotate = Tween<double>(begin: 2 * math.pi, end: 0).animate(CurvedAnimation(parent: _particleController, curve: Curves.linear));
    _titleSlide = Tween<double>(begin: 20, end: 0).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _exitScale = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
  }

  void _startSequence() async {
    // Start all animations immediately to avoid waiting on a blue screen
    _bgController.forward();
    _logoController.forward();
    _rotateController.forward();
    _textController.forward();

    // Await background initializations concurrently during the animation
    await Future.wait([
      AppInit.supabaseFuture,
      AppInit.firebaseFuture,
    ]);

    // Fire auth init + animation in parallel
    final authFuture = ref.read(authProvider.notifier).init();

    // Wait for auth init to complete
    try {
      await authFuture;
    } catch (_) {}

    // Very brief hold
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    await _exitController.forward();

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.user != null) {
      // ✅ Session exists → trigger lock if PIN is set, then go home
      final hasPin = await PinService.hasPin();
      if (hasPin) {
        ref.read(appLockProvider.notifier).forceLock();
      }
      if (mounted) context.go('/');
    } else {
      // ❌ No session → go directly to Login
      if (mounted) context.go('/auth/login');
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scaffoldBg = const Color(0xFF060E2A); // Dark background to match native splash

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController, _logoController, _rotateController,
          _particleController, _textController, _exitController,
        ]),
        builder: (context, _) {
          return ScaleTransition(
            scale: _exitScale,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Deep space gradient
                FadeTransition(
                  opacity: _bgFade,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.3),
                        radius: 1.5,
                        colors: [
                          cs.primary.withValues(alpha: 0.3),
                          scaffoldBg.withValues(alpha: 0.8),
                          scaffoldBg,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),

                // Floating particles
                FadeTransition(
                  opacity: _bgFade,
                  child: CustomPaint(
                    painter: _ParticlePainter(_particleData, _particleController.value, size),
                  ),
                ),

                // Center content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow
                            Opacity(
                              opacity: _logoElevation.value * 0.3,
                              child: Container(
                                width: 200, height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [cs.primary.withValues(alpha: 0.6), Colors.transparent]),
                                ),
                              ),
                            ),
                            // Orbit ring 1
                            Opacity(
                              opacity: _logoElevation.value,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateX(0.85)..rotateZ(_ring1Rotate.value),
                                child: Container(
                                  width: 180, height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: cs.primary.withValues(alpha: 0.35), width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            // Orbit ring 2
                            Opacity(
                              opacity: _logoElevation.value * 0.7,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateX(0.4)..rotateZ(_ring2Rotate.value),
                                child: Container(
                                  width: 150, height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 1),
                                  ),
                                ),
                              ),
                            ),
                            // 3D logo flip
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(_rotateY.value),
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: FadeTransition(
                                  opacity: _logoOpacity,
                                  child: Container(
                                    width: 110, height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(color: cs.primary.withValues(alpha: 0.6), blurRadius: 40, spreadRadius: 4),
                                        BoxShadow(color: theme.shadowColor.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: -2, offset: const Offset(-4, -4)),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(18),
                                    child: Image.asset('assets/images/kaamkaaz_app_icon.png', fit: BoxFit.contain),
                                  ),
                                ),
                              ),
                            ),
                            // Orbiting dot
                            Opacity(
                              opacity: _logoElevation.value,
                              child: Transform.rotate(
                                angle: _ring1Rotate.value,
                                child: Transform.translate(
                                  offset: const Offset(90, 0),
                                  child: Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: cs.primary,
                                      boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.8), blurRadius: 6)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Opacity(
                          opacity: _titleFade.value,
                          child: Text(
                            'KAAMKAAZ',
                            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 6,
                                shadows: [Shadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 20)]),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Opacity(
                        opacity: _taglineFade.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          child: Text('connectWorkGrow'.tr(),
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75), letterSpacing: 2.5, fontWeight: FontWeight.w600)),
                        ),
                      ),

                      const SizedBox(height: 60),

                      Opacity(
                        opacity: _taglineFade.value,
                        child: _LoadingDots(controller: _particleController),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Loading dots ──────────────────────────────────────────────────────────
class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = ((controller.value + i / 3) % 1.0);
          final scale = 0.5 + 0.5 * math.sin(t * math.pi);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 7, height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6 + 0.4 * scale)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Particle system ───────────────────────────────────────────────────────
class _Particle {
  final double x, y, size, speed, opacity;
  final Color color;
  _Particle({required this.x, required this.y, required this.size, required this.speed, required this.opacity, required this.color});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  final Size size;
  _ParticlePainter(this.particles, this.t, this.size);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    for (final p in particles) {
      final yOffset = (p.y + t * p.speed) % 1.0;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(p.x * canvasSize.width, yOffset * canvasSize.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
