import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app_colors.dart';

class AppUtils {
  static void showTopSnackBar(BuildContext context, String message,
      {bool isError = true}) {
    // Translate the error if it's a key
    String displayMessage = message;
    if (message.startsWith('error_') || message.contains('_')) {
      // Check if it's a known translation key or contains underscores which usually indicate keys
      try {
        displayMessage = message.tr();
      } catch (_) {
        displayMessage = message;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayMessage,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
