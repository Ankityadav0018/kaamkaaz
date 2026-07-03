import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class AdminPhoneSetupScreen extends ConsumerStatefulWidget {
  const AdminPhoneSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminPhoneSetupScreen> createState() => _AdminPhoneSetupScreenState();
}

class _AdminPhoneSetupScreenState extends ConsumerState<AdminPhoneSetupScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _codeSent = false;
  String _verificationId = '';

  @override
  void dispose() {
    _phoneCtrl.dispose();
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

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showSnack('Enter a valid phone number', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    String formattedPhone = phone;
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+91$formattedPhone'; // default to India
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
         // Auto-resolution (rare on iOS, common on Android)
         await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        _showSnack(e.message ?? 'Verification failed', isError: true);
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _isLoading = false;
        });
        _showSnack('OTP sent via SMS');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyCode() async {
    final code = _otpCtrl.text.trim();
    if (code.isEmpty || code.length < 6) {
      _showSnack('Enter the 6-digit OTP', isError: true);
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
        throw Exception('Failed to get Firebase token');
      }

      // Send to our backend to setup phone
      final result = await ref.read(authProvider.notifier).adminSetupPhone(idToken);
      
      if (result['success'] == true) {
        if (!mounted) return;
        _showSnack('2FA Setup Complete!');
        context.go('/home'); // Auth flow will route correctly
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnack(result['message'] ?? 'Setup failed', isError: true);
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
      appBar: AppBar(title: const Text('Setup Admin 2FA')),
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
                  const Icon(Icons.security, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Setup Two-Factor Authentication',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Protect your admin account by linking your phone number.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  if (!_codeSent) ...[
                    TextField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixText: '+91 ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendCode,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Send OTP'),
                    ),
                  ] else ...[
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
                          : const Text('Verify & Complete Setup'),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () => setState(() => _codeSent = false),
                      child: const Text('Change Phone Number'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
