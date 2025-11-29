import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/period_record.dart';
import '../models/settings.dart';
import '../utils/period_calculator.dart';
import '../utils/date_utils.dart' as app_date_utils; // Используем app_date_utils

class CalendarWidget extends StatefulWidget {
  final Function(DateTime) onDaySelected;
  final Settings settings;
  final List<PeriodRecord> periodRecords;

  const CalendarWidget({
    super.key,
    required this.onDaySelected,
    required this.settings,
    required this.periodRecords,
  });

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  // Инициализируем focusedDay и selectedDay как UTC даты
  DateTime _focusedDay = app_date_utils.getUtcToday();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    // Инициализируем _selectedDay также как UTC сегодня, если это не было сделано ранее
    _selectedDay = app_date_utils.getUtcToday();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nextPeriodInfo = PeriodCalculator.getNextPeriodInfo(widget.settings, widget.periodRecords);
    final bool planOverdueToday = PeriodCalculator.isPlanOverdue(widget.settings, widget.periodRecords);

    return Column(
      children: [
        // Информация о следующем периоде
        if (nextPeriodInfo != null && nextPeriodInfo.daysUntil >= 0)
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.calendarNextPeriod,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Отображаем даты в локальном времени для пользователя
                    '${app_date_utils.toLocalDay(nextPeriodInfo.startDate).day}.${app_date_utils.toLocalDay(nextPeriodInfo.startDate).month}.${app_date_utils.toLocalDay(nextPeriodInfo.startDate).year} - ${app_date_utils.toLocalDay(nextPeriodInfo.endDate).day}.${app_date_utils.toLocalDay(nextPeriodInfo.endDate).month}.${app_date_utils.toLocalDay(nextPeriodInfo.endDate).year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.calendarInDays(nextPeriodInfo.daysUntil),
                    style: TextStyle(
                      color: nextPeriodInfo.daysUntil <= 3 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Календарь
        TableCalendar(
          firstDay: app_date_utils.getUtcToday().subtract(const Duration(days: 365 * 10)), // Используем UTC даты
          lastDay: app_date_utils.getUtcToday().add(const Duration(days: 365 * 10)), // Используем UTC даты
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          locale: Localizations.localeOf(context).toLanguageTag(),
          startingDayOfWeek: widget.settings.firstDayOfWeek == 'sunday'
              ? StartingDayOfWeek.sunday
              : StartingDayOfWeek.monday,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          onPageChanged: (focusedDay) {
            _focusedDay = app_date_utils.startOfDayUtc(focusedDay); // Убедимся, что это UTC без времени
          },
          onDaySelected: (selectedDay, focusedDay) {
            final utcSelectedDay = app_date_utils.startOfDayUtc(selectedDay); // Переводим в UTC
            final utcFocusedDay = app_date_utils.startOfDayUtc(focusedDay);   // Переводим в UTC
            setState(() {
              _selectedDay = utcSelectedDay;
              _focusedDay = utcFocusedDay;
            });
            widget.onDaySelected(utcSelectedDay); // Передаем UTC дату
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, events) {
              return _buildCalendarDay(app_date_utils.startOfDayUtc(date), context, planOverdueToday); // Переводим в UTC
            },
            todayBuilder: (context, date, events) {
              return _buildCalendarDay(app_date_utils.startOfDayUtc(date), context, planOverdueToday); // Переводим в UTC
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(l10n),
      ],
    );
  }

  Widget _buildCalendarDay(DateTime date, BuildContext context, bool planOverdueToday) {
    // Входящая 'date' теперь гарантированно UTC без времени
    final bool isToday = isSameDay(date, app_date_utils.getUtcToday());
    
    final PeriodDayType periodType = PeriodCalculator.getPeriodDayType(
      date, 
      widget.settings, 
      widget.periodRecords
    );
    final bool isOvulationDay = PeriodCalculator.isOvulationDay(
      date,
      widget.settings,
      widget.periodRecords,
    );
    final bool isDelayDay = PeriodCalculator.isDelayDay(
      date,
      widget.settings,
      widget.periodRecords,
    );

    Color backgroundColor = Colors.transparent;
    Color textColor = Colors.black;

    // Определяем цвет фона в зависимости от типа дня
    switch (periodType) {
      case PeriodDayType.planned:
        backgroundColor = Colors.pink[100]!;
        break;
      case PeriodDayType.actual:
        backgroundColor = Colors.lightBlue[200]!;
        break;
      case PeriodDayType.none:
        backgroundColor = Colors.transparent;
        break;
    }

    // Если сегодняшний день, добавляем черную обводку и жирный шрифт
    if (isToday) {
      textColor = Colors.black;
    }

    final dayCircle = Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isToday ? Colors.black : (periodType != PeriodDayType.none ? Colors.black26 : Colors.transparent),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          // Дата для отображения всегда в локальном времени
          app_date_utils.toLocalDay(date).day.toString(),
          style: TextStyle(
            color: textColor,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        dayCircle,
        if (isOvulationDay)
          const Positioned(
            bottom: -2,
            right: -2,
            child: Icon(
              Icons.child_friendly,
              size: 16,
              color: Colors.deepPurpleAccent,
            ),
          ),
        if (isDelayDay)
          const Positioned(
            top: -2,
            left: -2,
            child: Icon(
              Icons.access_time,
              size: 16,
              color: Colors.orangeAccent,
            ),
          ),
      ],
    );
  }

  // Легенда цветов
  Widget _buildLegend(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.calendarLegendTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(Colors.pink[100]!, l10n.calendarLegendPlanned),
              _buildLegendItem(Colors.lightBlue[200]!, l10n.calendarLegendActual),
              _buildLegendIconItem(
                Icons.circle,
                l10n.calendarLegendToday,
                Colors.black,
              ),
              _buildLegendIconItem(
                Icons.child_friendly,
                l10n.calendarLegendOvulation,
                Colors.deepPurpleAccent,
              ),
              _buildLegendIconItem(
                Icons.access_time,
                l10n.calendarLegendOverdue,
                Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26),
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildLegendIconItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}