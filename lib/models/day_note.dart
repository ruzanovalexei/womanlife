import '../utils/date_utils.dart'; // Добавляем импорт

class DayNote {
  final int? id;
  final DateTime date;
  final List<String> symptoms;
  final int sexualActsCount;

  const DayNote({
    this.id,
    required this.date,
    required this.symptoms,
    this.sexualActsCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': MyDateUtils.toUtcDateString(date), // Используем toUtcDateString
      'symptoms': symptoms.join(','),
      'sexualActsCount': sexualActsCount,
    };
  }

  factory DayNote.fromMap(Map<String, dynamic> map) {
    return DayNote(
      id: map['id'],
      date: MyDateUtils.fromUtcDateString(map['date']), // Используем fromUtcDateString
      symptoms: _parseSymptoms(map['symptoms']),
      sexualActsCount: map['sexualActsCount'] ?? 0,
    );
  }

  static List<String> _parseSymptoms(String symptomsString) {
    if (symptomsString.isEmpty) {
      return [];
    }
    return symptomsString.split(',');
  }

  static String formatDateForDatabase(DateTime date) {
    // Эта функция используется только для запросов к БД, где дата хранится в UTC.
    // Поэтому форматируем входящую дату в UTC-строку.
    return MyDateUtils.toUtcDateString(date);
  }

  DayNote copyWith({
    int? id,
    DateTime? date,
    List<String>? symptoms,
    int? sexualActsCount,
  }) {
    return DayNote(
      id: id ?? this.id,
      date: date ?? this.date,
      symptoms: symptoms ?? this.symptoms,
      sexualActsCount: sexualActsCount ?? this.sexualActsCount,
    );
  }

  @override
  String toString() {
    return 'DayNote{id: $id, date: $date, symptoms: $symptoms, sexualActsCount: $sexualActsCount}';
  }
}