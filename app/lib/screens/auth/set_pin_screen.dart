import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../services/pin_service.dart';
import '../../utils/app_colors.dart';
import 'package:flutter/services.dart';
import '../../providers/app_lock_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class SetPinScreen extends ConsumerStatefulWidget {
  const SetPinScreen({super.key});

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmMode = false;
  bool _isError = false;
  bool _isSetupComplete = false;

  @override
  void initState() {
    super.initState();
  }

  void _onNumPressed(String num) {
    if (_isSetupComplete) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isError = false;
      if (!_isConfirmMode) {
        if (_pin.length < 6) _pin += num;
        if (_pin.length == 6) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) setState(() => _isConfirmMode = true);
          });
        }
      } else {
        if (_confirmPin.length < 6) _confirmPin += num;
        if (_confirmPin.length == 6) {
          _verifyAndSave();
        }
      }
    });
  }

  void _onDeletePressed() {
    if (_isSetupComplete) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isError = false;
      if (!_isConfirmMode && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      } else if (_isConfirmMode && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (_isConfirmMode && _confirmPin.isEmpty) {
        // Go back to PIN mode if deleting from empty confirm
        _isConfirmMode = false;
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _verifyAndSave() async {
    if (_pin == _confirmPin) {
      await PinService.setPin(_pin);
      
      // Clear the forced setup flag if it existed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('needs_pin_setup', false);
      
      // Restart the idle timer since we modified lock settings
      ref.read(appLockProvider.notifier).unlock();
      
      setState(() => _isSetupComplete = true);
    } else {
      HapticFeedback.lightImpact();
      setState(() {
        _isError = true;
        _confirmPin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pinsDoNotMatch'.tr()), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _completeSetup() async {
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePin = _isConfirmMode ? _confirmPin : _pin;
    final authState = ref.watch(authProvider);
    final firstName = (authState.user?.name ?? 'User').split(' ').first;
    
    return Scaffold(
      backgroundColor: const Color(0xFF060E2A),
      body: SafeArea(
        child: _isSetupComplete ? _buildWifiSetup() : _buildPinPad(activePin, firstName),
      ),
    );
  }

  Widget _buildWifiSetup() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 80, color: AppColors.success),
          const SizedBox(height: 24),
          const Text(
            'PIN Set Successfully!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _completeSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
              child: Text('finishSetup'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinPad(String activePin, String firstName) {
    return LayoutBuilder(
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
            'Welcome, $firstName 👋',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isConfirmMode ? 'Enter your PIN again' : 'Create 6-digit PIN',
          style: TextStyle(
            fontSize: 15,
            color: _isError ? AppColors.danger : Colors.white70,
          ),
        ),
        const SizedBox(height: 40),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final isFilled = index < activePin.length;
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
        
        const Spacer(),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
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
                  const SizedBox(width: 75), // Spacer
                  _NumBtn('0', () => _onNumPressed('0')),
                  _ActionBtn(Icons.backspace_outlined, _onDeletePressed),
                ],
              ),
            ],
          ),
        ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
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
