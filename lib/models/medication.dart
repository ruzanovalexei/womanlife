// lib/models/medication.dart
import 'dart:convert';
import '../utils/date_utils.dart'; // Добавляем импорт
import '../models/medication_time.dart';

class Medication {
  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final List<MedicationTime> times; // Время приема в течение дня

  Medication({
    this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.times,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': MyDateUtils.toUtcDateString(startDate), // Используем toUtcDateString
      'endDate': endDate != null ? MyDateUtils.toUtcDateString(endDate!) : null, // Используем toUtcDateString
      'times': jsonEncode(times.map((t) => t.toMap()).toList()),
    };
  }


  factory Medication.fromMap(Map<String, dynamic> map) {
    final List<MedicationTime> parsedTimes = [];
    if (map['times'] != null && (map['times'] is String) && (map['times'] as String).isNotEmpty) {
      final List<dynamic> timesJson = jsonDecode(map['times']);
      for (dynamic timeMap in timesJson) {
        parsedTimes.add(MedicationTime.fromMap(timeMap));
      }
    }

    return Medication(
      id: map['id'],
      name: map['name'],
      startDate: MyDateUtils.fromUtcDateString(map['startDate']), // Используем fromUtcDateString
      endDate: map['endDate'] != null ? MyDateUtils.fromUtcDateString(map['endDate']) : null, // Используем fromUtcDateString
      times: parsedTimes,
    );
  }

  String get timesAsString {
    return times.map((t) => t.toString()).join(', ');
  }

 // Проверка, активен ли препарат в конкретный день
  bool isActiveOn(DateTime day) {
    // Входная 'day' также должна быть UTC датой без времени
    // Все даты в Medication (startDate, endDate) теперь уже UTC без времени
    final normalizedDay = MyDateUtils.startOfDayUtc(day);
    final normalizedStartDate = startDate; // Уже нормализована
    final normalizedEndDate = endDate; // Уже нормализована

    if (normalizedDay.isBefore(normalizedStartDate)) return false;
    if (normalizedEndDate != null && normalizedDay.isAfter(normalizedEndDate)) return false;

    return true; // Активен в этот день
  }

  Medication copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    List<MedicationTime>? times,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate,
      times: times ?? this.times,
    );
  }
}



