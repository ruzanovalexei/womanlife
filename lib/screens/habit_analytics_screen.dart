import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/models/habit_execution.dart';
import 'package:period_tracker/models/habit_measurable.dart';
import 'package:period_tracker/models/habit_daily_stats.dart';
import 'package:period_tracker/models/habit_execution_record.dart';
import 'package:period_tracker/models/habit_measurable_record.dart';
import 'package:period_tracker/models/frequency_type.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/utils/date_utils.dart';

/// Тип привычки для аналитики
enum HabitType { execution, measurable }

class HabitAnalyticsScreen extends StatefulWidget {
  final dynamic habit; // HabitExecution или HabitMeasurable
  final HabitType habitType;

  const HabitAnalyticsScreen({
    super.key,
    required this.habit,
    required this.habitType,
  });

  @override
  State<HabitAnalyticsScreen> createState() => _HabitAnalyticsScreenState();
}

class _HabitAnalyticsScreenState extends State<HabitAnalyticsScreen> {
  final _databaseHelper = DatabaseHelper();
  final _chartScrollController = ScrollController();
  List<HabitDailyStats> _dailyStats = [];
  bool _isLoading = true;
  
  // Сводная статистика
  double _totalPlanned = 0;
  double _totalActual = 0;
  double _adherencePercent = 0;
  
  // Данные привычки
  late String _habitName;
  late String _unit;
  late DateTime _startDate;
  late DateTime? _endDate;
  late int _frequencyId;

  // FrequencyType
  FrequencyType? _frequencyType;

  @override
  void initState() {
    super.initState();
    _initHabitData();
    _loadStats();
  }

  void _initHabitData() {
    if (widget.habitType == HabitType.execution) {
      final habit = widget.habit as HabitExecution;
      _habitName = habit.name;
      _unit = ''; // Для привычек выполнения нет единицы измерения
      _startDate = habit.startDate;
      _endDate = habit.endDate;
      _frequencyId = habit.frequencyId;
    } else {
      final habit = widget.habit as HabitMeasurable;
      _habitName = habit.name;
      _unit = habit.unit;
      _startDate = habit.startDate;
      _endDate = habit.endDate;
      _frequencyId = habit.frequencyId;
    }
  }

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      // Загружаем FrequencyType
      _frequencyType = await _databaseHelper.getFrequencyTypeById(_frequencyId);
      
      // Определяем период (только до сегодняшнего дня)
      final today = MyDateUtils.startOfDayUtc(DateTime.now());
      final normalizedStart = MyDateUtils.startOfDayUtc(_startDate);
      final normalizedEnd = _endDate != null 
          ? MyDateUtils.startOfDayUtc(_endDate!) 
          : today;
      
      // Не показываем будущие дни - берём минимум из endDate и today
      final actualEnd = normalizedEnd.isBefore(today) ? normalizedEnd : today;
      
      List<HabitDailyStats> stats = [];
      
      if (widget.habitType == HabitType.execution) {
        stats = await _loadExecutionStats(normalizedStart, actualEnd);
      } else {
        stats = await _loadMeasurableStats(normalizedStart, actualEnd);
      }
      
