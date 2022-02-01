import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  Future<void> init() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
      // AndroidInitializationSettings('app_icon');
      AndroidInitializationSettings('@mipmap/ic_launcher');

    final IOSInitializationSettings initializationSettingsIOS =
      IOSInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
        // onDidReceiveLocalNotification: onDidReceiveLocalNotification,
      );

    final InitializationSettings initializationSettings =
      InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: null);

    tz.initializeTimeZones();

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);
  }

  Future selectNotification(String? payload) async {
    // Handle notification tapped logic here
    print("tapped! $payload");
  }

  Future<void> scheduleNotification(int notificationId, String title, String? body, String payload, DateTime date) async {
    const CHANNEL_ID = "frend";
    const CHANNEL_NAME = "frend_channel";

    await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId, title, body,
        tz.TZDateTime.from(date, tz.local),
        // tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1)),
        const NotificationDetails(android: AndroidNotificationDetails(CHANNEL_ID, CHANNEL_NAME)),
        payload: payload,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime);
  }
}