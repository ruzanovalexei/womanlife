import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/models/settings.dart';
import 'package:period_tracker/models/planner_task.dart';
import 'package:period_tracker/utils/date_utils.dart';
import 'package:period_tracker/services/ad_banner_service.dart';
import 'planner_task_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _adBannerService = AdBannerService();
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
  static const _backgroundImage = AssetImage('assets/images/fon1.png');

  // Виджет баннера создается один раз и переиспользуется
  Widget? _bannerWidget;

  @override
  void initState() {
    super.initState();
    _selectedDate = MyDateUtils.getUtcToday();
    _initializeScreen();
    _initializeBannerWidget();
  }

  // Оптимизированная инициализация экрана
  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  // Инициализация виджета баннера - создается один раз
  void _initializeBannerWidget() {
    if (_bannerWidget == null) {
      _bannerWidget = _adBannerService.createBannerWidget();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    // Очищаем виджет баннера при уничтожении экрана
    _bannerWidget = null;
    super.dispose();
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

  int _getEndHour() {
    final parts = _settings.dayEndTime.split(':');
    return int.tryParse(parts[0]) ?? 24;
  }

  int _calculateHourCount() {
    return _getEndHour() - _getStartHour();
  }

  /// Преобразуем TimeOfDay в минуты от начала дня
  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Получаем смещение задачи относительно начала рабочего дня
  double _getTaskTopOffset(PlannerTask task) {
    final dayStartMinutes = _getStartHour() * 60;
    final taskStartMinutes = _timeToMinutes(task.startTime);
    final relativeMinutes = taskStartMinutes - dayStartMinutes;
    return (relativeMinutes / 60) * _hourBlockHeight;
  }

  /// Получаем высоту задачи
  double _getTaskHeight(PlannerTask task) {
    final duration = _timeToMinutes(task.endTime) - _timeToMinutes(task.startTime);
    return (duration / 60) * _hourBlockHeight;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalHeight = _calculateHourCount() * _hourBlockHeight;

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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: _backgroundImage,
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Заголовок с датой
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
                        // Основная область с часами и задачами
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Ширина области задач (без колонки времени)
                              final tasksAreaWidth = constraints.maxWidth - 60 - 1;
                              return SingleChildScrollView(
                                child: SizedBox(
                                  height: totalHeight,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Колонка времени
                                      SizedBox(
                                        width: 60,
                                        child: _buildTimeColumn(),
                                      ),
                                      // Разделительная линия
                                      Container(
                                        width: 1,
                                        color: Colors.black,
                                      ),
                                      // Область слотов и задач
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            // Сетка часов
                                            _buildHourGrid(),
                                            // Задачи
                                            ..._buildTaskCards(context, tasksAreaWidth),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            // Блок рекламы - используем созданный один раз виджет
            if (_bannerWidget != null) ...[
              _bannerWidget!,
            ] else ...[
              // Показываем загрузку, если виджет еще не создан
              const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Строит колонку с временем
  Widget _buildTimeColumn() {
    final List<Widget> widgets = [];
    final startHour = _getStartHour();
    final endHour = _getEndHour();

    for (int hour = startHour; hour < endHour; hour++) {
      widgets.add(
        SizedBox(
          height: _hourBlockHeight,
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 8.0),
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(fontSize: 12, color: Colors.black),
              textAlign: TextAlign.end,
            ),
          ),
        ),
      );
    }

    return Column(children: widgets);
  }

  /// Строит сетку часовых линий
  Widget _buildHourGrid() {
    final List<Widget> lines = [];
    final startHour = _getStartHour();
    final endHour = _getEndHour();

    for (int hour = startHour; hour < endHour; hour++) {
      lines.add(
        Positioned(
          left: 0,
          right: 0,
          top: (hour - startHour) * _hourBlockHeight,
          child: Container(
            height: _hourBlockHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black),
                right: BorderSide(color: Colors.black),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: lines);
  }

  /// Строит карточки задач
  List<Widget> _buildTaskCards(BuildContext context, double tasksAreaWidth) {
    final List<Widget> cards = [];
    final startHour = _getStartHour();
    final endHour = _getEndHour();

    // Находим задачи в пределах рабочего дня
    final visibleTasks = _tasks.where((task) {
      final taskEndMinutes = _timeToMinutes(task.endTime);
      final taskStartMinutes = _timeToMinutes(task.startTime);
      final dayEndMinutes = endHour * 60;
      final dayStartMinutes = startHour * 60;
      
      return taskEndMinutes > dayStartMinutes && taskStartMinutes < dayEndMinutes;
    }).toList();

    // Сортируем по времени начала
    visibleTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Находим задачи, которые пересекаются хотя бы с одной другой задачей
    final Set<int> intersectingIds = {};
    for (final task in visibleTasks) {
      final taskStart = _timeToMinutes(task.startTime);
      final taskEnd = _timeToMinutes(task.endTime);

      for (final other in visibleTasks) {
        if (task.id == other.id) continue;
        final otherStart = _timeToMinutes(other.startTime);
        final otherEnd = _timeToMinutes(other.endTime);
        
        if (taskStart < otherEnd && taskEnd > otherStart) {
          intersectingIds.add(task.id!);
          intersectingIds.add(other.id!);
        }
      }
    }

    // Отделяем пересекающиеся задачи от непересекающихся
    final intersectingTasks = visibleTasks.where((t) => intersectingIds.contains(t.id)).toList();
    final nonIntersectingTasks = visibleTasks.where((t) => !intersectingIds.contains(t.id)).toList();

    // Распределяем пересекающиеся задачи по столбцам
    final Map<int, List<PlannerTask>> intersectingColumns = {};
    for (final task in intersectingTasks) {
      final taskStart = _timeToMinutes(task.startTime);
      final taskEnd = _timeToMinutes(task.endTime);
      
      bool placed = false;
      for (final columnId in intersectingColumns.keys) {
        final column = intersectingColumns[columnId]!;
        bool canPlace = true;
        
        for (final existingTask in column) {
          final existingStart = _timeToMinutes(existingTask.startTime);
          final existingEnd = _timeToMinutes(existingTask.endTime);
          
          if (taskStart < existingEnd && taskEnd > existingStart) {
            canPlace = false;
            break;
          }
        }
        
        if (canPlace) {
          column.add(task);
          placed = true;
          break;
        }
      }

      if (!placed) {
        intersectingColumns[intersectingColumns.length] = [task];
      }
    }

    // Обрабатываем пересекающиеся задачи
    for (final column in intersectingColumns.values) {
      final columnCount = intersectingColumns.length;
      final columnWidth = tasksAreaWidth / columnCount;
      final columnIndex = intersectingColumns.keys.toList().indexOf(intersectingColumns.keys.firstWhere((k) => intersectingColumns[k] == column));
      final columnLeft = columnWidth * columnIndex;

      for (final task in column) {
        final taskTop = _getTaskTopOffset(task);
        final taskHeight = _getTaskHeight(task);

        cards.add(
          Positioned(
            top: taskTop,
            left: columnLeft,
            width: columnWidth,
            height: taskHeight,
            child: GestureDetector(
              onTap: () => _openTaskScreen(task),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  border: Border.all(color: Colors.blue, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.description != null && task.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            task.description!,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${task.startTime.format(context)} - ${task.endTime.format(context)}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    // Обрабатываем непересекающиеся задачи (на всю ширину)
    for (final task in nonIntersectingTasks) {
      final taskTop = _getTaskTopOffset(task);
      final taskHeight = _getTaskHeight(task);

      cards.add(
        Positioned(
          top: taskTop,
          left: 0,
          width: tasksAreaWidth,
          height: taskHeight,
          child: GestureDetector(
            onTap: () => _openTaskScreen(task),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                border: Border.all(color: Colors.blue, width: 1.5),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.description != null && task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          task.description!,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${task.startTime.format(context)} - ${task.endTime.format(context)}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return cards;
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