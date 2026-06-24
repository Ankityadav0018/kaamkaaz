import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exceptions/api_exception.dart';
import '../providers/auth_provider.dart';

class ErrorHandler {
  static void showSnackbar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
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
          backgroundColor: Colors.green,
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
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (onRetry != null)
            ElevatedButton(
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
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 12),
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
    if (error == null) return 'An unexpected error occurred. Please try again.';
    
    String msg = '';
    if (error is ApiException) {
      msg = error.message;
    } else {
      msg = error.toString();
    }

    msg = msg.replaceFirst('Exception:', '').trim();

    final lowerMsg = msg.toLowerCase();

    // Network & Timeout
    if (lowerMsg.contains('socketexception') || lowerMsg.contains('connection refused') || lowerMsg.contains('network is unreachable')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }
    if (lowerMsg.contains('timeout')) {
      return 'The request timed out. Please try again later.';
    }

    // Firebase & Auth
    if (lowerMsg.contains('firebase_auth')) {
      if (lowerMsg.contains('invalid-credential') || lowerMsg.contains('wrong-password') || lowerMsg.contains('user-not-found')) {
        return 'Invalid phone number or password.';
      }
      if (lowerMsg.contains('too-many-requests')) {
        return 'Too many attempts. Please try again later.';
      }
      return 'Authentication failed. Please try again.';
    }

    // Generic technical terms
    if (lowerMsg.contains('typeerror') || 
        lowerMsg.contains('nosuchmethoderror') || 
        lowerMsg.contains('rangeerror') || 
        lowerMsg.contains('format_exception') || 
        lowerMsg.contains('unhandled') ||
        lowerMsg.contains('internal server error') ||
        lowerMsg.contains('<html>') ||
        lowerMsg.contains('doctype') ||
        lowerMsg.contains('mongoerror') ||
        lowerMsg.contains('cast to objectid failed') ||
        lowerMsg.contains('null check operator')) {
      return 'We are experiencing a temporary issue. Please try again later.';
    }

    // If it's a completely unreadable raw exception
    if (msg.length > 100 && !msg.contains(' ')) {
      return 'Something went wrong. Please try again.';
    }

    return msg.isEmpty ? 'An error occurred. Please try again.' : msg;
  }
}
