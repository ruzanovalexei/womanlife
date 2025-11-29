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
      'date': _formatDate(date),
      'symptoms': symptoms.join(','),
      'sexualActsCount': sexualActsCount,
    };
  }

  factory DayNote.fromMap(Map<String, dynamic> map) {
    return DayNote(
      id: map['id'],
      date: DateTime.parse(map['date']),
      symptoms: _parseSymptoms(map['symptoms']),
      sexualActsCount: map['sexualActsCount'] ?? 0,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static List<String> _parseSymptoms(String symptomsString) {
    if (symptomsString.isEmpty) {
      return [];
    }
    return symptomsString.split(',');
  }

  static String formatDateForDatabase(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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