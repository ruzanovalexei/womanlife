// lib/models/medication_taken_record.dart
import 'package:flutter/material.dart';
import '../utils/date_utils.dart'; // Добавляем импорт

class MedicationTakenRecord {
  final int? id;
  final int medicationId;
  final DateTime date;
  final TimeOfDay scheduledTime; // Запланированное время
  final DateTime? actualTakenTime; // Фактическое время приема
  final bool isTaken;

  MedicationTakenRecord({
    this.id,
    required this.medicationId,
    required this.date,
    required this.scheduledTime,
    this.actualTakenTime,
    this.isTaken = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'date': MyDateUtils.toUtcDateString(date),
      'scheduledHour': scheduledTime.hour,
      'scheduledMinute': scheduledTime.minute,
      'actualTakenTime': actualTakenTime != null 
          ? MyDateUtils.toUtcDateTimeString(actualTakenTime!) 
          : null,
      'isTaken': isTaken ? 1 : 0,
    };
  }

  factory MedicationTakenRecord.fromMap(Map<String, dynamic> map) {
    return MedicationTakenRecord(
      id: map['id'],
      medicationId: map['medicationId'],
      date: MyDateUtils.fromUtcDateString(map['date']),
      scheduledTime: TimeOfDay(hour: map['scheduledHour'], minute: map['scheduledMinute']),
      actualTakenTime: map['actualTakenTime'] != null
          ? MyDateUtils.fromUtcDateTimeString(map['actualTakenTime'])
          : null,
      isTaken: map['isTaken'] == 1,
    );
  }

  MedicationTakenRecord copyWith({
    int? id,
    int? medicationId,
    DateTime? date,
    TimeOfDay? scheduledTime,
    DateTime? actualTakenTime,
    bool? isTaken,
  }) {
    return MedicationTakenRecord(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      date: date ?? this.date,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTakenTime: actualTakenTime, // Изменяем, чтобы можно было установить null
      isTaken: isTaken ?? this.isTaken,
    );
  }

  @override
  String toString() {
    return 'MedicationTakenRecord(id: $id, medicationId: $medicationId, date: $date, scheduledTime: ${scheduledTime.hour}:${scheduledTime.minute}, actualTakenTime: $actualTakenTime, isTaken: $isTaken)';
  }
}
