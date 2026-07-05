import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class AdminOtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const AdminOtpScreen({Key? key, required this.phone}) : super(key: key);

  @override
  ConsumerState<AdminOtpScreen> createState() => _AdminOtpScreenState();
}

class _AdminOtpScreenState extends ConsumerState<AdminOtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _isLoading = false;
  String _verificationId = '';

  @override
  void initState() {
    super.initState();
    _triggerOtp();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  Future<void> _triggerOtp() async {
    setState(() => _isLoading = true);
    
    String formattedPhone = widget.phone;
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+91$formattedPhone';
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showSnack(e.message ?? 'SMS Failed', isError: true);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
          _showSnack('OTP sent to ${widget.phone}');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _verifyCode() async {
    final code = _otpCtrl.text.trim();
    if (code.isEmpty || code.length < 6) {
      _showSnack('Enter a valid 6-digit OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showSnack(e.message ?? 'Invalid OTP', isError: true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error verifying code', isError: true);
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        throw Exception('Failed to retrieve Firebase token');
      }

      // Verify token with backend
      final result = await ref.read(authProvider.notifier).adminVerifyOtp(idToken);
      
      if (result['success'] == true) {
        if (!mounted) return;
        _showSnack('Admin verified successfully!', isError: false);
        context.go('/');
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnack(result['message'] ?? 'Verification failed', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Authentication failed: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Security Verification')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.shield, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Enter 2FA Code',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An SMS code was sent to ${widget.phone}.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: _otpCtrl,
                    decoration: const InputDecoration(
                      labelText: '6-digit OTP',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Verify Access'),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _triggerOtp,
                    child: const Text('Resend Code'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
