// lib/models/habit_execution.dart
// import 'dart:convert';
import '../utils/date_utils.dart';

class HabitExecution {
  final int? id;
  final String name;
  final int frequencyId; // IDFrequencyType
  final String reminderTime; // Время напоминания в формате "HH:MM"
  final DateTime startDate;
  final DateTime? endDate;

  HabitExecution({
    this.id,
    required this.name,
    required this.frequencyId,
    required this.reminderTime,
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'frequencyId': frequencyId,
      'reminderTime': reminderTime,
      'startDate': MyDateUtils.toUtcDateString(startDate),
      'endDate': endDate != null ? MyDateUtils.toUtcDateString(endDate!) : null,
    };
  }

  factory HabitExecution.fromMap(Map<String, dynamic> map) {
    return HabitExecution(
      id: map['id'],
      name: map['name'],
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

  HabitExecution copyWith({
    int? id,
    String? name,
    int? frequencyId,
    String? reminderTime,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return HabitExecution(
      id: id ?? this.id,
      name: name ?? this.name,
      frequencyId: frequencyId ?? this.frequencyId,
      reminderTime: reminderTime ?? this.reminderTime,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitExecution &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          frequencyId == other.frequencyId &&
          reminderTime == other.reminderTime &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ frequencyId.hashCode ^ 
                     reminderTime.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}