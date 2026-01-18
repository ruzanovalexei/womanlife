import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/models/day_note.dart';
import 'package:period_tracker/models/period_record.dart';
import 'package:period_tracker/models/settings.dart';
import 'package:period_tracker/models/medication.dart';
import 'package:period_tracker/models/medication_taken_record.dart';
import 'package:period_tracker/models/habit_execution.dart';
import 'package:period_tracker/models/habit_measurable.dart';
import 'package:period_tracker/models/habit_execution_record.dart';
import 'package:period_tracker/models/habit_measurable_record.dart';
import 'package:period_tracker/models/frequency_type.dart';
import 'package:period_tracker/models/list_model.dart';
import 'package:period_tracker/models/list_item_model.dart';
import 'package:period_tracker/models/note_model.dart';
import 'package:period_tracker/models/planner_task.dart';
import 'package:period_tracker/utils/date_utils.dart';
import 'package:period_tracker/utils/period_calculator.dart';
import 'package:period_tracker/services/ad_banner_service.dart';
// import 'menu_screen.dart';

class DayReportScreen extends StatefulWidget {
  const DayReportScreen({super.key});

  @override
  _DayReportScreenState createState() => _DayReportScreenState();
}

// ... остальной код ...
class _DayReportScreenState extends State<DayReportScreen> {
  final _databaseHelper = DatabaseHelper();
  final _adBannerService = AdBannerService();
  
  late DateTime _selectedDate;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Виджет баннера создается один раз и переиспользуется
  Widget? _bannerWidget;
  
  // Данные для отчета
  DayNote? _dayNote;
  Settings? _settings;
  List<PeriodRecord> _periodRecords = [];
  List<Medication> _allMedications = [];
  List<MedicationTakenRecord> _medicationRecords = [];
  List<HabitExecution> _executionHabits = [];
  List<HabitMeasurable> _measurableHabits = [];
  List<HabitExecutionRecord> _executionRecords = [];
  List<HabitMeasurableRecord> _measurableRecords = [];
  Map<int, FrequencyType> _frequencyTypesMap = {};
  List<ListModel> _lists = [];
  List<NoteModel> _allNotes = [];
  List<PlannerTask> _plannerTasks = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = MyDateUtils.getUtcToday();
    _initializeScreen();
    _initializeBannerWidget();
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

  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Параллельная загрузка всех данных
      final results = await Future.wait([
        _databaseHelper.getDayNote(_selectedDate),
        _databaseHelper.getSettings(),
        _databaseHelper.getAllPeriodRecords(),
        _databaseHelper.getAllMedications(),
        _databaseHelper.getMedicationTakenRecordsForDay(_selectedDate),
        _databaseHelper.getAllHabitExecutions(),
        _databaseHelper.getAllHabitMeasurables(),
        _databaseHelper.getHabitExecutionRecordsForDate(_selectedDate),
        _databaseHelper.getHabitMeasurableRecordsForDate(_selectedDate),
        _databaseHelper.getAllFrequencyTypes(),
        _databaseHelper.getAllLists(),
        _databaseHelper.getAllNotes(),
        _databaseHelper.getTasksForDate(_selectedDate),
      ]);

      // Создаем карту FrequencyType
      final allFrequencyTypes = results[9] as List<FrequencyType>;
      final frequencyTypesMap = <int, FrequencyType>{};
      for (final frequencyType in allFrequencyTypes) {
        if (frequencyType.id != null) {
          frequencyTypesMap[frequencyType.id!] = frequencyType;
        }
      }

      if (mounted) {
        setState(() {
          _dayNote = results[0] as DayNote?;
          _settings = results[1] as Settings;
          _periodRecords = results[2] as List<PeriodRecord>;
          _allMedications = results[3] as List<Medication>;
          _medicationRecords = results[4] as List<MedicationTakenRecord>;
          _executionHabits = results[5] as List<HabitExecution>;
          _measurableHabits = results[6] as List<HabitMeasurable>;
          _executionRecords = results[7] as List<HabitExecutionRecord>;
          _measurableRecords = results[8] as List<HabitMeasurableRecord>;
          _frequencyTypesMap = frequencyTypesMap;
          _lists = results[10] as List<ListModel>;
          _allNotes = results[11] as List<NoteModel>;
          _plannerTasks = results[12] as List<PlannerTask>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final localeTag = Localizations.localeOf(context).toString();
    return DateFormat('dd.MM.yyyy', localeTag).format(date);
  }

  // Переключить на предыдущий день
  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadData();
  }

  // Переключить на следующий день
  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadData();
  }

