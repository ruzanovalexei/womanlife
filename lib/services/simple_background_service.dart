import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:period_tracker/database/database_helper.dart';
//import 'package:period_tracker/models/medication.dart';
//import 'package:period_tracker/models/medication_time.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final DatabaseHelper _databaseHelper = DatabaseHelper(); // Инициализация DatabaseHelper

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
    
    // Логика проверки и отображения уведомления
    final now = DateTime.now();
    final oneHourLater = now.add(const Duration(hours: 1));

    // Получаем все активные лекарства
    final allMedications = await _databaseHelper.getAllMedications();

    List<String> upcomingMedications = [];

    for (var medication in allMedications) {
      // Проверяем, активно ли лекарство сегодня
      if (medication.isActiveOn(now)) {
        for (var medicationTime in medication.times) {
          final medicationScheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            medicationTime.hour,
            medicationTime.minute,
          );

          // Проверяем, попадает ли запланированное время приема в ближайший час
          if (medicationScheduledTime.isAfter(now) &&
              medicationScheduledTime.isBefore(oneHourLater)) {
            upcomingMedications.add(
              "${medication.name} в ${medicationTime.hour.toString().padLeft(2, '0')}:${medicationTime.minute.toString().padLeft(2, '0')}",
            );
          }
        }
      }
    }

    if (upcomingMedications.isNotEmpty) {
      final title = "Скоро принимать лекарства!";
      final body = "Не забудьте принять:\n${upcomingMedications.join('\n')}";

      await notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000), 
        title,
        body,
        platformChannelSpecifics,
      );
    }
    return Future.value(true);
  });
}

class SimpleBackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      //isInDebugMode: true, // Для отладки установите true
    );
    
    await Workmanager().registerPeriodicTask(
      "simple-medication-reminder",
      "simpleMedicationReminder",
      frequency: const Duration(minutes: 15),
    );
  }
}