import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

const deadlineTaskName = "deadlineCheckTask_Final_WithPerms";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      final token = prefs.getString('token');
      final apiUrl = prefs.getString('apiUrl');

      if (username != null && token != null && apiUrl != null) {
        final apiService = ApiService(apiUrl: apiUrl, username: username, token: token);
        final deadlines = await apiService.fetchAllDeadlines();
        final deadlineList = deadlines['deadlines'] as List<dynamic>? ?? [];
        if (deadlineList.isNotEmpty) {
          final topDeadline = deadlineList.first as Map<String, dynamic>;
          await _showDeadlineNotification(deadlineList.length, topDeadline);
        }
      } else {
        // Silently fail if no credentials, no need to spam user
      }
      return Future.value(true);
    } catch (e) {
      // Silently fail in background
      return Future.value(false);
    }
  });
}

Future<void> _showDeadlineNotification(int deadlineCount, Map<String, dynamic> topDeadline) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final subject = topDeadline['course_name'] ?? 'N/A';
  final weekString = topDeadline['week'] as String? ?? 'N/A';
  final date = topDeadline['due_date_str'] ?? 'N/A';

  final title = 'Unsubmitted Deadlines ($deadlineCount)';
  final body = '$subject - $weekString';
  final subtext = 'Upload by: $date';

  final styleInformation = BigTextStyleInformation(
    '''$body<br><i>$subtext</i>''',
    htmlFormatBigText: true,
    contentTitle: title,
    htmlFormatContentTitle: true,
  );

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'deadline_channel_reminders_final', // New channel
    'Deadline Reminders',
    channelDescription: 'Standard reminders for upcoming lab deadlines.',
    importance: Importance.defaultImportance, 
    priority: Priority.defaultPriority,
    styleInformation: styleInformation);
  final platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics);
}

Future<void> initializeBackgroundService() async {
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await Workmanager().cancelAll();

  final now = DateTime.now();
  var scheduledTime = DateTime(now.year, now.month, now.day, 13, 06);

  if (now.isAfter(scheduledTime)) {
    scheduledTime = scheduledTime.add(const Duration(days: 1));
  }

  final initialDelay = scheduledTime.difference(now);

  await Workmanager().registerOneOffTask(
    "smartx_deadline_final_1305",
    deadlineTaskName,
    initialDelay: initialDelay,
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
