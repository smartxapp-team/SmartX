import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: notificationProvider.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 60, color: theme.textTheme.bodyMedium?.color),
                      const SizedBox(height: 16),
                      Text('No new notifications', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 80), // Add padding for FAB
                  itemCount: notificationProvider.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationProvider.notifications[index];
                    return Dismissible(
                      key: Key(notification.id.toString()),
                      direction: DismissDirection.startToEnd, // Swipe from left to right
                      onDismissed: (direction) {
                        notificationProvider.removeNotification(notification.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('"${notification.title}" dismissed.')),
                        );
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      child: Card(
                        elevation: 0,
                        color: theme.colorScheme.surface.withOpacity(0.7),
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        child: ListTile(
                          leading: Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary, size: 28),
                          title: Text(notification.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification.body, style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(notification.timestamp),
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: notificationProvider.notifications.isEmpty
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    notificationProvider.clearAllNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All notifications cleared.')),
                    );
                  },
                  backgroundColor: theme.colorScheme.error,
                  child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                  tooltip: 'Clear All Notifications',
                ),
        );
      },
    );
  }
}
