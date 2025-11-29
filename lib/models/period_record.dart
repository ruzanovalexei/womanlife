import '../utils/period_calculator.dart';

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
      'startDate': _formatDate(startDate),
      'endDate': endDate != null ? _formatDate(endDate!) : null,
    };
  }

  factory PeriodRecord.fromMap(Map<String, dynamic> map) {
    return PeriodRecord(
      id: map['id'],
      startDate: _parseDate(map['startDate']),
      endDate: map['endDate'] != null ? _parseDate(map['endDate']) : null,
    );
  }

  static DateTime _parseDate(String dateString) {
    // Парсим строку даты и возвращаем DateTime без информации о времени
    final date = DateTime.parse(dateString);
    return DateTime(date.year, date.month, date.day);
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Получить все даты в периоде
  List<DateTime> getAllPeriodDates() {
    List<DateTime> dates = [];
    DateTime end = endDate ?? PeriodCalculator.getToday();
    
    DateTime current = startDate;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }

  // Проверить, активен ли период (не завершен)
  bool get isActive => endDate == null;

  // Проверить, является ли дата частью этого периода
  bool containsDate(DateTime date) {
    DateTime end = endDate ?? PeriodCalculator.getToday();
    return (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
           (date.isBefore(end) || date.isAtSameMomentAs(end));
  }

  // Получить продолжительность периода в днях
  int get durationInDays {
    DateTime end = endDate ?? PeriodCalculator.getToday();
    return end.difference(startDate).inDays + 1;
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