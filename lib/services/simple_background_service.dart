import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/utils/background_localizations.dart';
import 'package:period_tracker/models/habit_execution.dart';
import 'package:period_tracker/models/habit_measurable.dart';
import 'package:period_tracker/models/frequency_type.dart';
import 'package:period_tracker/utils/date_utils.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final DatabaseHelper databaseHelper = DatabaseHelper(); // Инициализация DatabaseHelper
    
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
    
    // Логика проверки и отображения уведомления
    final now = DateTime.now();
    final fifteenMinutesLater = now.add(const Duration(minutes: 15));

    // Обрабатываем задачи в зависимости от типа
    if (task == "simpleMedicationReminder") {
      await _processMedicationsNotification(databaseHelper, notifications, now, fifteenMinutesLater);
    } else if (task == "simpleHabitsReminder") {
      await _processHabitsNotification(databaseHelper, notifications, now, fifteenMinutesLater);
    }

    return Future.value(true);
  });
}

// Функция для обработки уведомлений о лекарствах
Future<void> _processMedicationsNotification(
  DatabaseHelper databaseHelper,
  FlutterLocalNotificationsPlugin notifications,
  DateTime now,
  DateTime fifteenMinutesLater
) async {
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

  // Получаем все активные лекарства
  final allMedications = await databaseHelper.getAllMedications();

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

        // Проверяем, попадает ли запланированное время приема в ближайшие 15 минут
        if (medicationScheduledTime.isAfter(now) &&
            medicationScheduledTime.isBefore(fifteenMinutesLater)) {
          upcomingMedications.add(
            "${medication.name} в ${medicationTime.hour.toString().padLeft(2, '0')}:${medicationTime.minute.toString().padLeft(2, '0')}",
          );
        }
      }
    }
  }

  if (upcomingMedications.isNotEmpty) {
    final title = BackgroundLocalizations.getNotificationTitle();
    final body = "${BackgroundLocalizations.getNotificationBody()}\n${upcomingMedications.join('\n')}";

    await notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), 
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
    
// Функция для обработки уведомлений о привычках
Future<void> _processHabitsNotification(
  DatabaseHelper databaseHelper,
  FlutterLocalNotificationsPlugin notifications,
  DateTime now,
  DateTime fifteenMinutesLater
) async {
  // Получаем все активные привычки
  final allExecutionHabits = await databaseHelper.getAllHabitExecutions();
  final allMeasurableHabits = await databaseHelper.getAllHabitMeasurables();
  final allFrequencyTypes = await databaseHelper.getAllFrequencyTypes();

  // Создаем карту FrequencyType
  final frequencyTypesMap = <int, FrequencyType>{};
  for (final frequencyType in allFrequencyTypes) {
    if (frequencyType.id != null) {
      frequencyTypesMap[frequencyType.id!] = frequencyType;
    }
  }

  List<String> upcomingHabits = [];

  // Проверяем привычки типа выполнение
  for (var habit in allExecutionHabits) {
    // Проверяем, активна ли привычка сегодня
    if (_shouldExecuteHabitOnDate(habit, now, frequencyTypesMap)) {
      // Проверяем, установлено ли время напоминания
      if (habit.reminderTime.isNotEmpty) {
        final timeParts = habit.reminderTime.split(':');
        if (timeParts.length == 2) {
          final habitScheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          // Проверяем, попадает ли запланированное время в ближайшие 15 минут
          if (habitScheduledTime.isAfter(now) &&
              habitScheduledTime.isBefore(fifteenMinutesLater)) {
            upcomingHabits.add(
              "${habit.name} в ${habit.reminderTime}",
            );
          }
        }
      }
    }
  }

  // Проверяем измеримые привычки
  for (var habit in allMeasurableHabits) {
    // Проверяем, активна ли привычка сегодня
    if (_shouldExecuteMeasurableHabitOnDate(habit, now, frequencyTypesMap)) {
      // Проверяем, установлено ли время напоминания
      if (habit.reminderTime.isNotEmpty) {
        final timeParts = habit.reminderTime.split(':');
        if (timeParts.length == 2) {
          final habitScheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          // Проверяем, попадает ли запланированное время в ближайшие 15 минут
          if (habitScheduledTime.isAfter(now) &&
              habitScheduledTime.isBefore(fifteenMinutesLater)) {
            upcomingHabits.add(
              "${habit.name} в ${habit.reminderTime}",
            );
          }
        }
      }
    }
  }

  // Показываем уведомление о привычках, если есть запланированные
  if (upcomingHabits.isNotEmpty) {
    const AndroidNotificationDetails habitsAndroidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'habits_channel',
      'Напоминания о привычках',
      channelDescription: 'Уведомления о выполнении привычек',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails habitsPlatformChannelSpecifics =
        NotificationDetails(
      android: habitsAndroidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    final habitsTitle = 'Напоминание о привычках';
    final habitsBody = "Время выполнить привычки:\n${upcomingHabits.join('\n')}";

    await notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000) + 1, // Уникальный ID
      habitsTitle,
      habitsBody,
      habitsPlatformChannelSpecifics,
    );
  }
}

