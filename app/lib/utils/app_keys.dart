import 'package:flutter/material.dart';

class AppKeys {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static BuildContext? get context => rootNavigatorKey.currentContext;

  static void showSnackBar(String message, {bool isError = false}) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
