import 'package:flutter/material.dart';

class AppSnackbar {
  static const Duration _successDuration = Duration(seconds: 2);
  static const Duration _errorDuration = Duration(seconds: 4);

  static void showSuccess(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        duration: _successDuration,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: _errorDuration,
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blueGrey.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
