class Settings {
  final int? id;
  final int cycleLength;
  final int periodLength;
  final int planningMonths; // Период планирования в месяцах
  final String locale;
  final String firstDayOfWeek;

  const Settings({
    this.id,
    required this.cycleLength,
    required this.periodLength,
    required this.planningMonths,
    required this.locale,
    required this.firstDayOfWeek,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cycleLength': cycleLength,
      'periodLength': periodLength,
      'planningMonths': planningMonths,
      'locale': locale,
      'firstDayOfWeek': firstDayOfWeek,
    };
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      id: map['id'],
      cycleLength: map['cycleLength'],
      periodLength: map['periodLength'],
      planningMonths: map['planningMonths'] ?? 3, // По умолчанию 3 месяца
      locale: map['locale'] ?? 'en',
      firstDayOfWeek: map['firstDayOfWeek'] ?? 'monday',
    );
  }

  Settings copyWith({
    int? id,
    int? cycleLength,
    int? periodLength,
    int? planningMonths,
    String? locale,
    String? firstDayOfWeek,
  }) {
    return Settings(
      id: id ?? this.id,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      planningMonths: planningMonths ?? this.planningMonths,
      locale: locale ?? this.locale,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
    );
  }

  @override
  String toString() {
    return 'Settings{id: $id, cycleLength: $cycleLength, periodLength: $periodLength, planningMonths: $planningMonths, locale: $locale, firstDayOfWeek: $firstDayOfWeek}';
  }
}