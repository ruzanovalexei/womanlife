// lib/models/planner_task.dart

import 'package:flutter/material.dart';
import '../utils/date_utils.dart';

class PlannerTask {
  final int? id;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String title;
  final String? description;

  PlannerTask({
    this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': MyDateUtils.toUtcDateString(date),
      'startTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'title': title,
      'description': description,
    };
  }

  factory PlannerTask.fromMap(Map<String, dynamic> map) {
    return PlannerTask(
      id: map['id'],
      date: MyDateUtils.fromUtcDateString(map['date']),
      startTime: _parseTime(map['startTime']),
      endTime: _parseTime(map['endTime']),
      title: map['title'],
      description: map['description'],
    );
  }

  static TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
