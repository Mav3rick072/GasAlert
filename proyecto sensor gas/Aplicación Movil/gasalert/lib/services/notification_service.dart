import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _noti =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _noti.initialize(initSettings);
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'alert_channel',
          'Alertas Importantes',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notiDetails = NotificationDetails(
      android: androidDetails,
    );

    await _noti.show(0, title, body, notiDetails);
  }
}
