// This screen has been disabled — OTP verification via phone has been removed.
// The router no longer registers this screen.
// Kept as a stub to avoid dangling file issues.
import 'package:flutter/material.dart';

class OtpScreen extends StatelessWidget {
  final String phoneNumber;
  final String verificationId;
  final String? role;
  final String? name;

  const OtpScreen({
    required this.phoneNumber,
    required this.verificationId,
    this.role,
    this.name,
    super.key,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
