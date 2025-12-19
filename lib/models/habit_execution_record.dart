// lib/models/habit_execution_record.dart
import '../utils/date_utils.dart';

class HabitExecutionRecord {
  final int? id;
  final int habitId; // ID HabitExecution
  final bool isCompleted; // Отметка о выполнении
  final DateTime executionDate; // Дата дня выполнения
  final DateTime createdAt; // Дата и время отметки

  HabitExecutionRecord({
    this.id,
    required this.habitId,
    required this.isCompleted,
    required this.executionDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'isCompleted': isCompleted ? 1 : 0,
      'executionDate': MyDateUtils.toUtcDateString(executionDate),
      'createdAt': MyDateUtils.toUtcDateTimeString(createdAt),
    };
  }

  factory HabitExecutionRecord.fromMap(Map<String, dynamic> map) {
    return HabitExecutionRecord(
      id: map['id'],
      habitId: map['habitId'],
      isCompleted: map['isCompleted'] == 1,
      executionDate: MyDateUtils.fromUtcDateString(map['executionDate']),
      createdAt: MyDateUtils.fromUtcDateTimeString(map['createdAt']),
    );
  }

  HabitExecutionRecord copyWith({
    int? id,
    int? habitId,
    bool? isCompleted,
    DateTime? executionDate,
    DateTime? createdAt,
  }) {
    return HabitExecutionRecord(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      isCompleted: isCompleted ?? this.isCompleted,
      executionDate: executionDate ?? this.executionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitExecutionRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          habitId == other.habitId &&
          isCompleted == other.isCompleted &&
          executionDate == other.executionDate &&
          createdAt == other.createdAt;

  @override
  int get hashCode => id.hashCode ^ habitId.hashCode ^ isCompleted.hashCode ^ 
                     executionDate.hashCode ^ createdAt.hashCode;
}