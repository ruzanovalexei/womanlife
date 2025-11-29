import '../models/settings.dart';
import '../models/period_record.dart';

class PeriodCalculator {
  // Получить текущую дату в локальном времени (без времени)
  static DateTime getToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Найти последнюю фактическую дату начала месячных
  static DateTime? findLastActualPeriodStart(List<PeriodRecord> periodRecords) {
    if (periodRecords.isEmpty) return null;
    
    // Сортируем записи по дате начала (от новых к старым)
    periodRecords.sort((a, b) => b.startDate.compareTo(a.startDate));
    
    return periodRecords.first.startDate;
  }

  // Получить все фактические дни месячных из записей о периодах
  static List<DateTime> getAllActualPeriodDays(List<PeriodRecord> periodRecords) {
    List<DateTime> actualDays = [];
    
    for (PeriodRecord record in periodRecords) {
      actualDays.addAll(record.getAllPeriodDates());
    }
    
    return actualDays;
  }

  // Расчет плановых периодов на основе последней фактической даты и периода планирования
  static List<PeriodRange> calculatePlannedPeriods(Settings settings, List<PeriodRecord> periodRecords) {
    List<PeriodRange> plannedPeriods = [];
    
    DateTime? lastActualStart = findLastActualPeriodStart(periodRecords);
    if (lastActualStart == null) return plannedPeriods;
    
    DateTime endDate = getToday().add(Duration(days: 30 * settings.planningMonths));
    
    DateTime currentPeriodStart = lastActualStart;
    
    while (!currentPeriodStart.isAfter(endDate)) {
      DateTime periodEnd = currentPeriodStart.add(Duration(days: settings.periodLength - 1));
      plannedPeriods.add(PeriodRange(
        startDate: currentPeriodStart,
        endDate: periodEnd,
      ));
      
      currentPeriodStart = currentPeriodStart.add(Duration(days: settings.cycleLength));
    }
    
    return plannedPeriods;
  }

  // Получить все плановые дни месячных
  static List<DateTime> getAllPlannedPeriodDays(Settings settings, List<PeriodRecord> periodRecords) {
    List<DateTime> plannedDays = [];
    List<PeriodRange> plannedPeriods = calculatePlannedPeriods(settings, periodRecords);
    
    for (PeriodRange period in plannedPeriods) {
      DateTime current = period.startDate;
      while (current.isBefore(period.endDate) || current.isAtSameMomentAs(period.endDate)) {
        plannedDays.add(current);
        current = current.add(const Duration(days: 1));
      }
    }
    
    return plannedDays;
  }

  // Проверка, является ли день плановым днем месячных
  static bool isPlannedPeriodDay(DateTime day, Settings settings, List<PeriodRecord> periodRecords) {
    final plannedDays = getAllPlannedPeriodDays(settings, periodRecords);
    return plannedDays.any((plannedDay) => 
      plannedDay.year == day.year &&
      plannedDay.month == day.month &&
      plannedDay.day == day.day
    );
  }

  // Проверка, является ли день фактическим днем месячных
  static bool isActualPeriodDay(DateTime day, List<PeriodRecord> periodRecords) {
    final actualDays = getAllActualPeriodDays(periodRecords);
    return actualDays.any((actualDay) => 
      actualDay.year == day.year &&
      actualDay.month == day.month &&
      actualDay.day == day.day
    );
  }

  // Получить тип дня для определения цвета
  static PeriodDayType getPeriodDayType(DateTime day, Settings settings, List<PeriodRecord> periodRecords) {
    bool isPlanned = isPlannedPeriodDay(day, settings, periodRecords);
    bool isActual = isActualPeriodDay(day, periodRecords);
    
    // Приоритет отдается фактическим дням
    if (isActual) {
      return PeriodDayType.actual;
    } else if (isPlanned) {
      return PeriodDayType.planned;
    } else {
      return PeriodDayType.none;
    }
  }

  // Получить информацию о следующем плановом периоде
  static NextPeriodInfo? getNextPeriodInfo(Settings settings, List<PeriodRecord> periodRecords) {
    DateTime? lastActualStart = findLastActualPeriodStart(periodRecords);
    if (lastActualStart == null) return null;
    
    DateTime nextPeriodStart = lastActualStart.add(Duration(days: settings.cycleLength));
    DateTime nextPeriodEnd = nextPeriodStart.add(Duration(days: settings.periodLength - 1));
    
    return NextPeriodInfo(
      startDate: nextPeriodStart,
      endDate: nextPeriodEnd,
      daysUntil: nextPeriodStart.difference(getToday()).inDays,
    );
  }

  // Проверить, можно ли отметить начало периода
  static bool canMarkPeriodStart(DateTime selectedDate, PeriodRecord? lastPeriod) {
    if (lastPeriod == null) return true;
    
    // Можно отметить начало, если выбранная дата после окончания последнего периода
    DateTime lastPeriodEnd = lastPeriod.endDate ?? getToday();
    return selectedDate.isAfter(lastPeriodEnd);
  }

  // Проверить, можно ли отметить окончание периода
  static bool canMarkPeriodEnd(DateTime selectedDate, PeriodRecord? lastPeriod) {
    if (lastPeriod == null) return false;
    
    // Можно отметить окончание, если есть активный период и выбранная дата >= начала периода
    return lastPeriod.isActive && 
           (selectedDate.isAfter(lastPeriod.startDate) || selectedDate.isAtSameMomentAs(lastPeriod.startDate));
  }

