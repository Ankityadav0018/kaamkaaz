import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../providers/app_lock_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/pin_service.dart';
import '../../utils/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isError = false;
  late AnimationController _shakeController;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _secureScreen(true);
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoTriggerBiometric();
    });
  }

  @override
  void dispose() {
    _secureScreen(false);
    _shakeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  static const _channel = MethodChannel('org.kaamkaaz.app/security');

  Future<void> _secureScreen(bool secure) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('secureScreen', {'secure': secure});
      } catch (_) {}
    }
  }

  Future<void> _autoTriggerBiometric() async {
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    if (canCheck) {
      try {
        final ok = await auth.authenticate(localizedReason: 'Unlock Kaamkaaz');
        if (ok) {
          ref.read(appLockProvider.notifier).unlock();
        }
      } catch (_) {}
    }
  }

  void _onNumPressed(String num) {
    if (_pin.length < 6) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin += num;
        _isError = false;
      });
      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final success = await ref.read(appLockProvider.notifier).verifyAndUnlock(_pin);
    if (!success) {
      HapticFeedback.lightImpact();
      _shakeController.forward(from: 0);
      setState(() {
        _isError = true;
        _pin = '';
      });
      _checkLockout();
    }
  }

  void _checkLockout() {
    final state = ref.read(appLockProvider);
    if (state.lockedUntil != null && state.lockedUntil!.isAfter(DateTime.now())) {
      _remainingSeconds = state.lockedUntil!.difference(DateTime.now()).inSeconds;
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
            if (_remainingSeconds <= 0) {
              timer.cancel();
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appLockProvider, (prev, next) {
      if (next.lockedUntil != null && prev?.lockedUntil != next.lockedUntil) {
        _checkLockout();
      }
    });

    final lockState = ref.watch(appLockProvider);
    final authState = ref.watch(authProvider);
    final isLockedOut = lockState.lockedUntil != null && lockState.lockedUntil!.isAfter(DateTime.now());
    
    final firstName = (authState.user?.name ?? 'User').split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFF060E2A), // Deep dark blue background
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
            // Logo
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(12),
              child: Image.asset('assets/images/kaamkaaz_app_icon.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            // Title
            const Text(
              'KAAMKAAZ',
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.w700, 
                color: Colors.white,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 16),
            // User Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Text(
                'Welcome back, $firstName 👋',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isLockedOut
                  ? 'Try again in \$_remainingSeconds s'
                  : 'Enter PIN to unlock',
              style: TextStyle(
                fontSize: 15,
                color: isLockedOut ? AppColors.danger : Colors.white70,
                fontWeight: isLockedOut ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 40),
            
            // PIN Dots
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final offset = _shakeController.isAnimating
                    ? (1 - _shakeController.value) * 10 * ((_shakeController.value * 5).floor().isEven ? 1 : -1)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? Colors.white : Colors.white.withValues(alpha: 0.2),
                    ),
                  );
                }),
              ),
            ),
            
            const Spacer(),
            
            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: IgnorePointer(
                ignoring: isLockedOut,
                child: Opacity(
                  opacity: isLockedOut ? 0.5 : 1.0,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _NumBtn('1', () => _onNumPressed('1')),
                          _NumBtn('2', () => _onNumPressed('2')),
                          _NumBtn('3', () => _onNumPressed('3')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _NumBtn('4', () => _onNumPressed('4')),
                          _NumBtn('5', () => _onNumPressed('5')),
                          _NumBtn('6', () => _onNumPressed('6')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _NumBtn('7', () => _onNumPressed('7')),
                          _NumBtn('8', () => _onNumPressed('8')),
                          _NumBtn('9', () => _onNumPressed('9')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionBtn(Icons.fingerprint, _autoTriggerBiometric),
                          _NumBtn('0', () => _onNumPressed('0')),
                          _ActionBtn(Icons.backspace_outlined, _onDeletePressed),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('needs_pin_setup', true);
                
                await PinService.clearPin();
                ref.read(appLockProvider.notifier).unlock();
                await ref.read(authProvider.notifier).logout();
                if (mounted) context.go('/auth/login');
              },
              child: Text('forgotPin'.tr(), style: TextStyle(color: Colors.white54, fontSize: 14)),
            ),
                    const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NumBtn extends StatelessWidget {
  final String num;
  final VoidCallback onTap;
  const _NumBtn(this.num, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        child: Center(
          child: Text(
            num,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        height: 75,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Icon(icon, size: 28, color: Colors.white70),
        ),
      ),
    );
  }
}
