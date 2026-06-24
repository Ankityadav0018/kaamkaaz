import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pin_service.dart';
import 'auth_provider.dart';

class AppLockState {
  final bool isLocked;
  final int failedAttempts;
  final int lockoutCycles;
  final DateTime? lockedUntil;

  AppLockState({
    this.isLocked = false,
    this.failedAttempts = 0,
    this.lockoutCycles = 0,
    this.lockedUntil,
  });

  AppLockState copyWith({
    bool? isLocked,
    int? failedAttempts,
    int? lockoutCycles,
    DateTime? lockedUntil,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutCycles: lockoutCycles ?? this.lockoutCycles,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  final Ref ref;
  Timer? _idleTimer;
  DateTime? _lastBackgroundedTime;
  static const _gracePeriod = Duration(seconds: 15);
  static const _idleTimeout = Duration(minutes: 2);

  AppLockNotifier(this.ref) : super(AppLockState()) {
    _initColdStart();
    _startIdleTimer();
  }

  Future<void> _initColdStart() async {
    // Instantly lock on cold start if PIN is set
    if (await PinService.hasPin()) {
      state = state.copyWith(isLocked: true);
    }
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, () {
      final user = ref.read(authProvider).user;
      if (user != null && !state.isLocked) {
        _lockIfNeeded();
      }
    });
  }

  void recordActivity() {
    if (!state.isLocked) {
      _startIdleTimer();
    }
  }

  void recordBackgrounded() {
    _lastBackgroundedTime = DateTime.now();
    _idleTimer?.cancel();
  }

  Future<void> checkAndLockIfNeeded({required bool isLoggedIn}) async {
    if (!isLoggedIn) return;
    
    // Check grace period
    if (_lastBackgroundedTime != null) {
      final elapsed = DateTime.now().difference(_lastBackgroundedTime!);
      if (elapsed < _gracePeriod) {
        _startIdleTimer();
        return;
      }
    }
    
    await _lockIfNeeded();
  }

  Future<void> _lockIfNeeded() async {
    if (await PinService.hasPin()) {
      state = state.copyWith(isLocked: true);
    }
  }

  void forceLock() {
    state = state.copyWith(isLocked: true);
  }

  void unlock() {
    state = AppLockState(); // Reset everything
    // IMPORTANT: Set lastBackgroundedTime to now so that any delayed 'resumed' 
    // lifecycle events from the OS closing the biometric dialog fall within 
    // the grace period and don't accidentally re-lock the app!
    _lastBackgroundedTime = DateTime.now();
    _startIdleTimer();
  }

  Future<bool> verifyAndUnlock(String pin) async {
    if (state.lockedUntil != null && DateTime.now().isBefore(state.lockedUntil!)) {
      return false; // Still locked out
    }

    final isValid = await PinService.verifyPin(pin);
    if (isValid) {
      unlock();
      return true;
    } else {
      final attempts = state.failedAttempts + 1;
      if (attempts >= 5) {
        final cycles = state.lockoutCycles + 1;
        if (cycles >= 3) {
          // Force logout
          await ref.read(authProvider.notifier).logout();
          unlock();
        } else {
          state = state.copyWith(
            failedAttempts: 0,
            lockoutCycles: cycles,
            lockedUntil: DateTime.now().add(const Duration(seconds: 30)),
          );
        }
      } else {
        state = state.copyWith(failedAttempts: attempts);
      }
      return false;
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  return AppLockNotifier(ref);
});