// Функция проверки, должна ли привычка типа выполнение выполняться в конкретный день
bool _shouldExecuteHabitOnDate(HabitExecution habit, DateTime date, Map<int, FrequencyType> frequencyTypesMap) {
  final frequencyType = frequencyTypesMap[habit.frequencyId];
  if (frequencyType == null) return false;

  // Проверяем, активна ли привычка в этот день по датам начала/окончания
  if (!habit.isActiveOn(date)) return false;

  final dayOfWeek = date.weekday; // 1 = понедельник, 7 = воскресенье
  final daysFromStart = date.difference(habit.startDate).inDays;

  switch (frequencyType.type) {
    case 1: // Каждый день
      return true;
    case 2: // Каждый X день
      final interval = frequencyType.intervalValue ?? 2;
      return daysFromStart >= 0 && daysFromStart % interval == 0;
    case 3: // Дни недели
      final selectedDays = frequencyType.selectedDaysOfWeek ?? [];
      return selectedDays.contains(dayOfWeek);
    case 4: // X раз в неделю
      final timesPerWeek = frequencyType.intervalValue ?? 3;
      // Простая логика: если это один из первых дней недели с учетом количества раз
      final weekStart = _getWeekStart(date);
      final daysFromWeekStart = date.difference(weekStart).inDays;
      return daysFromWeekStart < timesPerWeek;
    default:
      return false;
  }
}

// Функция проверки, должна ли измеримая привычка выполняться в конкретный день
bool _shouldExecuteMeasurableHabitOnDate(HabitMeasurable habit, DateTime date, Map<int, FrequencyType> frequencyTypesMap) {
  final frequencyType = frequencyTypesMap[habit.frequencyId];
  if (frequencyType == null) return false;

  // Проверяем, активна ли привычка в этот день по датам начала/окончания
  if (!habit.isActiveOn(date)) return false;

  final dayOfWeek = date.weekday; // 1 = понедельник, 7 = воскресенье
  final daysFromStart = date.difference(habit.startDate).inDays;

  switch (frequencyType.type) {
    case 1: // Каждый день
      return true;
    case 2: // Каждый X день
      final interval = frequencyType.intervalValue ?? 2;
      return daysFromStart >= 0 && daysFromStart % interval == 0;
    case 3: // Дни недели
      final selectedDays = frequencyType.selectedDaysOfWeek ?? [];
      return selectedDays.contains(dayOfWeek);
    case 4: // X раз в неделю
      final timesPerWeek = frequencyType.intervalValue ?? 3;
      // Простая логика: если это один из первых дней недели с учетом количества раз
      final weekStart = _getWeekStart(date);
      final daysFromWeekStart = date.difference(weekStart).inDays;
      return daysFromWeekStart < timesPerWeek;
    default:
      return false;
  }
}

// Получить начало недели (понедельник)
DateTime _getWeekStart(DateTime date) {
  final dayOfWeek = date.weekday;
  return date.subtract(Duration(days: dayOfWeek - 1));
}

class SimpleBackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      //isInDebugMode: true, // Для отладки установите true
    );
    
    // Задача для уведомлений о лекарствах
    await Workmanager().registerPeriodicTask(
      "simple-medication-reminder",
      "simpleMedicationReminder",
      frequency: const Duration(minutes: 15),
    );
    
    // Задача для уведомлений о привычках
    await Workmanager().registerPeriodicTask(
      "simple-habits-reminder",
      "simpleHabitsReminder", 
      frequency: const Duration(minutes: 15),
    );
  }
}