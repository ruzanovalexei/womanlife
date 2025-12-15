// lib/models/habit_measurable_record.dart
import '../utils/date_utils.dart';

class HabitMeasurableRecord {
  final int? id;
  final int habitId; // ID HabitMeasurable
  final bool isCompleted; // Отметка о выполнении
  final double? actualValue; // Фактическое значение
  final DateTime executionDate; // Дата дня выполнения
  final DateTime createdAt; // Дата и время отметки

  HabitMeasurableRecord({
    this.id,
    required this.habitId,
    required this.isCompleted,
    this.actualValue,
    required this.executionDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'isCompleted': isCompleted ? 1 : 0,
      'actualValue': actualValue,
      'executionDate': MyDateUtils.toUtcDateString(executionDate),
      'createdAt': MyDateUtils.toUtcDateTimeString(createdAt),
    };
  }

  factory HabitMeasurableRecord.fromMap(Map<String, dynamic> map) {
    return HabitMeasurableRecord(
      id: map['id'],
      habitId: map['habitId'],
      isCompleted: map['isCompleted'] == 1,
      actualValue: map['actualValue']?.toDouble(),
      executionDate: MyDateUtils.fromUtcDateString(map['executionDate']),
      createdAt: MyDateUtils.fromUtcDateTimeString(map['createdAt']),
    );
  }

  HabitMeasurableRecord copyWith({
    int? id,
    int? habitId,
    bool? isCompleted,
    double? actualValue,
    DateTime? executionDate,
    DateTime? createdAt,
  }) {
    return HabitMeasurableRecord(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      isCompleted: isCompleted ?? this.isCompleted,
      actualValue: actualValue ?? this.actualValue,
      executionDate: executionDate ?? this.executionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitMeasurableRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          habitId == other.habitId &&
          isCompleted == other.isCompleted &&
          actualValue == other.actualValue &&
          executionDate == other.executionDate &&
          createdAt == other.createdAt;

  @override
  int get hashCode => id.hashCode ^ habitId.hashCode ^ isCompleted.hashCode ^ 
                     actualValue.hashCode ^ executionDate.hashCode ^ createdAt.hashCode;
}