  // Получить заметки за выбранный день
  List<NoteModel> _getNotesForSelectedDate() {
    return _allNotes.where((note) {
      final noteDate = DateTime(note.createdDate.year, note.createdDate.month, note.createdDate.day);
      final selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      return noteDate.isAtSameMomentAs(selectedDate);
    }).toList();
  }

  // Получить активные списки задач (не завершенные) с невыполненными задачами
  Future<List<ListWithProgressAndItems>> _getActiveListsWithProgress() async {
    final activeLists = <ListWithProgressAndItems>[];
    
    for (final list in _lists) {
      final progress = await _databaseHelper.getListProgress(list.id!);
      final total = progress['total']!;
      final completed = progress['completed']!;
      
      // Показываем только не завершенные списки
      if (total > 0 && completed < total) {
        // Получаем все элементы списка
        final allItems = await _databaseHelper.getListItemsByListId(list.id!);
        
        // Фильтруем только невыполненные задачи
        final incompleteItems = allItems.where((item) => !item.isCompleted).toList();
        
        activeLists.add(ListWithProgressAndItems(
          list: list,
          total: total,
          completed: completed,
          incompleteItems: incompleteItems,
        ));
      }
    }
    
    return activeLists;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Обычная навигация назад вместо полной замены стека
          },
        ),
        title: Text(l10n.dayReportTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: l10n.refreshTooltip,
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            // Основной контент
            Expanded(
              child: _buildMainContent(l10n),
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

  Widget _buildMainContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorWidget(l10n);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Divider(
            color: Colors.black,
            thickness: 2,
            height: 2,
          ),
          const SizedBox(height: 8),

          // Заголовок с датой
          _buildDateHeader(l10n),
          const SizedBox(height: 8),
          // Толстая черная линия под заголовком
          const Divider(
            color: Colors.black,
            thickness: 2,
            height: 2,
          ),
          const SizedBox(height: 16),

          // --- Задачи на сегодня ---
          ..._generatePlannerTasksReport(l10n),
          const SizedBox(height: 16),
          // Тонкая серая линия
          const Divider(
            color: Colors.grey,
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 16),

          // --- Лекарства ---
          const Text(
            'Лекарства',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ..._generateMedicationsReport(l10n),
          const SizedBox(height: 16),
          // Тонкая серая линия
          const Divider(
            color: Colors.grey,
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 16),

          // --- Привычки ---
          const Text(
            'Привычки',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ..._generateHabitsReport(l10n),
          const SizedBox(height: 16),
          // Тонкая серая линия
          const Divider(
            color: Colors.grey,
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 16),

          // --- Активные списки задач ---
          // Отображаем только на текущую дату и в будущем
          if (!_isDateInPast(_selectedDate)) ...[
            const Text(
              'Активные списки задач',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<ListWithProgressAndItems>>(
              future: _getActiveListsWithProgress(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Загрузка списков задач...');
                }
                if (snapshot.hasError) {
                  return Text('Ошибка загрузки списков задач: ${snapshot.error}');
                }
                
                final activeLists = snapshot.data!;
                if (activeLists.isEmpty) {
                  return const Text('Нет активных списков задач', style: TextStyle(color: Colors.grey));
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: activeLists.map((listWithItems) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // '• ${listWithItems.list.name}: ${listWithItems.completed}/${listWithItems.total} выполнено',
                          '• ${listWithItems.list.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // Показываем невыполненные задачи с отступом
                        ...listWithItems.incompleteItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 16, top: 2),
                            child: Text(
                              '  - ${item.text}',
                              style: const TextStyle(color: Color(0xFF212121)),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            // Тонкая серая линия
            const Divider(
              color: Colors.grey,
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 16),
          ],

          // --- Информация о месячных ---
          const Text(
            'Информация о месячных',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ..._generatePeriodInfoReport(l10n),
          const SizedBox(height: 16),
          // Тонкая серая линия
          const Divider(
            color: Colors.grey,
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 16),

          // --- Информация о сексе ---
          if (_dayNote?.hadSex == true) ...[
            const Text(
              'Секс',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            ..._generateSexReport(l10n),
            const SizedBox(height: 16),
            // Тонкая серая линия
            const Divider(
              color: Colors.grey,
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 16),
          ],

          // --- Симптомы ---
          if (_dayNote?.symptoms.isNotEmpty == true) ...[
            const Text(
              'Симптомы',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            ..._generateSymptomsReport(l10n),
            const SizedBox(height: 16),
            // Тонкая серая линия
            const Divider(
              color: Colors.grey,
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 16),
          ],

          // --- Заметки ---
          Text(
            'Заметки (${_getNotesForSelectedDate().length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ..._generateNotesReport(l10n),
        ],
      ),
    );
  }

  Widget _buildDateHeader(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: _goToPreviousDay,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Предыдущий день',
            ),
            
            Expanded(
              child: Center(
                child: Text(
                  _formatDate(context, _selectedDate),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            IconButton(
              onPressed: _goToNextDay,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Следующий день',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Ошибка: $_errorMessage',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  // --- Новые методы для генерации чисто текстового контента ---

  List<Widget> _generateMedicationsReport(AppLocalizations l10n) {
    final activeMedications = _allMedications.where((med) => _isMedicationActiveOnDate(med, _selectedDate)).toList();
    List<MedicationEvent> medicationEvents = [];
    for (var medication in activeMedications) {
      for (var timeOfDay in medication.times) {
        final scheduledDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );
        final takenRecord = _medicationRecords.firstWhere(
          (record) =>
              record.medicationId == medication.id &&
              record.scheduledTime.hour == timeOfDay.hour &&
              record.scheduledTime.minute == timeOfDay.minute,
          orElse: () => MedicationTakenRecord(
            medicationId: medication.id!,
            date: _selectedDate,
            scheduledTime: TimeOfDay(hour: timeOfDay.hour, minute: timeOfDay.minute),
            isTaken: false,
          ),
        );
        medicationEvents.add(MedicationEvent(
          name: medication.name,
          scheduledTime: scheduledDateTime,
          medicationId: medication.id!,
          isTaken: takenRecord.isTaken,
          actualTakenTime: takenRecord.actualTakenTime,
        ));
      }
    }
    medicationEvents.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    if (medicationEvents.isEmpty) {
      return [const Text('На выбранный день лекарства не запланированы', style: TextStyle(color: Colors.grey))];
    }
    return medicationEvents.map<Widget>((event) {
      final color = event.isTaken ? const Color(0xFF7E57C2) : const Color(0xFF212121);
      return Text(
        '• ${event.name} (${TimeOfDay.fromDateTime(event.scheduledTime).format(context)}) - ${event.isTaken ? "Принято" : "Не принято"}${event.isTaken && event.actualTakenTime != null ? " в ${DateFormat('HH:mm').format(event.actualTakenTime!.toLocal())}" : ""}',
        style: TextStyle(color: color),
      );
    }).toList();
  }

  List<Widget> _generateHabitsReport(AppLocalizations l10n) {
    final habitReports = <HabitReport>[];
    for (final habit in _executionHabits) {
      if (!_shouldExecuteHabitOnDate(habit, _selectedDate)) continue;
      final record = _executionRecords.firstWhere(
        (r) => r.habitId == habit.id,
        orElse: () => HabitExecutionRecord(
          habitId: habit.id!,
          isCompleted: false,
          executionDate: _selectedDate,
          createdAt: DateTime.now(),
        ),
      );
      habitReports.add(HabitReport(
        name: habit.name,
        type: 'execution',
        isCompleted: record.isCompleted,
        planned: true, 
        actual: record.isCompleted,
      ));
    }
    for (final habit in _measurableHabits) {
      if (!_shouldExecuteMeasurableHabitOnDate(habit, _selectedDate)) continue;
      final record = _measurableRecords.firstWhere(
        (r) => r.habitId == habit.id,
        orElse: () => HabitMeasurableRecord(
          habitId: habit.id!,
          isCompleted: false,
          executionDate: _selectedDate,
          createdAt: DateTime.now(),
        ),
      );
      habitReports.add(HabitReport(
        name: habit.name,
        type: 'measurable',
        isCompleted: record.isCompleted,
        planned: true, 
        actual: record.isCompleted,
        goal: habit.goal,
        unit: habit.unit,
        actualValue: record.actualValue,
      ));
    }
    if (habitReports.isEmpty) {
      return [const Text('На выбранный день привычки не запланированы', style: TextStyle(color: Colors.grey))];
    }
    return habitReports.map<Widget>((report) {
      String habitText = '• ${report.name}: ${report.actual ? "Выполнено" : "Не выполнено"}';
      if (report.type == 'measurable' && report.goal != null) {
        habitText += ', Цель: ${report.goal} ${report.unit ?? ''}';
        if (report.actualValue != null) {
          habitText += ', Факт: ${report.actualValue} ${report.unit ?? ''}';
        }
      }
      final color = report.actual ? const Color(0xFF7E57C2) : const Color(0xFF212121);
      return Text(habitText, style: TextStyle(color: color));
    }).toList();
  }

  List<Widget> _generatePeriodInfoReport(AppLocalizations l10n) {
    if (_settings == null) return [const SizedBox.shrink()];
    
    final isOvulationDay = PeriodCalculator.isOvulationDay(_selectedDate, _settings!, _periodRecords);
    final isFertileDay = PeriodCalculator.isFertileDay(_selectedDate, _settings!, _periodRecords);
    
    List<Widget> periodInfoTexts = [];
    
    // Следующие плановые месячные
    if (_periodRecords.isEmpty || _settings == null) {
      periodInfoTexts.add(const Text('Нет данных о плановых периодах', style: TextStyle(color: Colors.grey)));
    } else {
      final plannedPeriods = PeriodCalculator.calculatePlannedPeriods(_settings!, _periodRecords);
      final sortedActualPeriods = List<PeriodRecord>.from(_periodRecords)
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      
      if (sortedActualPeriods.isEmpty) {
        periodInfoTexts.add(const SizedBox.shrink());
      } else {
        final lastActualPeriod = sortedActualPeriods.first;
        final nextPlannedPeriods = plannedPeriods.where((plannedPeriod) {
          final daysDifference = plannedPeriod.startDate.difference(lastActualPeriod.startDate).inDays;
          return daysDifference > 14;
        }).take(1).toList();
        
        if (nextPlannedPeriods.isEmpty) {
          periodInfoTexts.add(const Text('Следующие плановые месячные не рассчитаны', style: TextStyle(color: Color(0xFF212121))));
        } else {
          final nextPeriod = nextPlannedPeriods.first;
          final daysUntil = nextPeriod.startDate.difference(_selectedDate).inDays;
          
          periodInfoTexts.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Следующие плановые месячные:'),
                Text('${_formatDate(context, nextPeriod.startDate)} - ${_formatDate(context, nextPeriod.endDate)}'),
                Text(
                  daysUntil > 0 
                      ? 'Через $daysUntil дн.'
                      : daysUntil == 0 
                          ? 'Начинаются сегодня'
                          : 'Задержка: ${-daysUntil} дн.',
                  style: TextStyle(
                    color: daysUntil < 0 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            )
          );
        }
      }
    }

    if (isOvulationDay) {
      periodInfoTexts.add(const Text('• Идеальное время для зачатия', style: TextStyle(color: Colors.green)));
    }
    
    if (isFertileDay && !isOvulationDay) {
      periodInfoTexts.add(const Text('• Благоприятные дни для зачатия', style: TextStyle(color: Colors.lightGreen)));
    }

    if (periodInfoTexts.isEmpty) {
      return [const Text('Нет информации о месячных за этот день', style: TextStyle(color: Colors.grey))];
    }
    
    return periodInfoTexts;
  }

  List<Widget> _generateSexReport(AppLocalizations l10n) {
    if (_dayNote == null) return [const SizedBox.shrink()];

    List<Widget> sexInfoTexts = [];
    if (_dayNote!.hadSex != null) {
      sexInfoTexts.add(Text('• Секс: ${_dayNote!.hadSex! ? 'Был' : 'Не был'}'));
    }
    if (_dayNote!.isSafeSex != null) {
      sexInfoTexts.add(Text('• Безопасный: ${_dayNote!.isSafeSex! ? 'Да' : 'Нет'}'));
    }
    if (_dayNote!.hadOrgasm != null) {
      sexInfoTexts.add(Text('• Оргазм: ${_dayNote!.hadOrgasm! ? 'Да' : 'Нет'}'));
    }
    return sexInfoTexts;
  }

  List<Widget> _generateSymptomsReport(AppLocalizations l10n) {
    if (_dayNote == null || _dayNote!.symptoms.isEmpty) {
      return [const Text('Симптомов не отмечено', style: TextStyle(color: Colors.grey))];
    }
    return _dayNote!.symptoms.map<Widget>((symptom) {
      return Text('• $symptom');
    }).toList();
  }

  List<Widget> _generateNotesReport(AppLocalizations l10n) {
    final dayNotes = _getNotesForSelectedDate();
    if (dayNotes.isEmpty) {
      return [const Text('Заметок за этот день нет', style: TextStyle(color: Colors.grey))];
    }
    return dayNotes.map<Widget>((note) {
      return Text('• ${note.title}: ${_truncateText(note.content, 2)}');
    }).toList();
  }

  List<Widget> _generatePlannerTasksReport(AppLocalizations l10n) {
    if (_plannerTasks.isEmpty) {
      return [
        const Text(
          'Задачи на сегодня',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text('Нет запланированных задач', style: TextStyle(color: Colors.grey)),
      ];
    }

    // Сортируем задачи по времени начала (уже отсортировано в БД, но на всякий случай)
    final sortedTasks = List<PlannerTask>.from(_plannerTasks)
      ..sort((a, b) {
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });

    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;

    // Проверяем, является ли выбранная дата прошедшей
    final isSelectedDateInPast = _isDateInPast(_selectedDate);

    final taskWidgets = <Widget>[
      const Text(
        'Задачи на сегодня',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      const SizedBox(height: 8),
    ];

    for (final task in sortedTasks) {
      // Вычисляем время окончания задачи в минутах от начала дня
      final endTimeInMinutes = task.endTime.hour * 60 + task.endTime.minute;
      
      // Определяем цвет задачи:
      // 1. Если дата в прошлом - все задачи серые
      // 2. Если дата сегодня - серый только если время окончания прошло
      // 3. Если дата в будущем - все задачи черные
      Color textColor;

      if (isSelectedDateInPast) {
        // Прошедшая дата - все задачи серые
        textColor = const Color(0xFF757575);
      } else {
        // Текущая или будущая дата - используем логику по времени
        final isPast = endTimeInMinutes < currentTimeInMinutes;
        textColor = isPast ? const Color(0xFF757575) : const Color(0xFF212121);
      }

      final startTimeStr = task.startTime.format(context);
      final endTimeStr = task.endTime.format(context);

      taskWidgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$startTimeStr - $endTimeStr',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
      );
    }

    return taskWidgets;
  }

  String _truncateText(String text, int maxLines) {
    // final words = text.split(' ');
    final maxChars = maxLines * 50; // примерно 50 символов на строку
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}...';
  }

  // Вспомогательные методы для проверки активности лекарств и привычек
  bool _isMedicationActiveOnDate(Medication medication, DateTime date) {
    final startDate = medication.startDate; 
    final endDate = medication.endDate;
    
    return (date.isAfter(startDate.subtract(const Duration(days: 1))) || date.isAtSameMomentAs(startDate)) && 
           (endDate == null || date.isBefore(endDate.add(const Duration(days: 1))) || date.isAtSameMomentAs(endDate));
  }

  // Получить начало недели (понедельник)
  DateTime _getWeekStart(DateTime date) {
    final dayOfWeek = date.weekday;
    return date.subtract(Duration(days: dayOfWeek - 1));
  }

  // Проверка, должна ли привычка типа выполнение выполняться в конкретный день на основе частоты
  bool _shouldExecuteHabitOnDate(HabitExecution habit, DateTime date) {
    final frequencyType = _frequencyTypesMap[habit.frequencyId];
    if (frequencyType == null) return false;

    // Проверяем, активна ли привычка в этот день по датам начала/окончания
    if (!habit.isActiveOn(date)) return false;

    final dayOfWeek = date.weekday; // 1 = понедельник, 7 = воскресенье
    final daysFromStart = date.difference(habit.startDate).inDays;

    switch (frequencyType.type) {
      case 1: // Каждый день
        return true;
      case 2: // Каждый X день
        final interval = frequencyType.intervalValue ?? 2;
        return daysFromStart >= 0 && daysFromStart % interval == 0;
      case 3: // Дни недели
        final selectedDays = frequencyType.selectedDaysOfWeek ?? [];
        return selectedDays.contains(dayOfWeek);
      case 4: // X раз в неделю
        final timesPerWeek = frequencyType.intervalValue ?? 3;
        // Простая логика: если это один из первых дней недели с учетом количества раз
        final weekStart = _getWeekStart(date);
        final daysFromWeekStart = date.difference(weekStart).inDays;
        return daysFromWeekStart < timesPerWeek;
      default:
        return false;
    }
  }

  // Проверка, должна ли измеримая привычка выполняться в конкретный день на основе частоты
  bool _shouldExecuteMeasurableHabitOnDate(HabitMeasurable habit, DateTime date) {
    final frequencyType = _frequencyTypesMap[habit.frequencyId];
    if (frequencyType == null) return false;

    // Проверяем, активна ли привычка в этот день по датам начала/окончания
    if (!habit.isActiveOn(date)) return false;

    final dayOfWeek = date.weekday; // 1 = понедельник, 7 = воскресенье
    final daysFromStart = date.difference(habit.startDate).inDays;

    switch (frequencyType.type) {
      case 1: // Каждый день
        return true;
      case 2: // Каждый X день
        final interval = frequencyType.intervalValue ?? 2;
        return daysFromStart >= 0 && daysFromStart % interval == 0;
      case 3: // Дни недели
        final selectedDays = frequencyType.selectedDaysOfWeek ?? [];
        return selectedDays.contains(dayOfWeek);
      case 4: // X раз в неделю
        final timesPerWeek = frequencyType.intervalValue ?? 3;
        // Простая логика: если это один из первых дней недели с учетом количества раз
        final weekStart = _getWeekStart(date);
        final daysFromWeekStart = date.difference(weekStart).inDays;
        return daysFromWeekStart < timesPerWeek;
      default:
        return false;
    }
  }

  // Проверяет, является ли дата прошедшей (меньше текущей даты)
  bool _isDateInPast(DateTime date) {
    final today = MyDateUtils.getUtcToday();
    return date.isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  void dispose() {
    // Очищаем виджет баннера при уничтожении экрана
    _bannerWidget = null;
    super.dispose();
  }
}

// Вспомогательные классы для отчета
class MedicationEvent {
  final String name;
  final DateTime scheduledTime;
  final int medicationId;
  final bool isTaken;
  final DateTime? actualTakenTime;

  MedicationEvent({
    required this.name,
    required this.scheduledTime,
    required this.medicationId,
    required this.isTaken,
    this.actualTakenTime,
  });
}

class HabitReport {
  final String name;
  final String type;
  final bool isCompleted;
  final bool planned;
  final bool actual;
  final double? goal;
  final String? unit;
  final double? actualValue;

  HabitReport({
    required this.name,
    required this.type,
    required this.isCompleted,
    required this.planned,
    required this.actual,
    this.goal,
    this.unit,
    this.actualValue,
  });
}

class ListWithProgress {
  final ListModel list;
  final int total;
  final int completed;

  ListWithProgress({
    required this.list,
    required this.total,
    required this.completed,
  });
}

class ListWithProgressAndItems {
  final ListModel list;
  final int total;
  final int completed;
  final List<ListItemModel> incompleteItems;

  ListWithProgressAndItems({
    required this.list,
    required this.total,
    required this.completed,
    required this.incompleteItems,
  });
}