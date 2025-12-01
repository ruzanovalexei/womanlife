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