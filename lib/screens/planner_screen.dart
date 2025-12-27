// lib/screens/planner_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/models/settings.dart';
import 'package:period_tracker/models/planner_task.dart';
import 'package:period_tracker/utils/date_utils.dart';
import 'planner_task_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late DateTime _selectedDate;
  Settings _settings = const Settings(
    cycleLength: 28,
    periodLength: 5,
    planningMonths: 3,
    locale: 'ru',
    firstDayOfWeek: 'monday',
  );
  List<PlannerTask> _tasks = [];
  bool _isLoading = true;
  static const double _hourBlockHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _selectedDate = MyDateUtils.getUtcToday();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _databaseHelper.getSettings();
      final tasks = await _databaseHelper.getTasksForDate(_selectedDate);
      if (mounted) {
        setState(() {
          _settings = settings;
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToPrevDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadData();
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadData();
  }

  String _formatDate(BuildContext context, DateTime date) {
    final localeTag = Localizations.localeOf(context).toString();
    return DateFormat('dd MMMM yyyy', localeTag).format(date.toLocal());
  }

  int _getStartHour() {
    final parts = _settings.dayStartTime.split(':');
    return int.tryParse(parts[0]) ?? 0;
  }

  int _calculateHourCount() {
    final startParts = _settings.dayStartTime.split(':');
    final endParts = _settings.dayEndTime.split(':');
    final start = int.parse(startParts[0]) + (int.parse(startParts[1]) / 60);
    final end = int.parse(endParts[0]) + (int.parse(endParts[1]) / 60);
    return (end - start).ceil();
  }

  bool _timesOverlap(TimeOfDay start1, TimeOfDay end1, TimeOfDay start2, TimeOfDay end2) {
    final s1 = start1.hour * 60 + start1.minute;
    final e1 = end1.hour * 60 + end1.minute;
    final s2 = start2.hour * 60 + start2.minute;
    final e2 = end2.hour * 60 + end2.minute;
    return s1 < e2 && s2 < e1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plannerTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openTaskScreen(null),
            tooltip: l10n.addTask,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _goToPrevDay,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            _formatDate(context, _selectedDate),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: _goToNextDay,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _calculateHourCount(),
                    itemBuilder: (context, index) {
                      final hourStart = _getStartHour() + index;
                      return _buildHourBlock(context, hourStart);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHourBlock(BuildContext context, int hour) {
    final hourStart = TimeOfDay(hour: hour, minute: 0);
    final hourEnd = TimeOfDay(hour: hour, minute: 60);

    final overlappingTasks = _tasks.where((task) {
      return _timesOverlap(task.startTime, task.endTime, hourStart, hourEnd);
    }).toList();

    overlappingTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
    final count = overlappingTasks.length;

    return SizedBox(
      height: _hourBlockHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0, right: 8.0),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          // Разделительная линия
          Container(
            width: 1,
            color: Colors.grey[300],
          ),
          // Слоты для задач
          if (count == 0)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
              ),
            )
          else
            ..._buildTaskWidgets(context, overlappingTasks, hour, count),
        ],
      ),
    );
  }

  List<Widget> _buildTaskWidgets(
    BuildContext context,
    List<PlannerTask> tasks,
    int currentHour,
    int taskCount,
  ) {
    if (tasks.isEmpty) return [];

    final List<Widget> widgets = [];
    
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];

      // Вычисляем время начала и конца задачи внутри текущего часа
      int taskStartMinute = 0;
      if (task.startTime.hour == currentHour) {
        taskStartMinute = task.startTime.minute;
      }

      int taskEndMinute = 60;
      if (task.endTime.hour == currentHour) {
        taskEndMinute = task.endTime.minute;
      } else if (task.endTime.hour > currentHour) {
        taskEndMinute = 60;
      }

      // Длительность задачи в минутах
      final taskDuration = taskEndMinute - taskStartMinute;

      widgets.add(
        // Равная ширина для всех пересекающихся задач
        Flexible(
          flex: 1, // Все задачи получают равную ширину
          child: Container(
            height: _hourBlockHeight,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            child: Stack(
              children: [
                // Фоновая линия часа
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                  ),
                ),
                // Задача позиционируется пропорционально времени
                Positioned(
                  top: (taskStartMinute / 60) * _hourBlockHeight,
                  left: 0,
                  right: 0,
                  height: (taskDuration / 60) * _hourBlockHeight,
                  child: GestureDetector(
                    onTap: () => _openTaskScreen(task),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (task.description != null && task.description!.isNotEmpty)
                              Text(
                                task.description!,
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            Text(
                              '${task.startTime.format(context)} - ${task.endTime.format(context)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  void _openTaskScreen(PlannerTask? task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlannerTaskScreen(
          date: _selectedDate,
          task: task,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }
}
