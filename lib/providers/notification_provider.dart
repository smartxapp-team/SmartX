import 'package:flutter/material.dart';
import 'dart:collection';

// A simple data model for our notifications
class NotificationModel {
  final int id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationProvider with ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  int _nextId = 0;

  // Use an UnmodifiableListView to prevent direct modification of the list outside the provider
  UnmodifiableListView<NotificationModel> get notifications => UnmodifiableListView(_notifications.reversed);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(String title, String body) {
    _notifications.add(NotificationModel(
      id: _nextId++,
      title: title,
      body: body,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void removeNotification(int id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void markAllAsRead() {
    bool changed = false;
    for (var notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }
}
