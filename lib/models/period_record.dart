import '../utils/period_calculator.dart';
import '../utils/date_utils.dart'; // Добавляем импорт

class PeriodRecord {
  final int? id;
  final DateTime startDate;
  final DateTime? endDate;

  const PeriodRecord({
    this.id,
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': DateUtils.toUtcDateString(startDate), // Используем toUtcDateString
      'endDate': endDate != null ? DateUtils.toUtcDateString(endDate!) : null, // Используем toUtcDateString
    };
  }

  factory PeriodRecord.fromMap(Map<String, dynamic> map) {
    return PeriodRecord(
      id: map['id'],
      startDate: DateUtils.fromUtcDateString(map['startDate']), // Используем fromUtcDateString
      endDate: map['endDate'] != null ? DateUtils.fromUtcDateString(map['endDate']) : null, // Используем fromUtcDateString
    );
  }

  // Получить все даты в периоде
  List<DateTime> getAllPeriodDates() {
    List<DateTime> dates = [];
    DateTime end = endDate ?? DateUtils.getUtcToday(); // Используем getUtcToday

    // Убедимся, что обе даты обрезаны до начала дня UTC для корректного сравнения
    DateTime current = DateUtils.startOfDayUtc(startDate);
    DateTime actualEnd = DateUtils.startOfDayUtc(end);

    while (current.isBefore(actualEnd) || current.isAtSameMomentAs(actualEnd)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }

  // Проверить, активен ли период (не завершен)
  bool get isActive => endDate == null;

  // Проверить, является ли дата частью этого периода
  bool containsDate(DateTime date) {
    DateTime end = endDate ?? DateUtils.getUtcToday();
    // Нормализуем все даты до начала дня UTC для корректного сравнения
    final normalizedDate = DateUtils.startOfDayUtc(date);
    final normalizedStartDate = DateUtils.startOfDayUtc(startDate);
    final normalizedEndDate = DateUtils.startOfDayUtc(end);

    return (normalizedDate.isAfter(normalizedStartDate) || normalizedDate.isAtSameMomentAs(normalizedStartDate)) &&
           (normalizedDate.isBefore(normalizedEndDate) || normalizedDate.isAtSameMomentAs(normalizedEndDate));
  }

  // Получить продолжительность периода в днях
  int get durationInDays {
    DateTime end = endDate ?? DateUtils.getUtcToday();
    // Все даты уже UTC и без времени
    final normalizedStartDate = DateUtils.startOfDayUtc(startDate);
    final normalizedEndDate = DateUtils.startOfDayUtc(end);
    return normalizedEndDate.difference(normalizedStartDate).inDays + 1;
  }

  PeriodRecord copyWith({
    int? id,
    DateTime? startDate,
    DateTime? endDate,
    bool setEndDate = false,
  }) {
    return PeriodRecord(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: setEndDate ? endDate : (endDate ?? this.endDate),
    );
  }

  @override
  String toString() {
    return 'PeriodRecord{id: $id, startDate: $startDate, endDate: $endDate, isActive: $isActive}';
  }
}