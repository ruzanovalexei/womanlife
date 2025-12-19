// lib/models/habit_measurable.dart
// import 'dart:convert';
import '../utils/date_utils.dart';

class HabitMeasurable {
  final int? id;
  final String name;
  final double goal; // Цель
  final String unit; // Единица измерения
  final int frequencyId; // IDFrequencyType
  final String reminderTime; // Время напоминания в формате "HH:MM"
  final DateTime startDate;
  final DateTime? endDate;

  HabitMeasurable({
    this.id,
    required this.name,
    required this.goal,
    required this.unit,
    required this.frequencyId,
    required this.reminderTime,
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'goal': goal,
      'unit': unit,
      'frequencyId': frequencyId,
      'reminderTime': reminderTime,
      'startDate': MyDateUtils.toUtcDateString(startDate),
      'endDate': endDate != null ? MyDateUtils.toUtcDateString(endDate!) : null,
    };
  }

  factory HabitMeasurable.fromMap(Map<String, dynamic> map) {
    return HabitMeasurable(
      id: map['id'],
      name: map['name'],
      goal: map['goal'].toDouble(),
      unit: map['unit'],
      frequencyId: map['frequencyId'],
      reminderTime: map['reminderTime'],
      startDate: MyDateUtils.fromUtcDateString(map['startDate']),
      endDate: map['endDate'] != null ? MyDateUtils.fromUtcDateString(map['endDate']) : null,
    );
  }

  // Проверка, активна ли привычка в конкретный день
  bool isActiveOn(DateTime day) {
    final normalizedDay = MyDateUtils.startOfDayUtc(day);
    final normalizedStartDate = startDate;
    final normalizedEndDate = endDate;

    if (normalizedDay.isBefore(normalizedStartDate)) return false;
    if (normalizedEndDate != null && normalizedDay.isAfter(normalizedEndDate)) return false;

    return true;
  }

  HabitMeasurable copyWith({
    int? id,
    String? name,
    double? goal,
    String? unit,
    int? frequencyId,
    String? reminderTime,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return HabitMeasurable(
      id: id ?? this.id,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      unit: unit ?? this.unit,
      frequencyId: frequencyId ?? this.frequencyId,
      reminderTime: reminderTime ?? this.reminderTime,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitMeasurable &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          goal == other.goal &&
          unit == other.unit &&
          frequencyId == other.frequencyId &&
          reminderTime == other.reminderTime &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ goal.hashCode ^ unit.hashCode ^ 
                     frequencyId.hashCode ^ reminderTime.hashCode ^ 
                     startDate.hashCode ^ endDate.hashCode;
}