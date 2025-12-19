import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import '../database/database_helper.dart';
import '../models/habit_execution.dart';
import '../models/habit_measurable.dart';
import '../models/frequency_type.dart';
import '../models/habit_execution_record.dart';
import '../models/habit_measurable_record.dart';
import '../utils/date_utils.dart';
import 'habits_settings_screen.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  _HabitsScreenState createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _databaseHelper = DatabaseHelper();
  late DateTime _selectedDate;
  
  List<HabitExecution> _executionHabits = [];
  List<HabitMeasurable> _measurableHabits = [];
  // List<FrequencyType> _frequencyTypes = [];
  Map<int, FrequencyType> _frequencyTypesMap = {};
  
  Map<int, HabitExecutionRecord> _executionRecords = {};
  Map<int, HabitMeasurableRecord> _measurableRecords = {};
  
  bool _isLoading = true;
  String? _errorMessage;

  // Реклама
  late BannerAd banner;
  var isBannerAlreadyCreated = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = MyDateUtils.getUtcToday();
    _initializeScreen();
  }

  // Оптимизированная инициализация экрана
  void _initializeScreen() {
    _createAdBanner();
    _loadData();
  }

  // Создание баннера
  BannerAd _createBanner() {
    final screenWidth = MediaQuery.of(context).size.width.round();
    final adSize = BannerAdSize.sticky(width: screenWidth);
    
    return BannerAd(
      adUnitId: 'R-M-17946414-4',
      adSize: adSize,
      adRequest: const AdRequest(),
      onAdLoaded: () {
        if (mounted) {
          setState(() {}); // Обновляем только для показа баннера
        }
      },
      onAdFailedToLoad: (error) {
        debugPrint('Ad failed to load: $error');
      },
      onAdClicked: () {},
      onLeftApplication: () {},
      onReturnedToApplication: () {},
      onImpression: (impressionData) {}
    );
  }

  // Оптимизированное создание баннера
  void _createAdBanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !isBannerAlreadyCreated) {
        try {
          banner = _createBanner();
          setState(() {
            isBannerAlreadyCreated = true;
          });
        } catch (e) {
          debugPrint('Banner creation failed: $e');
        }
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Загружаем все привычки
      final executionHabits = await _databaseHelper.getAllHabitExecutions();
      final measurableHabits = await _databaseHelper.getAllHabitMeasurables();
      final allFrequencyTypes = await _databaseHelper.getAllFrequencyTypes();
      
      // Создаем карту FrequencyType
      final frequencyTypesMap = <int, FrequencyType>{};
      for (final frequencyType in allFrequencyTypes) {
        if (frequencyType.id != null) {
          frequencyTypesMap[frequencyType.id!] = frequencyType;
        }
      }
      
      // Загружаем записи выполнения для выбранной даты
      final executionRecords = await _databaseHelper.getHabitExecutionRecordsForDate(_selectedDate);
      final measurableRecords = await _databaseHelper.getHabitMeasurableRecordsForDate(_selectedDate);
      
      // Создаем карты записей
      final executionRecordsMap = <int, HabitExecutionRecord>{};
      for (final record in executionRecords) {
        executionRecordsMap[record.habitId] = record;
      }
      
      final measurableRecordsMap = <int, HabitMeasurableRecord>{};
      for (final record in measurableRecords) {
        measurableRecordsMap[record.habitId] = record;
      }

      setState(() {
        _executionHabits = executionHabits;
        _measurableHabits = measurableHabits;
        // _frequencyTypes = allFrequencyTypes;
        _frequencyTypesMap = frequencyTypesMap;
        _executionRecords = executionRecordsMap;
        _measurableRecords = measurableRecordsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Проверка, должна ли привычка выполняться в конкретный день на основе частоты
  bool _shouldExecuteOnDate(HabitExecution habit, DateTime date) {
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

  bool _shouldExecuteOnDateMeasurable(HabitMeasurable habit, DateTime date) {
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

  // Получить начало недели (понедельник)
  DateTime _getWeekStart(DateTime date) {
    final dayOfWeek = date.weekday;
    return date.subtract(Duration(days: dayOfWeek - 1));
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

  String _formatDate(BuildContext context, DateTime date) {
    final localeTag = Localizations.localeOf(context).toString();
    return DateFormat('dd.MM.yyyy', localeTag).format(date);
  }

  // Переключить выполнение привычки типа выполнение
  Future<void> _toggleExecutionHabit(HabitExecution habit, bool isCompleted) async {
    try {
      final existingRecord = _executionRecords[habit.id];
      final now = DateTime.now();

      if (isCompleted) {
        // Создаем новую запись или обновляем существующую
        final newRecord = existingRecord?.copyWith(
          isCompleted: true,
          createdAt: now,
        ) ?? HabitExecutionRecord(
          habitId: habit.id!,
          isCompleted: true,
          executionDate: _selectedDate,
          createdAt: now,
        );

        if (existingRecord == null) {
          await _databaseHelper.insertHabitExecutionRecord(newRecord);
        } else {
          await _databaseHelper.updateHabitExecutionRecord(newRecord);
        }
      } else {
        // Обновляем существующую запись
        if (existingRecord != null) {
          final updatedRecord = existingRecord.copyWith(isCompleted: false);
          await _databaseHelper.updateHabitExecutionRecord(updatedRecord);
        }
      }

      // Обновляем локальное состояние
      setState(() {
        if (isCompleted) {
          _executionRecords[habit.id!] = existingRecord?.copyWith(
            isCompleted: true,
            createdAt: now,
          ) ?? HabitExecutionRecord(
            habitId: habit.id!,
            isCompleted: true,
            executionDate: _selectedDate,
            createdAt: now,
          );
        } else {
          if (existingRecord != null) {
            _executionRecords[habit.id!] = existingRecord.copyWith(isCompleted: false);
          }
        }
      });
    } catch (e) {
      _showErrorSnackBar('Ошибка при обновлении привычки: $e');
    }
  }

  // Переключить выполнение измеримой привычки
  Future<void> _toggleMeasurableHabit(HabitMeasurable habit, bool isCompleted) async {
    try {
      if (isCompleted) {
        // Показываем диалог для ввода значения
        final result = await _showMeasurableValueDialog(habit);
        if (result != null) {
          await _saveMeasurableRecord(habit, true, result);
        } else {
          // Пользователь отменил ввод, возвращаем чекбокс в исходное состояние
          setState(() {});
        }
      } else {
        // Снимаем галочку
        await _saveMeasurableRecord(habit, false, null);
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка при обновлении привычки: $e');
    }
  }

  Future<double?> _showMeasurableValueDialog(HabitMeasurable habit) async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Введите результат для "${habit.name}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Цель: ${habit.goal} ${habit.unit}'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Фактическое значение (${habit.unit})',
                  hintText: 'Введите значение',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null) {
                  Navigator.pop(context, value);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Введите корректное числовое значение'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('ОК'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveMeasurableRecord(HabitMeasurable habit, bool isCompleted, double? value) async {
    final existingRecord = _measurableRecords[habit.id];
    final now = DateTime.now();

    if (isCompleted) {
      // Создаем новую запись или обновляем существующую
      final newRecord = existingRecord?.copyWith(
        isCompleted: true,
        actualValue: value,
        createdAt: now,
      ) ?? HabitMeasurableRecord(
        habitId: habit.id!,
        isCompleted: true,
        actualValue: value,
        executionDate: _selectedDate,
        createdAt: now,
      );

      if (existingRecord == null) {
        await _databaseHelper.insertHabitMeasurableRecord(newRecord);
      } else {
        await _databaseHelper.updateHabitMeasurableRecord(newRecord);
      }
    } else {
      // Обновляем существующую запись
      if (existingRecord != null) {
        final updatedRecord = existingRecord.copyWith(
          isCompleted: false,
          actualValue: null,
        );
        await _databaseHelper.updateHabitMeasurableRecord(updatedRecord);
      }
    }

    // Обновляем локальное состояние
    setState(() {
      if (isCompleted) {
        _measurableRecords[habit.id!] = existingRecord?.copyWith(
          isCompleted: true,
          actualValue: value,
          createdAt: now,
        ) ?? HabitMeasurableRecord(
          habitId: habit.id!,
          isCompleted: true,
          actualValue: value,
          executionDate: _selectedDate,
          createdAt: now,
        );
      } else {
        if (existingRecord != null) {
          _measurableRecords[habit.id!] = existingRecord.copyWith(
            isCompleted: false,
            actualValue: null,
          );
        }
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Вынесенный основной контент
  Widget _buildMainContent(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Навигация по датам
          _buildDateNavigation(),
          const SizedBox(height: 8),
          
          // Основной контент с привычками
          Expanded(
            child: _buildContent(),
          ),
          
          // Кнопка для перехода к экрану настроек привычек
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HabitsSettingsScreen(),
                  ),
                );
                
                // Если были изменения в привычках, перезагружаем данные
                if (result == true) {
                  await _loadData();
                }
              },
              icon: const Icon(Icons.settings),
              label: const Text('Настройки привычек'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Вынесенный виджет баннера
  Widget _buildBannerWidget() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 8),
      height: isBannerAlreadyCreated ? 60 : 0, // Фиксированная высота
      child: isBannerAlreadyCreated 
               ? IgnorePointer(
              child: AdWidget(bannerAd: banner),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.habitsTitle),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fon1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Основной контент
            Expanded(
              child: _buildMainContent(l10n),
            ),
            
            // Блок рекламы
            _buildBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigation() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Кнопка "предыдущая"
            IconButton(
              onPressed: _goToPreviousDay,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Предыдущий день',
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
            ),
            
            // Центральная часть с датой
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Center(
                  child: Text(
                    _formatDate(context, _selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            // Кнопка "следующая"
            IconButton(
              onPressed: _goToNextDay,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Следующий день',
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ошибка: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Фильтруем привычки для выбранной даты
    final executionHabitsForDate = _executionHabits
        .where((habit) => _shouldExecuteOnDate(habit, _selectedDate))
        .toList();
        
    final measurableHabitsForDate = _measurableHabits
        .where((habit) => _shouldExecuteOnDateMeasurable(habit, _selectedDate))
        .toList();

    // Объединяем все привычки в один список с указанием типа
    final allHabits = <Map<String, dynamic>>[];
    
    for (final habit in executionHabitsForDate) {
      allHabits.add({
        'habit': habit,
        'type': 'execution',
      });
    }
    
    for (final habit in measurableHabitsForDate) {
      allHabits.add({
        'habit': habit,
        'type': 'measurable',
      });
    }

    if (allHabits.isEmpty) {
      return const Center(
        child: Text(
          'На выбранную дату привычки не запланированы',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allHabits.length,
      itemBuilder: (context, index) {
        final habitData = allHabits[index];
        final habit = habitData['habit'];
        final type = habitData['type'];
        
        if (type == 'execution') {
          return _buildHabitCard(habit as HabitExecution, false);
        } else {
          return _buildHabitCard(habit as HabitMeasurable, true);
        }
      },
    );
  }

  

  Widget _buildHabitCard(dynamic habit, bool isMeasurable) {
    final isCompleted = isMeasurable 
        ? (_measurableRecords[habit.id]?.isCompleted ?? false)
        : (_executionRecords[habit.id]?.isCompleted ?? false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с чекбоксом и названием привычки
            Row(
              children: [
                Checkbox(
                  value: isCompleted,
                  onChanged: (value) {
                    if (value != null) {
                      if (isMeasurable) {
                        _toggleMeasurableHabit(habit, value);
                      } else {
                        _toggleExecutionHabit(habit, value);
                      }
                    }
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Дополнительная информация
            if (isMeasurable) ...[
              // Для измеримых привычек показываем цель и факт
              _buildMeasurableInfo(habit),
              const SizedBox(height: 8),
            ],
            
            // Напоминание
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Напоминание: ${habit.reminderTime.isEmpty ? 'не установлено' : habit.reminderTime}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurableInfo(HabitMeasurable habit) {
    final record = _measurableRecords[habit.id];
    final actualValue = record?.actualValue;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Цель: ${habit.goal} ${habit.unit}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (actualValue != null) ...[
            const SizedBox(width: 16),
            const Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Факт: $actualValue ${habit.unit}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.green),
            ),
          ],
        ],
      ),
    );
  }
}