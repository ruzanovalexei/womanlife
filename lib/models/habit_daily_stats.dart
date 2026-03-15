import '../utils/date_utils.dart';

class HabitDailyStats {
  final DateTime date;
  final double plannedValue; // Для execution = 1, для measurable = goal
  final double actualValue; // Для execution = 1 или 0, для measurable = actualValue
  final bool isMeasurable; // Тип привычки

  HabitDailyStats({
    required this.date,
    required this.plannedValue,
    required this.actualValue,
    required this.isMeasurable,
  });

  /// Полностью выполнено (для execution) или достигнута цель (для measurable)
  bool get isFullyCompleted {
    if (isMeasurable) {
      return actualValue >= plannedValue;
    }
    return actualValue >= 1;
  }

  /// Частично выполнено (только для measurable)
  bool get isPartiallyCompleted {
    if (isMeasurable) {
      return actualValue > 0 && actualValue < plannedValue;
    }
    return false;
  }

  /// Не выполнено
  bool get isNotCompleted {
    if (plannedValue <= 0) return false;
    return actualValue == 0;
  }

  /// Процент выполнения
  double get completionPercent {
    if (plannedValue <= 0) return 0;
    return ((actualValue / plannedValue) * 100).clamp(0, 100);
  }

  /// Форматированная дата
  String get formattedDate => MyDateUtils.toUtcDateString(date);

  @override
  String toString() {
    return 'HabitDailyStats(date: $date, planned: $plannedValue, actual: $actualValue, measurable: $isMeasurable)';
  }
}
