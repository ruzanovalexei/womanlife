import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/models/medication.dart';
import 'package:period_tracker/models/medication_daily_stats.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/utils/date_utils.dart';

class MedicationAnalyticsScreen extends StatefulWidget {
  final Medication medication;

  const MedicationAnalyticsScreen({
    super.key,
    required this.medication,
  });

  @override
  State<MedicationAnalyticsScreen> createState() => _MedicationAnalyticsScreenState();
}

class _MedicationAnalyticsScreenState extends State<MedicationAnalyticsScreen> {
  final _databaseHelper = DatabaseHelper();
  List<MedicationDailyStats> _dailyStats = [];
  bool _isLoading = true;
  
  // Сводная статистика
  int _totalPlanned = 0;
  int _totalTaken = 0;
  double _adherencePercent = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Определяем период
      final startDate = widget.medication.startDate;
      final endDate = widget.medication.endDate ?? DateTime.now();
      
      // Нормализуем даты
      final normalizedStart = MyDateUtils.startOfDayUtc(startDate);
      final normalizedEnd = MyDateUtils.startOfDayUtc(endDate);
      
      // Получаем записи о приеме
      final records = await _databaseHelper.getMedicationTakenRecordsForPeriod(
        widget.medication.id!,
        normalizedStart,
        normalizedEnd,
      );
      
      // Группируем записи по датам
      final Map<DateTime, List<dynamic>> recordsByDate = {};
      for (final record in records) {
        final dateKey = MyDateUtils.startOfDayUtc(record.date);
        recordsByDate.putIfAbsent(dateKey, () => []).add(record);
      }
      
      // Создаем статистику для каждого дня в периоде
      final List<MedicationDailyStats> stats = [];
      final plannedPerDay = widget.medication.times.length; // Количество запланированных приемов в день
      
      // Проходим по каждому дню в периоде
      var currentDate = normalizedStart;
      while (!currentDate.isAfter(normalizedEnd)) {
        final dayRecords = recordsByDate[currentDate] ?? [];
        final takenCount = dayRecords.where((r) => r.isTaken).length;
        
        stats.add(MedicationDailyStats(
          date: currentDate,
          plannedCount: plannedPerDay,
          takenCount: takenCount,
        ));
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      if (mounted) {
        setState(() {
          _dailyStats = stats;
          _isLoading = false;
          
          // Вычисляем сводную статистику
          _totalPlanned = stats.fold(0, (sum, s) => sum + s.plannedCount);
          _totalTaken = stats.fold(0, (sum, s) => sum + s.takenCount);
          _adherencePercent = _totalPlanned > 0 
              ? (_totalTaken / _totalPlanned * 100).clamp(0, 100) 
              : 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading medication stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication.name),
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
                    '$_totalPlanned',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    l10n.medicationTakenLabel,
                    '$_totalTaken',
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.medicationChartTitle,
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
                _buildLegendItem(Colors.green, l10n.medicationTakenLabel),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _buildBarChart(l10n),
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
    // Ограничиваем количество отображаемых дней для читаемости
    final displayStats = _dailyStats.length > 14 
        ? _dailyStats.sublist(_dailyStats.length - 14) 
        : _dailyStats;
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxValue(displayStats).toDouble() + 1,
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
                // Показываем дату через день для экономии места
                if (value.toInt() % 2 == 0) {
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
                if (value == 0 || value > _getMaxValue(displayStats)) {
                  return const SizedBox();
                }
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 30,
              interval: 1,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
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
                toY: stat.plannedCount.toDouble(),
                color: Colors.blue.withValues(alpha: 0.7),
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: stat.takenCount.toDouble(),
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

  int _getMaxValue(List<MedicationDailyStats> stats) {
    if (stats.isEmpty) return 1;
    return stats.map((s) => s.plannedCount).reduce((a, b) => a > b ? a : b);
  }

  Widget _buildTableCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.medicationTableTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Заголовок таблицы
            _buildTableHeader(context, l10n),
            const Divider(),
            // Данные таблицы
            ..._dailyStats.map((stat) => _buildTableRow(context, l10n, stat)),
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
          // Дата - ширина как у данных
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
              l10n.medicationTakenShortLabel,
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
    MedicationDailyStats stat,
  ) {
    final dateStr = DateFormat('dd.MM.yyyy').format(stat.date.toLocal());
    
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
          // Дата - фиксированная ширина
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
              '${stat.plannedCount}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          // Факт
          Expanded(
            child: Text(
              '${stat.takenCount}',
              style: TextStyle(
                fontSize: 12,
                color: stat.isFullyCompleted
                    ? Colors.green
                    : stat.isPartiallyCompleted
                        ? Colors.orange
                        : stat.plannedCount > 0
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

  Widget _buildStatusIcon(MedicationDailyStats stat) {
    if (stat.plannedCount == 0) {
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
