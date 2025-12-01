//import 'package:flutter/material.dart';

class MyDateUtils {
  /// Возвращает текущую дату в UTC без учета времени.
  static DateTime getUtcToday() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  /// Форматирует DateTime в строку 'YYYY-MM-DD' в UTC.
  static String toUtcDateString(DateTime date) {
    final utcDate = date.toUtc();
    return '${utcDate.year}-${utcDate.month.toString().padLeft(2, '0')}-${utcDate.day.toString().padLeft(2, '0')}';
  }

  /// Парсит строку 'YYYY-MM-DD' и возвращает DateTime в UTC без учета времени.
  static DateTime fromUtcDateString(String dateString) {
    // Разбираем строку вручную, чтобы явно создать UTC DateTime
    final parts = dateString.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return DateTime.utc(year, month, day);
  }

  /// Получает локальную дату без учета времени из любой DateTime.
  static DateTime toLocalDay(DateTime date) {
    final localDate = date.toLocal();
    return DateTime(localDate.year, localDate.month, localDate.day);
  }

  /// Преобразует локальную дату в UTC дату, представляющую тот же день в UTC, обнуляя время.
  static DateTime fromLocalDayToUtcDay(DateTime localDate) {
    return DateTime.utc(localDate.year, localDate.month, localDate.day);
  }

  /// Обрезает DateTime до начала дня в UTC.
  static DateTime startOfDayUtc(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Обрезает DateTime до начала дня в локальном времени.
  static DateTime startOfDayLocal(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Форматирует DateTime в строку 'YYYY-MM-DD HH:MM:SS.mmm' в UTC.
  static String toUtcDateTimeString(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Парсит строку 'YYYY-MM-DD HH:MM:SS.mmm' и возвращает DateTime в UTC.
  static DateTime fromUtcDateTimeString(String dateTimeString) {
    return DateTime.parse(dateTimeString).toUtc();
  }
}
