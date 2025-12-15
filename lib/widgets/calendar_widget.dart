import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/period_record.dart';
import '../models/settings.dart';
import '../utils/period_calculator.dart';
import '../utils/date_utils.dart'; // Используем app_date_utils

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
  // Инициализируем focusedDay и selectedDay как UTC даты
  DateTime _focusedDay = MyDateUtils.getUtcToday();
  DateTime? _selectedDay;

  // Состояние блока легенды (по умолчанию закрыт)
  bool _isLegendBlockExpanded = false;

  @override
  void initState() {
    super.initState();
    // Инициализируем _selectedDay также как UTC сегодня, если это не было сделано ранее
    _selectedDay = MyDateUtils.getUtcToday();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nextPeriodInfo = PeriodCalculator.getNextPeriodInfo(widget.settings, widget.periodRecords);
    final bool planOverdueToday = PeriodCalculator.isPlanOverdue(widget.settings, widget.periodRecords);

    return Column(
      children: [
        // Прокручиваемый контент календаря
        Expanded(
          child: SingleChildScrollView(
            child: Column(
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
                            '${MyDateUtils.toLocalDay(nextPeriodInfo.startDate).day}.${MyDateUtils.toLocalDay(nextPeriodInfo.startDate).month}.${MyDateUtils.toLocalDay(nextPeriodInfo.startDate).year} - ${MyDateUtils.toLocalDay(nextPeriodInfo.endDate).day}.${MyDateUtils.toLocalDay(nextPeriodInfo.endDate).month}.${MyDateUtils.toLocalDay(nextPeriodInfo.endDate).year}',
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
                
                // Кастомный заголовок без кнопки формата
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(
                              _focusedDay.year,
                              _focusedDay.month - 1,
                              1,
                            );
                          });
                        },
                      ),
                      Text(
                        '${_getMonthName(_focusedDay.month, context)} ${_focusedDay.year}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(
                              _focusedDay.year,
                              _focusedDay.month + 1,
                              1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                // Календарь
                TableCalendar(
                  firstDay: MyDateUtils.getUtcToday().subtract(const Duration(days: 365 * 10)), // Используем UTC даты
                  lastDay: MyDateUtils.getUtcToday().add(const Duration(days: 365 * 10)), // Используем UTC даты
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month, // Фиксируем формат на месяц
                  headerVisible: false, // Скрываем встроенный заголовок
                  locale: Localizations.localeOf(context).toLanguageTag(),
                  startingDayOfWeek: widget.settings.firstDayOfWeek == 'sunday'
                      ? StartingDayOfWeek.sunday
                      : StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = MyDateUtils.startOfDayUtc(focusedDay); // Убедимся, что это UTC без времени
                    });
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    final utcSelectedDay = MyDateUtils.startOfDayUtc(selectedDay); // Переводим в UTC
                    final utcFocusedDay = MyDateUtils.startOfDayUtc(focusedDay);   // Переводим в UTC
                    setState(() {
                      _selectedDay = utcSelectedDay;
                      _focusedDay = utcFocusedDay;
                    });
                    widget.onDaySelected(utcSelectedDay); // Передаем UTC дату
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, date, events) {
                      return _buildCalendarDay(MyDateUtils.startOfDayUtc(date), context, planOverdueToday); // Переводим в UTC
                    },
                    todayBuilder: (context, date, events) {
                      return _buildCalendarDay(MyDateUtils.startOfDayUtc(date), context, planOverdueToday); // Переводим в UTC
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildLegend(l10n),
                const SizedBox(height: 16), // Добавляем отступ внизу для лучшего UX
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarDay(DateTime date, BuildContext context, bool planOverdueToday) {
    // Входящая 'date' теперь гарантированно UTC без времени
    final bool isToday = isSameDay(date, MyDateUtils.getUtcToday());
    
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
    final bool isFertileDay = PeriodCalculator.isFertileDay(
      date,
      widget.settings,
      widget.periodRecords,
    );
    final bool isDelayDay = PeriodCalculator.isDelayDay(
      date,
      widget.settings,
      widget.periodRecords,
    );

    // Получаем номер дня в цикле
    final int? cycleDayNumber = PeriodCalculator.getCycleDayNumber(
      date,
      widget.settings,
      widget.periodRecords,
    );

    Color backgroundColor = Colors.transparent;
    Color textColor = const Color.fromARGB(255, 15, 42, 95); // Изменяем цвет текста на белый

    // Определяем цвет фона в зависимости от типа дня
    switch (periodType) {
      case PeriodDayType.planned:
        backgroundColor = Colors.pink[100]!;
        break;
      case PeriodDayType.actual:
        backgroundColor = Colors.red[200]!;
        break;
      case PeriodDayType.fertile:
        backgroundColor = Colors.green[200]!; // Зеленый для фертильных дней
        break;
      case PeriodDayType.none:
        backgroundColor = Colors.transparent;
        break;
    }

    // Если день фертильный, но не является днем месячных, используем зеленый цвет
    if (isFertileDay && periodType == PeriodDayType.none) {
      backgroundColor = Colors.green[200]!;
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
          color: const Color.fromARGB(255, 15, 42, 95), // Белое обрамление для всех дней
          width: periodType != PeriodDayType.none ? 2 : 1, // Толще для месячных и фертильных дней
        ),
      ),
      child: Center(
        child: Text(
          // Дата для отображения всегда в локальном времени
          MyDateUtils.toLocalDay(date).day.toString(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold, // Все номера дней делаем жирными
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
            top: -2,
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
            right: -2,
            child: Icon(
              Icons.access_time,
              size: 16,
              color: Colors.red,
            ),
          ),
        if (cycleDayNumber != null)
          Positioned(
            bottom: -2,
            left: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue[100]!,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[300]!, width: 1),
              ),
              child: Text(
                cycleDayNumber.toString(),
                style: TextStyle(
                  color: Colors.blue[800]!,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Раскрывающийся блок "Легенда"
  Widget _buildLegendBlock(AppLocalizations l10n) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: _isLegendBlockExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isLegendBlockExpanded = expanded;
          });
        },
        title: Text(
          'Легенда',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Добавляем объяснение нумерации дней цикла
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50]!,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Нумерация дней цикла:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800]!,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Числа в левом нижнем углу показывают день от начала цикла\n• После новых месячных нумерация начинается заново\n• В текущих месячных показываются дни до планового начала следующего цикла',
                        style: TextStyle(
                          color: Colors.blue[700]!,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.calendarLegendTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Упрощенная версия легенды для диагностики
                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.pink[100]!,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black26),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(l10n.calendarLegendPlanned),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.red[200]!,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black26),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(l10n.calendarLegendActual),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green[200]!,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black26),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(l10n.calendarLegendFertile),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black),
                          ),
                          child: const Icon(Icons.circle, size: 12, color: Colors.black),
                        ),
                        const SizedBox(width: 4),
                        Text(l10n.calendarLegendToday),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.deepPurpleAccent),
                          ),
                          child: const Icon(Icons.child_friendly, size: 12, color: Colors.deepPurpleAccent),
                        ),
                        const SizedBox(width: 4),
                        Text(l10n.calendarLegendOvulation),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red),
                          ),
                          child: const Icon(Icons.access_time, size: 12, color: Colors.red),
                        ),
                        const SizedBox(width: 4),
                        Text(l10n.calendarLegendOverdue),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Легенда цветов (старый метод для обратной совместимости)
  Widget _buildLegend(AppLocalizations l10n) {
    return _buildLegendBlock(l10n);
  }

  // Widget _buildLegendItem(Color color, String text) {
  //   return Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Container(
  //         width: 16,
  //         height: 16,
  //         decoration: BoxDecoration(
  //           color: color,
  //           shape: BoxShape.circle,
  //           border: Border.all(color: Colors.black26),
  //         ),
  //       ),
  //       const SizedBox(width: 4),
  //       Text(text, style: const TextStyle(fontSize: 12)),
  //     ],
  //   );
  // }

  // Widget _buildLegendIconItem(IconData icon, String text, Color color) {
  //   return Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Container(
  //         width: 18,
  //         height: 18,
  //         decoration: BoxDecoration(
  //           color: Colors.transparent,
  //           shape: BoxShape.circle,
  //           border: Border.all(color: color),
  //         ),
  //         child: Icon(icon, size: 12, color: color),
  //       ),
  //       const SizedBox(width: 4),
  //       Text(text, style: const TextStyle(fontSize: 12)),
  //     ],
  //   );
  // }

  // Получить локализованное название месяца
  String _getMonthName(int month, BuildContext context) {
    final locale = Localizations.localeOf(context);
    return DateFormat('LLLL', locale.toLanguageTag()).format(DateTime(DateTime.now().year, month, 1));
  }
}