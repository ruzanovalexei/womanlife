// lib/models/frequency_type.dart
import 'dart:convert';

class FrequencyType {
  final int? id;
  final int type; // 1=каждый день, 2=каждый X день, 3=выбор дня недели, 4=X раз в неделю
  final int? intervalValue; // Значение для типов 2 и 4 (количество дней или раз в неделю)
  final List<int>? selectedDaysOfWeek; // Выбранные дни недели для типа 3 (1-7, где 1=понедельник)

  FrequencyType({
    this.id,
    required this.type,
    this.intervalValue,
    this.selectedDaysOfWeek,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'intervalValue': intervalValue,
      'selectedDaysOfWeek': selectedDaysOfWeek != null ? jsonEncode(selectedDaysOfWeek) : null,
    };
  }

  factory FrequencyType.fromMap(Map<String, dynamic> map) {
    List<int>? parsedDaysOfWeek;
    if (map['selectedDaysOfWeek'] != null && (map['selectedDaysOfWeek'] is String) && (map['selectedDaysOfWeek'] as String).isNotEmpty) {
      final List<dynamic> daysJson = jsonDecode(map['selectedDaysOfWeek']);
      parsedDaysOfWeek = daysJson.cast<int>();
    }

    return FrequencyType(
      id: map['id'],
      type: map['type'],
      intervalValue: map['intervalValue'],
      selectedDaysOfWeek: parsedDaysOfWeek,
    );
  }

  String get description {
    switch (type) {
      case 1:
        return 'Каждый день';
      case 2:
        return 'Каждые $intervalValue ${_getDayWord(intervalValue!)}';
      case 3:
        final dayNames = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
        final selectedDays = selectedDaysOfWeek?.map((day) => dayNames[day - 1]).join(', ') ?? '';
        return 'По дням недели: $selectedDays';
      case 4:
        return '$intervalValue ${_getTimeWord(intervalValue!)} в неделю';
      default:
        return 'Неизвестный тип';
    }
  }

  String _getDayWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'день';
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'дня';
    } else {
      return 'дней';
    }
  }

  String _getTimeWord(int count) {
    if (count == 1) {
      return 'раз';
    } else if ([2, 3, 4].contains(count)) {
      return 'раза';
    } else {
      return 'раз';
    }
  }

  /// Проверяет, должна ли привычка выполняться в указанный день
  /// [date] - проверяемая дата
  /// [startDate] - дата начала привычки (нужна для типа 2 - каждый X день)
  bool shouldExecuteOn(DateTime date, DateTime startDate) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    
    switch (type) {
      case 1:
        // Каждый день
        return true;
        
      case 2:
        // Каждый X день
        if (intervalValue == null || intervalValue! < 1) return false;
        final daysDifference = normalizedDate.difference(normalizedStart).inDays;
        // Привычка выполняется в startDate, затем через intervalValue дней
        return daysDifference >= 0 && daysDifference % intervalValue! == 0;
        
      case 3:
        // Дни недели
        if (selectedDaysOfWeek == null || selectedDaysOfWeek!.isEmpty) return false;
        // DateTime.weekday: 1 = Monday, 7 = Sunday
        return selectedDaysOfWeek!.contains(date.weekday);
        
      case 4:
        // X раз в неделю - показываем все дни, пользователь сам решает когда выполнять
        // В отчёте будем считать план как intervalValue / 7 в среднем
        return true;
        
      default:
        return false;
    }
  }

  FrequencyType copyWith({
    int? id,
    int? type,
    int? intervalValue,
    List<int>? selectedDaysOfWeek,
  }) {
    return FrequencyType(
      id: id ?? this.id,
      type: type ?? this.type,
      intervalValue: intervalValue ?? this.intervalValue,
      selectedDaysOfWeek: selectedDaysOfWeek ?? this.selectedDaysOfWeek,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrequencyType &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          intervalValue == other.intervalValue &&
          selectedDaysOfWeek == other.selectedDaysOfWeek;

  @override
  int get hashCode => id.hashCode ^ type.hashCode ^ intervalValue.hashCode ^ selectedDaysOfWeek.hashCode;
}