  // Проверить, можно ли редактировать период
  static bool canEditPeriod(PeriodRecord? lastPeriod) {
    return lastPeriod != null;
  }

  // Проверить, находится ли день в активном периоде
  static bool isDateInActivePeriod(DateTime date, PeriodRecord? activePeriod) {
    if (activePeriod == null) return false;
    return activePeriod.containsDate(date);
  }

  static bool isOvulationDay(DateTime day, Settings settings, List<PeriodRecord> periodRecords) {
    final ovulationOffset = settings.ovulationDay - 1;
    final cycleLength = settings.cycleLength;
    if (ovulationOffset < 0 || cycleLength <= 0 || ovulationOffset >= cycleLength) {
      return false;
    }

    bool isSameDate(DateTime other) =>
        other.year == day.year && other.month == day.month && other.day == day.day;

    // Check actual recorded periods
    for (final record in periodRecords) {
      final ovulationDate = record.startDate.add(Duration(days: ovulationOffset));
      if (isSameDate(ovulationDate)) {
        return true;
      }
    }

    final lastStart = findLastActualPeriodStart(periodRecords);
    if (lastStart == null) return false;

    final diff = day.difference(lastStart).inDays;
    if (diff < 0) return false;

    final offsetInCycle = diff % cycleLength;
    return offsetInCycle == ovulationOffset;
  }

  static bool isPlanOverdue(Settings settings, List<PeriodRecord> periodRecords) {
    final lastActualStart = findLastActualPeriodStart(periodRecords);
    final cycleLength = settings.cycleLength;
    if (lastActualStart == null || cycleLength <= 0) return false;

    DateTime plannedStart = lastActualStart.add(Duration(days: cycleLength));
    final DateTime today = getToday();
    if (plannedStart.isAfter(today)) return false;

    while (true) {
      final DateTime nextStart = plannedStart.add(Duration(days: cycleLength));
      if (nextStart.isAfter(today)) {
        break;
      }
      plannedStart = nextStart;
    }

    final DateTime plannedDate = DateTime(plannedStart.year, plannedStart.month, plannedStart.day);
    if (today.isBefore(plannedDate)) return false;
    final diff = today.difference(plannedDate).inDays;
    return diff >= 2;
  }

  // Проверить, является ли день днем задержки (иконка часов)
  static bool isDelayDay(DateTime day, Settings settings, List<PeriodRecord> periodRecords) {
    final lastActualStart = findLastActualPeriodStart(periodRecords);
    final cycleLength = settings.cycleLength;
    if (lastActualStart == null || cycleLength <= 0) return false;

    // Нормализуем даты до начала дня для корректного сравнения
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    DateTime normalizedLastActualStart = DateTime(
      lastActualStart.year, 
      lastActualStart.month, 
      lastActualStart.day
    );
    
    // Находим текущую дату
    final DateTime normalizedToday = getToday();
    
    // Если проверяемый день в будущем относительно текущей даты, это не день задержки
    if (normalizedDay.isAfter(normalizedToday)) return false;
    
    // Находим ближайшую плановую дату начала месячных к текущей дате
    DateTime plannedStart = normalizedLastActualStart.add(Duration(days: cycleLength));
    
    // Если плановая дата еще не наступила до текущей даты, это не день задержки
    if (plannedStart.isAfter(normalizedToday)) return false;
    
    // Ищем ближайшую плановую дату к текущей дате
    while (true) {
      final DateTime nextStart = plannedStart.add(Duration(days: cycleLength));
      if (nextStart.isAfter(normalizedToday)) {
        break;
      }
      plannedStart = nextStart;
    }
    
    // Если проверяемый день раньше плановой даты, это не день задержки
    if (normalizedDay.isBefore(plannedStart)) return false;
    
    // Проверяем, что проверяемый день на 2+ дней позже плановой даты
    final daysDifference = normalizedDay.difference(plannedStart).inDays;
    if (daysDifference < 2) return false;
    
    // Проверяем, есть ли фактические данные о месячных в период от плановой даты до проверяемого дня
    final actualPeriodRecords = periodRecords.where((record) {
      DateTime normalizedRecordStart = DateTime(
        record.startDate.year, 
        record.startDate.month, 
        record.startDate.day
      );
      return normalizedRecordStart.isAfter(plannedStart.subtract(const Duration(days: 1))) &&
             normalizedRecordStart.isBefore(normalizedDay.add(const Duration(days: 1)));
    }).toList();
    
    // Если есть фактические данные в этот период, то это не задержка
    if (actualPeriodRecords.isNotEmpty) return false;
    
    return true;
  }
}

// Типы дней для определения цвета
enum PeriodDayType {
  none,      // Не день месячных
  planned,   // Только плановый
  actual,    // Только фактический
}

// Информация о следующем периоде
class NextPeriodInfo {
  final DateTime startDate;
  final DateTime endDate;
  final int daysUntil;

  const NextPeriodInfo({
    required this.startDate,
    required this.endDate,
    required this.daysUntil,
  });
}

// Диапазон периода
class PeriodRange {
  final DateTime startDate;
  final DateTime endDate;

  const PeriodRange({
    required this.startDate,
    required this.endDate,
  });
}