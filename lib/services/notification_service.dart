import 'package:flutter/material.dart';

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showFloatingNotification(String title, String body) {
    final SnackBar snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(body),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    messengerKey.currentState?.showSnackBar(snackBar);
  }
}
