import '../utils/date_utils.dart'; // Добавляем импорт

class DayNote {
  final int? id;
  final DateTime date;
  final List<String> symptoms;
  // Новые поля для блока секса
  final bool? hadSex; // Был ли секс (null = не выбрано)
  final bool? isSafeSex; // Безопасный ли секс (null = не выбрано, true = безопасный, false = небезопасный)
  final bool? hadOrgasm; // Был ли оргазм (null = не выбрано)

  const DayNote({
    this.id,
    required this.date,
    required this.symptoms,
    this.hadSex,
    this.isSafeSex,
    this.hadOrgasm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': MyDateUtils.toUtcDateString(date), // Используем toUtcDateString
      'symptoms': symptoms.join(','),
      'hadSex': hadSex != null ? (hadSex! ? 1 : 0) : null,
      'isSafeSex': isSafeSex != null ? (isSafeSex! ? 1 : 0) : null,
      'hadOrgasm': hadOrgasm != null ? (hadOrgasm! ? 1 : 0) : null,
    };
  }

  factory DayNote.fromMap(Map<String, dynamic> map) {
    return DayNote(
      id: map['id'],
      date: MyDateUtils.fromUtcDateString(map['date']), // Используем fromUtcDateString
      symptoms: _parseSymptoms(map['symptoms']),
      hadSex: map['hadSex'] != null ? map['hadSex'] == 1 : null,
      isSafeSex: map['isSafeSex'] != null ? map['isSafeSex'] == 1 : null,
      hadOrgasm: map['hadOrgasm'] != null ? map['hadOrgasm'] == 1 : null,
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
    bool? hadSex,
    bool? isSafeSex,
    bool? hadOrgasm,
  }) {
    return DayNote(
      id: id ?? this.id,
      date: date ?? this.date,
      symptoms: symptoms ?? this.symptoms,
      hadSex: hadSex ?? this.hadSex,
      isSafeSex: isSafeSex ?? this.isSafeSex,
      hadOrgasm: hadOrgasm ?? this.hadOrgasm,
    );
  }

  @override
  String toString() {
    return 'DayNote{id: $id, date: $date, symptoms: $symptoms, hadSex: $hadSex, isSafeSex: $isSafeSex, hadOrgasm: $hadOrgasm}';
  }
}