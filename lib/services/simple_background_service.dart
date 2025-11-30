import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Инициализируем уведомления
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    final FlutterLocalNotificationsPlugin notifications = 
        FlutterLocalNotificationsPlugin();
    
    await notifications.initialize(settings);
    
    // Показываем уведомление
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medication_channel',
      'Напоминания о лекарствах',
      channelDescription: 'Уведомления о приеме лекарств',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );
    
    // await notifications.show(
    //   DateTime.now().millisecondsSinceEpoch.remainder(100000),
    //   'Прием лекарств',
    //   'Текущее время: ${DateTime.now().hour}:${DateTime.now().minute}',
    //   platformChannelSpecifics,
    // );
        await notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Автоматический Прием лекарств',
      'Текущее время: ${DateTime.now().hour}:${DateTime.now().minute}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'periodic_channel',
          'Периодические уведомления',
          channelDescription: 'Напоминания о приеме лекарств',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );   
    return Future.value(true);
  });
}

class SimpleBackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Для отладки установите true
    );
    
    await Workmanager().registerPeriodicTask(
      "simple-medication-reminder",
      "simpleMedicationReminder",
      frequency: const Duration(minutes: 1),
    );
  }
}