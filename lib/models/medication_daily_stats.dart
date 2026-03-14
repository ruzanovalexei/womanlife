// lib/models/medication_daily_stats.dart

class MedicationDailyStats {
  final DateTime date;
  final int plannedCount; // Количество запланированных приемов за день
  final int takenCount; // Количество фактически принятых лекарств за день

  MedicationDailyStats({
    required this.date,
    required this.plannedCount,
    required this.takenCount,
  });

  /// Процент выполнения (от 0 до 100)
  double get adherencePercent {
    if (plannedCount == 0) return 0;
    return (takenCount / plannedCount * 100).clamp(0, 100);
  }

  /// День полностью выполнен
  bool get isFullyCompleted => takenCount >= plannedCount && plannedCount > 0;

  /// День частично выполнен
  bool get isPartiallyCompleted => takenCount > 0 && takenCount < plannedCount;

  /// День не выполнен
  bool get isNotCompleted => takenCount == 0 && plannedCount > 0;

  @override
  String toString() {
    return 'MedicationDailyStats(date: $date, planned: $plannedCount, taken: $takenCount)';
  }
}
