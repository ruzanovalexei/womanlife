import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> schedulePeriodicNotifications() async {
    await _notifications.periodicallyShow(
      0,
      'Прием лекарств',
      'Время принять лекарство',
      RepeatInterval.everyMinute, // Для тестирования. Замените на hourly
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'periodic_channel',
          'Периодические уведомления',
          channelDescription: 'Напоминания о приеме лекарств',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'periodic_category',
        ),
      ), // Добавлена новая закрывающая скобка для NotificationDetails
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showImmediateNotification() async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Прием лекарств',
      'Текущее время: ${DateTime.now().hour}:${DateTime.now().minute}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'periodic_channel',
          'Периодические уведомления',
          channelDescription: 'Напоминания о приеме лекарств',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'periodic_category',
        ),
      ),
    );
  }
}