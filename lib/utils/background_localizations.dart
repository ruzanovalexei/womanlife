// lib/utils/background_localizations.dart
import 'dart:io';

class BackgroundLocalizations {
  static const Map<String, Map<String, String>> _strings = {
    'ru': {
      'notificationChannelName': 'Напоминания о лекарствах',
      'notificationChannelDescription': 'Уведомления о приеме лекарств',
      'notificationTitle': 'Скоро принимать лекарства!',
      'notificationBody': 'Не забудьте принять:',
      'taskName': 'simpleMedicationReminder',
    },
    'en': {
      'notificationChannelName': 'Medication Reminders',
      'notificationChannelDescription': 'Medication intake notifications',
      'notificationTitle': 'Time to take medications!',
      'notificationBody': "Don't forget to take:",
      'taskName': 'simpleMedicationReminder',
    },
  };

  static String getNotificationChannelName() {
    final locale = Platform.localeName.startsWith('ru') ? 'ru' : 'en';
    return _strings[locale]!['notificationChannelName']!;
  }

  static String getNotificationChannelDescription() {
    final locale = Platform.localeName.startsWith('ru') ? 'ru' : 'en';
    return _strings[locale]!['notificationChannelDescription']!;
  }

  static String getNotificationTitle() {
    final locale = Platform.localeName.startsWith('ru') ? 'ru' : 'en';
    return _strings[locale]!['notificationTitle']!;
  }

  static String getNotificationBody() {
    final locale = Platform.localeName.startsWith('ru') ? 'ru' : 'en';
    return _strings[locale]!['notificationBody']!;
  }

  static String getTaskName() {
    final locale = Platform.localeName.startsWith('ru') ? 'ru' : 'en';
    return _strings[locale]!['taskName']!;
  }
}