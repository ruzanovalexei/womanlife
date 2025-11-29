// lib/models/medication.dart
import 'dart:convert';

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
      'startDate': _formatDate(startDate),
      'endDate': endDate != null ? _formatDate(endDate!) : null,
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
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      times: parsedTimes,
    );
  }

  String get timesAsString {
    return times.map((t) => t.toString()).join(', ');
  }

  // Вспомогательный метод для форматирования даты
  static String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0]; // YYYY-MM-DD
  }

  // Проверка, активен ли препарат в конкретный день
  bool isActiveOn(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEndDate = endDate != null ? DateTime(endDate!.year, endDate!.month, endDate!.day) : null;

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

// lib/models/medication_time.dart
class MedicationTime {
  final int hour;
  final int minute;

  MedicationTime({required this.hour, required this.minute});

  factory MedicationTime.fromMap(Map<String, dynamic> map) {
    return MedicationTime(
      hour: map['hour'],
      minute: map['minute'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationTime &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}