      if (mounted) {
        setState(() {
          _dailyStats = stats;
          _isLoading = false;
          
          // Вычисляем сводную статистику
          _totalPlanned = stats.fold(0.0, (sum, s) => sum + s.plannedValue);
          
          // Для измеримых привычек считаем количество выполнений, а не сумму значений
          if (widget.habitType == HabitType.measurable) {
            _totalActual = stats.where((s) => s.actualValue > 0).length.toDouble();
            // Пересчитываем план как количество дней
            _totalPlanned = stats.length.toDouble();
          } else {
            _totalActual = stats.fold(0.0, (sum, s) => sum + s.actualValue);
          }
          
          _adherencePercent = _totalPlanned > 0 
              ? (_totalActual / _totalPlanned * 100).clamp(0, 100) 
              : 0;
        });
        
        // Прокручиваем к последним дням после построения виджета
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chartScrollController.hasClients) {
            final maxScroll = _chartScrollController.position.maxScrollExtent;
            _chartScrollController.jumpTo(maxScroll);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading habit stats: $e');
    }
  }

  Future<List<HabitDailyStats>> _loadExecutionStats(
    DateTime startDate, 
    DateTime endDate,
  ) async {
    final habit = widget.habit as HabitExecution;
    
    // Получаем записи о выполнении
    final records = await _databaseHelper.getHabitExecutionRecordsByHabitId(habit.id!);
    
    // Группируем записи по датам
    final Map<DateTime, HabitExecutionRecord> recordsByDate = {};
    for (final record in records) {
      final dateKey = MyDateUtils.startOfDayUtc(record.executionDate);
      recordsByDate[dateKey] = record;
    }
    
    // Создаем статистику только для дней, когда привычка запланирована
    final List<HabitDailyStats> stats = [];
    var currentDate = startDate;
    
    while (!currentDate.isAfter(endDate)) {
      // Проверяем, должна ли привычка выполняться в этот день
      if (_frequencyType?.shouldExecuteOn(currentDate, startDate) ?? true) {
        final record = recordsByDate[currentDate];
        
        stats.add(HabitDailyStats(
          date: currentDate,
          plannedValue: 1, // Для execution план = 1
          actualValue: (record?.isCompleted ?? false) ? 1 : 0,
          isMeasurable: false,
        ));
      }
      
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return stats;
  }

  Future<List<HabitDailyStats>> _loadMeasurableStats(
    DateTime startDate, 
    DateTime endDate,
  ) async {
    final habit = widget.habit as HabitMeasurable;
    
    // Получаем записи о выполнении
    final records = await _databaseHelper.getHabitMeasurableRecordsByHabitId(habit.id!);
    
    // Группируем записи по датам
    final Map<DateTime, HabitMeasurableRecord> recordsByDate = {};
    for (final record in records) {
      final dateKey = MyDateUtils.startOfDayUtc(record.executionDate);
      recordsByDate[dateKey] = record;
    }
    
    // Создаем статистику только для дней, когда привычка запланирована
    final List<HabitDailyStats> stats = [];
    var currentDate = startDate;
    
    while (!currentDate.isAfter(endDate)) {
      // Проверяем, должна ли привычка выполняться в этот день
      if (_frequencyType?.shouldExecuteOn(currentDate, startDate) ?? true) {
        final record = recordsByDate[currentDate];
        
        stats.add(HabitDailyStats(
          date: currentDate,
          plannedValue: habit.goal,
          actualValue: record?.actualValue ?? 0,
          isMeasurable: true,
        ));
      }
      
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_habitName),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fon1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _dailyStats.isEmpty
                ? Center(
                    child: Text(
                      l10n.medicationNoStatsData,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : _buildContent(context, l10n),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Сводная статистика
          _buildSummaryCard(context, l10n),
          const SizedBox(height: 16),
          
          // График
          _buildChartCard(context, l10n),
          const SizedBox(height: 16),
          
          // Таблица
          _buildTableCard(context, l10n),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, AppLocalizations l10n) {
    // Для execution: "Запланировано: X", "Выполнено: Y"
    // Для measurable: "Запланировано: X дней", "Выполнено: Y дней"
    final plannedDisplay = widget.habitType == HabitType.execution 
        ? _totalPlanned.toInt().toString()
        : '${_totalPlanned.toInt()} ${_getDaysWord(_totalPlanned.toInt())}';
    final actualDisplay = widget.habitType == HabitType.execution 
        ? _totalActual.toInt().toString()
        : '${_totalActual.toInt()} ${_getDaysWord(_totalActual.toInt())}';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.medicationSummaryTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    l10n.medicationPlannedLabel,
                    plannedDisplay,
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    l10n.habitCompletedLabel,
                    actualDisplay,
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    l10n.medicationAdherenceLabel,
                    '${_adherencePercent.toStringAsFixed(1)}%',
                    Icons.pie_chart,
                    _getAdherenceColor(_adherencePercent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDaysWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'день';
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'дня';
    } else {
      return 'дней';
    }
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildChartCard(BuildContext context, AppLocalizations l10n) {
    // Вычисляем ширину графика: минимум 40 пикселей на день
    final chartWidth = (_dailyStats.length * 40.0).clamp(300.0, double.infinity);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.habitChartTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Легенда
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blue, l10n.medicationPlannedLabel),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.green, l10n.habitCompletedLabel),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: SingleChildScrollView(
                controller: _chartScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  child: _buildBarChart(l10n),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBarChart(AppLocalizations l10n) {
    final displayStats = _dailyStats;
    final maxValue = _getMaxValue(displayStats);
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue + (widget.habitType == HabitType.execution ? 0.5 : maxValue * 0.1),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= displayStats.length) {
                  return const SizedBox();
                }
                final stat = displayStats[value.toInt()];
                // Определяем интервал показа дат
                final showInterval = displayStats.length > 30 
                    ? 5
                    : displayStats.length > 14 
                        ? 3
                        : 2;
                
                if (value.toInt() % showInterval == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd.MM').format(stat.date.toLocal()),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value > maxValue) {
                  return const SizedBox();
                }
                // Для execution показываем только 0 и 1
                if (widget.habitType == HabitType.execution && value != 1) {
                  return const SizedBox();
                }
                return Text(
                  widget.habitType == HabitType.execution 
                      ? value.toInt().toString()
                      : value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 30,
              interval: widget.habitType == HabitType.execution ? 1 : maxValue / 5,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: widget.habitType == HabitType.execution ? 1 : maxValue / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        barGroups: displayStats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: stat.plannedValue,
                color: Colors.blue.withValues(alpha: 0.7),
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: stat.actualValue,
                color: Colors.green.withValues(alpha: 0.7),
                width: 12,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  double _getMaxValue(List<HabitDailyStats> stats) {
    if (stats.isEmpty) return 1;
    if (widget.habitType == HabitType.execution) return 1;
    return stats.map((s) => s.plannedValue).reduce((a, b) => a > b ? a : b);
  }

  Widget _buildTableCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.habitTableTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Заголовок таблицы
            _buildTableHeader(context, l10n),
            const Divider(),
            // Данные таблицы (сортировка по убыванию даты)
            ..._dailyStats.reversed.map((stat) => _buildTableRow(context, l10n, stat)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Дата
          SizedBox(
            width: 80,
            child: Text(
              l10n.medicationDateLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          // План
          Expanded(
            child: Text(
              l10n.medicationPlannedShortLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          // Факт
          Expanded(
            child: Text(
              l10n.habitCompletedLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          // Статус
          Expanded(
            child: Text(
              l10n.medicationStatusLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    AppLocalizations l10n,
    HabitDailyStats stat,
  ) {
    final dateStr = DateFormat('dd.MM.yyyy').format(stat.date.toLocal());
    
    // Форматирование значений
    final plannedStr = stat.isMeasurable 
        ? stat.plannedValue.toStringAsFixed(1)
        : stat.plannedValue.toInt().toString();
    final actualStr = stat.isMeasurable 
        ? stat.actualValue.toStringAsFixed(1)
        : stat.actualValue.toInt().toString();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Дата
          SizedBox(
            width: 80,
            child: Text(
              dateStr,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // План
          Expanded(
            child: Text(
              '$plannedStr${stat.isMeasurable ? " $_unit" : ""}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          // Факт
          Expanded(
            child: Text(
              '$actualStr${stat.isMeasurable ? " $_unit" : ""}',
              style: TextStyle(
                fontSize: 12,
                color: stat.isFullyCompleted
                    ? Colors.green
                    : stat.isPartiallyCompleted
                        ? Colors.orange
                        : stat.plannedValue > 0
                            ? Colors.red
                            : null,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Статус
          Expanded(
            child: _buildStatusIcon(stat),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(HabitDailyStats stat) {
    if (stat.plannedValue <= 0) {
      return const Text('-', textAlign: TextAlign.center);
    }
    
    if (stat.isFullyCompleted) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 20,
      );
    } else if (stat.isPartiallyCompleted) {
      return const Icon(
        Icons.remove_circle,
        color: Colors.orange,
        size: 20,
      );
    } else {
      return const Icon(
        Icons.cancel,
        color: Colors.red,
        size: 20,
      );
    }
  }

  Color _getAdherenceColor(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.red;
  }
}
