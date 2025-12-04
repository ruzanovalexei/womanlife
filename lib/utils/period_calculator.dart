import '../models/settings.dart';
import '../models/period_record.dart';
import 'date_utils.dart'; // Добавляем импорт date_utils

class PeriodCalculator {
  // Получить текущую дату в UTC без учета времени
  static DateTime getToday() {
    return MyDateUtils.getUtcToday();
  }

  // Найти последнюю фактическую дату начала месячных
  static DateTime? findLastActualPeriodStart(List<PeriodRecord> periodRecords) {
    if (periodRecords.isEmpty) return null;
    
    // Всегда работаем с UTC датами без времени
    periodRecords.sort((a, b) => b.startDate.compareTo(a.startDate)); // startDate уже в UTC
    
    return periodRecords.first.startDate;
  }

  // Получить все фактические дни месячных из записей о периодах
  static List<DateTime> getAllActualPeriodDays(List<PeriodRecord> periodRecords) {
    List<DateTime> actualDays = [];
    
    for (PeriodRecord record in periodRecords) {
      actualDays.addAll(record.getAllPeriodDates()); // getAllPeriodDates возвращает UTC даты
    }
    
    return actualDays;
  }

  // Расчет плановых периодов на основе последней фактической даты и периода планирования
  static List<PeriodRange> calculatePlannedPeriods(Settings settings, List<PeriodRecord> periodRecords) {
    List<PeriodRange> plannedPeriods = [];
    
    DateTime? lastActualStart = findLastActualPeriodStart(periodRecords);
    if (lastActualStart == null) return plannedPeriods;
    
    // Все даты в UTC, add Duration корректно работает
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

  // Проверка, является ли день плановым днем месячных (все даты уже UTC без времени)
  static bool isPlannedPeriodDay(DateTime day, Settings settings, List<PeriodRecord> periodRecords) {
    final plannedDays = getAllPlannedPeriodDays(settings, periodRecords);
    final normalizedDay = MyDateUtils.startOfDayUtc(day);
    return plannedDays.any((plannedDay) => plannedDay.isAtSameMomentAs(normalizedDay));
  }

  // Проверка, является ли день фактическим днем месячных (все даты уже UTC без времени)
  static bool isActualPeriodDay(DateTime day, List<PeriodRecord> periodRecords) {
    final actualDays = getAllActualPeriodDays(periodRecords);
    final normalizedDay = MyDateUtils.startOfDayUtc(day);
    return actualDays.any((actualDay) => actualDay.isAtSameMomentAs(normalizedDay));
  }

  // Получить тип дня для определения цвета
  static PeriodDayType getPeriodDayType(DateTime day, Settings settings, List<PeriodRecord> periodRecords) {
    // Нормализуем входящий день до UTC без времени
    final normalizedDay = MyDateUtils.startOfDayUtc(day);
    bool isPlanned = isPlannedPeriodDay(normalizedDay, settings, periodRecords);
    bool isActual = isActualPeriodDay(normalizedDay, periodRecords);
    bool isFertile = isFertileDay(normalizedDay, settings, periodRecords);
    
    // Приоритет: фактические дни > плановые дни > фертильные дни > обычные дни
    if (isActual) {
      return PeriodDayType.actual;
    } else if (isPlanned) {
      return PeriodDayType.planned;
    } else if (isFertile) {
      return PeriodDayType.fertile;
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
      daysUntil: nextPeriodStart.difference(getToday()).inDays, // getToday() возвращает UTC
    );
  }

  // Проверить, можно ли отметить начало периода
  static bool canMarkPeriodStart(DateTime selectedDate, PeriodRecord? lastPeriod) {
    final normalizedSelectedDate = MyDateUtils.startOfDayUtc(selectedDate);
    if (lastPeriod == null) return true;
    
    // Можно отметить начало, если выбранная дата после окончания последнего периода
    DateTime lastPeriodEnd = lastPeriod.endDate ?? getToday(); // getToday() возвращает UTC
    return normalizedSelectedDate.isAfter(lastPeriodEnd);
  }

  // Проверить, можно ли отметить окончание периода
  static bool canMarkPeriodEnd(DateTime selectedDate, PeriodRecord? lastPeriod) {
    final normalizedSelectedDate = MyDateUtils.startOfDayUtc(selectedDate);
    if (lastPeriod == null) return false;
    
    // Можно отметить окончание, если есть активный период и выбранная дата >= начала периода
    // lastPeriod.startDate уже в UTC
    return lastPeriod.isActive && 
           (normalizedSelectedDate.isAfter(lastPeriod.startDate) || normalizedSelectedDate.isAtSameMomentAs(lastPeriod.startDate));
  }

  // Проверить, можно ли редактировать период
  static bool canEditPeriod(PeriodRecord? lastPeriod) {
    return lastPeriod != null;
  }

  // Проверить, находится ли день в активном периоде
  static bool isDateInActivePeriod(DateTime date, PeriodRecord? activePeriod) {
    if (activePeriod == null) return false;
    // activePeriod.containsDate уже работает с UTC датами без времени
    return activePeriod.containsDate(MyDateUtils.startOfDayUtc(date));
  }

  static bool isOvulationDay(DateTime day, Settings settings, List<PeriodRecord> periodRecords) {
    final normalizedDay = MyDateUtils.startOfDayUtc(day);
    final cycleLength = settings.cycleLength;
    
    // Овуляция происходит за 14 дней до следующего цикла (медицинский стандарт)
    // Формула: овуляция = начало периода + (cycleLength - 14) дней
    final daysBeforeNextCycle = 14;
    final ovulationOffset = cycleLength - daysBeforeNextCycle;
    
    if (ovulationOffset < 0 || cycleLength <= 0 || daysBeforeNextCycle <= 0 || daysBeforeNextCycle > cycleLength) {
      return false;
    }

    // Check actual recorded periods (record.startDate уже UTC)
    for (final record in periodRecords) {
      final ovulationDate = record.startDate.add(Duration(days: ovulationOffset));
      if (MyDateUtils.startOfDayUtc(ovulationDate) == normalizedDay) {
        return true;
      }
    }

    final lastStart = findLastActualPeriodStart(periodRecords); // Возвращает UTC
    if (lastStart == null) return false;

    final diff = normalizedDay.difference(lastStart).inDays;
    if (diff < 0) return false;

    final offsetInCycle = diff % cycleLength;
    return offsetInCycle == ovulationOffset;
  }

  // Проверить, является ли день фертильным днем (овуляция + 3 дня до + 1 день после)
  static bool isFertileDay(DateTime day, Settings settings, List<PeriodRecord> periodRecords) {
    final normalizedDay = MyDateUtils.startOfDayUtc(day);
    final cycleLength = settings.cycleLength;
    
    // Овуляция происходит за 14 дней до следующего цикла
    final daysBeforeNextCycle = 14;
    final ovulationOffset = cycleLength - daysBeforeNextCycle;
    
    if (ovulationOffset < 0 || cycleLength <= 0 || daysBeforeNextCycle <= 0 || daysBeforeNextCycle > cycleLength) {
      return false;
    }

    // Check actual recorded periods (record.startDate уже UTC)
    for (final record in periodRecords) {
      final ovulationDate = record.startDate.add(Duration(days: ovulationOffset));
      final normalizedOvulationDate = MyDateUtils.startOfDayUtc(ovulationDate);
      
      // Фертильный период: овуляция - 3 дня до + 1 день после
      final fertileStart = normalizedOvulationDate.subtract(const Duration(days: 3));
      final fertileEnd = normalizedOvulationDate.add(const Duration(days: 1));
      
      if (normalizedDay.isAtSameMomentAs(normalizedOvulationDate) ||
          (normalizedDay.isAfter(fertileStart) && normalizedDay.isBefore(fertileEnd))) {
        return true;
      }
    }

    final lastStart = findLastActualPeriodStart(periodRecords); // Возвращает UTC
    if (lastStart == null) return false;

    final diff = normalizedDay.difference(lastStart).inDays;
    if (diff < 0) return false;

    final offsetInCycle = diff % cycleLength;
    
    // Проверяем, находится ли день в фертильном периоде
    return offsetInCycle >= (ovulationOffset - 3) && offsetInCycle <= (ovulationOffset + 1);
  }

  static bool isPlanOverdue(Settings settings, List<PeriodRecord> periodRecords) {
    final lastActualStart = findLastActualPeriodStart(periodRecords); // Возвращает UTC
    final cycleLength = settings.cycleLength;
    if (lastActualStart == null || cycleLength <= 0) return false;

    DateTime plannedStart = lastActualStart.add(Duration(days: cycleLength));
    final DateTime today = getToday(); // Возвращает UTC
    if (plannedStart.isAfter(today)) return false;

    while (true) {
      final DateTime nextStart = plannedStart.add(Duration(days: cycleLength));
      if (MyDateUtils.startOfDayUtc(nextStart).isAfter(today)) { // Нормализуем nextStart на всякий случай
        break;
      }
      plannedStart = nextStart;
    }
    
    final DateTime plannedDate = MyDateUtils.startOfDayUtc(plannedStart); // plannedStart уже UTC
    if (today.isBefore(plannedDate)) return false;
    final diff = today.difference(plannedDate).inDays;
    return diff >= 2;
  }

  // Проверить, является ли день днем задержки (иконка часов)
  static bool isDelayDay(DateTime day, Settings settings, List<PeriodRecord> periodRecords) {
    final normalizedDay = MyDateUtils.startOfDayUtc(day);
    final lastActualStart = findLastActualPeriodStart(periodRecords); // Возвращает UTC
    final cycleLength = settings.cycleLength;
    if (lastActualStart == null || cycleLength <= 0) return false;

    final normalizedLastActualStart = lastActualStart; // Уже UTC без времени
    
    final DateTime normalizedToday = getToday(); // Возвращает UTC
    
    if (normalizedDay.isAfter(normalizedToday)) return false;
    
    DateTime plannedStart = normalizedLastActualStart.add(Duration(days: cycleLength));
    
    if (plannedStart.isAfter(normalizedToday)) return false;
    
    while (true) {
      final DateTime nextStart = plannedStart.add(Duration(days: cycleLength));
      if (MyDateUtils.startOfDayUtc(nextStart).isAfter(normalizedToday)) { // Нормализуем nextStart на всякий случай
        break;
      }
      plannedStart = nextStart;
    }
    
    if (normalizedDay.isBefore(plannedStart)) return false;
    
    final daysDifference = normalizedDay.difference(plannedStart).inDays;
    if (daysDifference < 2) return false;
    
    final actualPeriodRecords = periodRecords.where((record) {
      final normalizedRecordStart = record.startDate; // Уже UTC без времени
      return normalizedRecordStart.isAfter(plannedStart.subtract(const Duration(days: 1))) &&
             normalizedRecordStart.isBefore(normalizedDay.add(const Duration(days: 1)));
    }).toList();
    
    if (actualPeriodRecords.isNotEmpty) return false;
    
    return true;
  }
}

// Типы дней для определения цвета
enum PeriodDayType {
  none,      // Не день месячных
  planned,   // Только плановый
  actual,    // Только фактический
  fertile,   // Фертильный день
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