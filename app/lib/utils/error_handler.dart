import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exceptions/api_exception.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class ErrorHandler {
  static void showSnackbar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
          backgroundColor: AppColors.textDark, // Utilitarian dark flat style
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static void showSuccessSnackbar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static void showDialogMsg(BuildContext context, String title, String message, {VoidCallback? onRetry}) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          if (onRetry != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safetyOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onRetry();
              },
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  static Widget showInlineError(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textMedium, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static void handleAuthError(BuildContext context, WidgetRef ref, String errorCode) {
    if (errorCode == 'AUTH_EXPIRED' || errorCode == 'AUTH_INVALID') {
      showDialogMsg(
        context,
        'Session Expired',
        'Your session has expired. Please log in again.',
        onRetry: () {
          ref.read(authProvider.notifier).logout();
          context.go('/login');
        },
      );
    }
  }

  static String getMessage(dynamic error) {
    if (error == null) return "Couldn't load this right now. Try again.";
    
    String msg = '';
    if (error is ApiException) {
      msg = error.message;
    } else {
      msg = error.toString();
    }

    final lowerMsg = msg.toLowerCase();

    // Specific user-facing validation/auth messages (non-technical)
    if (lowerMsg.contains('invalid') || 
        lowerMsg.contains('wrong') || 
        lowerMsg.contains('password') || 
        lowerMsg.contains('credential') || 
        lowerMsg.contains('not found') ||
        lowerMsg.contains('incorrect') ||
        lowerMsg.contains('does not exist') ||
        lowerMsg.contains('authentication failed')) {
      
      if (!lowerMsg.contains('socket') && !lowerMsg.contains('timeout')) {
        String cleanMsg = msg.replaceFirst('Exception: ', '').trim();
        // Fallback friendly message if it's too technical
        if (cleanMsg.toLowerCase().contains('auth')) return 'Invalid phone number or password.';
        return cleanMsg;
      }
    }

    if (lowerMsg.contains('too-many-requests')) {
      return "Too many attempts. Please try again later.";
    }

    // Payment-specific failure message (from Section 6 rule)
    if (lowerMsg.contains('razorpay') || lowerMsg.contains('payment failed') || lowerMsg.contains('gateway')) {
      return "Payment didn't go through. Try again or use a different method.";
    }

    // Never return raw tech jargon, network errors, timeouts, or stack traces
    // Just return the standard fallback state
    return "Couldn't load this right now. Try again.";
  }
}
