//import 'package:flutter/material.dart';

class DateUtils {
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
    final date = DateTime.parse(dateString).toUtc();
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Получает локальную дату без учета времени из любой DateTime.
  static DateTime toLocalDay(DateTime date) {
    final localDate = date.toLocal();
    return DateTime(localDate.year, localDate.month, localDate.day);
  }

  /// Обрезает DateTime до начала дня в UTC.
  static DateTime startOfDayUtc(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Обрезает DateTime до начала дня в локальном времени.
  static DateTime startOfDayLocal(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
