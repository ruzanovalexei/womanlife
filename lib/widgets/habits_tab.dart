import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/habit_execution.dart';
import '../models/habit_measurable.dart';
import '../models/frequency_type.dart';
import '../utils/date_utils.dart';

class HabitsTab extends StatefulWidget {
  const HabitsTab({super.key});

  @override
  _HabitsTabState createState() => _HabitsTabState();
}

class _HabitsTabState extends State<HabitsTab> {
  final _databaseHelper = DatabaseHelper();
  List<HabitExecution> _executionHabits = [];
  List<HabitMeasurable> _measurableHabits = [];
  List<FrequencyType> _frequencyTypes = [];
  Map<int, FrequencyType> _frequencyTypesMap = {}; // Карта всех FrequencyType
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final executionHabits = await _databaseHelper.getAllHabitExecutions();
      final measurableHabits = await _databaseHelper.getAllHabitMeasurables();
      
      // Загружаем все FrequencyTypes из базы данных
      final allFrequencyTypes = await _databaseHelper.getAllFrequencyTypes();
      
      // Создаем карту всех FrequencyType
      final frequencyTypesMap = <int, FrequencyType>{};
      for (final frequencyType in allFrequencyTypes) {
        if (frequencyType.id != null) {
          frequencyTypesMap[frequencyType.id!] = frequencyType;
        }
      }
      
      // Создаем базовые типы частоты для диалогов (по одному для каждого типа)
      final baseFrequencyTypes = <FrequencyType>[];
      for (int type = 1; type <= 4; type++) {
        final foundType = allFrequencyTypes.firstWhere(
          (ft) => ft.type == type,
          orElse: () => FrequencyType(type: type),
        );
        baseFrequencyTypes.add(foundType);
      }

      setState(() {
        _executionHabits = executionHabits;
        _measurableHabits = measurableHabits;
        _frequencyTypes = baseFrequencyTypes;
        _frequencyTypesMap = frequencyTypesMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showHabitTypeSelectionDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return const HabitTypeSelectionDialog();
      },
    );

    if (result != null) {
      if (result == 'execution') {
        await _showHabitExecutionDialog();
      } else if (result == 'measurable') {
        await _showHabitMeasurableDialog();
      }
    }
  }

  Future<void> _showHabitExecutionDialog({HabitExecution? habit}) async {
    // Загружаем конкретный FrequencyType для привычки при редактировании
    FrequencyType? habitFrequencyType;
    if (habit != null) {
      habitFrequencyType = await _databaseHelper.getFrequencyTypeById(habit.frequencyId);
    }

    final result = await showDialog<HabitExecution>(
      context: context,
      builder: (context) {
        return HabitExecutionDialog(
          habit: habit,
          frequencyTypes: _frequencyTypes,
          habitFrequencyType: habitFrequencyType,
        );
      },
    );

    if (result != null) {
      try {
        if (habit == null) {
          await _databaseHelper.insertHabitExecution(result);
        } else {
          await _databaseHelper.updateHabitExecution(result);
        }
        await _loadHabits();

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(habit == null ? l10n.habitExecutionAdded : l10n.habitExecutionUpdated),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.habitSaveError(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showHabitMeasurableDialog({HabitMeasurable? habit}) async {
    // Загружаем конкретный FrequencyType для привычки при редактировании
    FrequencyType? habitFrequencyType;
    if (habit != null) {
      habitFrequencyType = await _databaseHelper.getFrequencyTypeById(habit.frequencyId);
    }

    final result = await showDialog<HabitMeasurable>(
      context: context,
      builder: (context) {
        return HabitMeasurableDialog(
          habit: habit,
          frequencyTypes: _frequencyTypes,
          habitFrequencyType: habitFrequencyType,
        );
      },
    );

    if (result != null) {
      try {
        if (habit == null) {
          await _databaseHelper.insertHabitMeasurable(result);
        } else {
          await _databaseHelper.updateHabitMeasurable(result);
        }
        await _loadHabits();

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(habit == null ? l10n.habitMeasurableAdded : l10n.habitMeasurableUpdated),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.habitSaveError(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteHabitExecution(HabitExecution habit) async {
    final l10n = AppLocalizations.of(context)!;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteHabitTitle),
          content: Text(l10n.deleteHabitConfirmMessage(habit.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _databaseHelper.deleteHabitExecution(habit.id!);
                  Navigator.pop(context);
                  await _loadHabits();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.habitDeleted),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.habitDeleteError(e.toString())),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.deleteButton),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteHabitMeasurable(HabitMeasurable habit) async {
    final l10n = AppLocalizations.of(context)!;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteHabitTitle),
          content: Text(l10n.deleteHabitConfirmMessage(habit.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _databaseHelper.deleteHabitMeasurable(habit.id!);
                  Navigator.pop(context);
                  await _loadHabits();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.habitDeleted),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.habitDeleteError(e.toString())),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.deleteButton),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/fon1.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и кнопка добавления
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.habitsTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _showHabitTypeSelectionDialog,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Список привычек
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.errorWithMessage(_errorMessage!)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadHabits,
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        )
                      : (_executionHabits.isEmpty && _measurableHabits.isEmpty)
                          ? Center(
                              child: Text(
                                l10n.noHabits,
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _executionHabits.length + _measurableHabits.length,
                              itemBuilder: (context, index) {
                                // Объединяем все привычки в один список
                                if (index < _executionHabits.length) {
                                  return _buildHabitExecutionCard(_executionHabits[index]);
                                } else {
                                  final measurableIndex = index - _executionHabits.length;
                                  return _buildHabitMeasurableCard(_measurableHabits[measurableIndex]);
                                }
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitExecutionCard(HabitExecution habit) {
    final l10n = AppLocalizations.of(context)!;
    final frequencyType = _frequencyTypesMap[habit.frequencyId] ?? FrequencyType(type: 1);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              habit.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.habitTypeExecution} • ${frequencyType.description}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '${l10n.habitStartDateLabel}: ${DateFormat('dd.MM.yyyy').format(habit.startDate.toLocal())}',
              style: const TextStyle(fontSize: 14),
            ),
            if (habit.endDate != null) ...[
              Text(
                '${l10n.habitEndDateLabel}: ${DateFormat('dd.MM.yyyy').format(habit.endDate!.toLocal())}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (habit.reminderTime.isNotEmpty) ...[
              Text(
                '${l10n.habitReminderTimeLabel}: ${habit.reminderTime}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () => _showHabitExecutionDialog(habit: habit),
              tooltip: l10n.editButton,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteHabitExecution(habit),
              tooltip: l10n.deleteButton,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitMeasurableCard(HabitMeasurable habit) {
    final l10n = AppLocalizations.of(context)!;
    final frequencyType = _frequencyTypesMap[habit.frequencyId] ?? FrequencyType(type: 1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              habit.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.habitTypeMeasurable} • ${frequencyType.description}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '${l10n.habitGoalLabel}: ${habit.goal} ${habit.unit}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              '${l10n.habitStartDateLabel}: ${DateFormat('dd.MM.yyyy').format(habit.startDate.toLocal())}',
              style: const TextStyle(fontSize: 14),
            ),
            if (habit.endDate != null) ...[
              Text(
                '${l10n.habitEndDateLabel}: ${DateFormat('dd.MM.yyyy').format(habit.endDate!.toLocal())}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (habit.reminderTime.isNotEmpty) ...[
              Text(
                '${l10n.habitReminderTimeLabel}: ${habit.reminderTime}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () => _showHabitMeasurableDialog(habit: habit),
              tooltip: l10n.editButton,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteHabitMeasurable(habit),
              tooltip: l10n.deleteButton,
            ),
          ],
        ),
      ),
    );
  }
}

// Диалог выбора типа привычки
class HabitTypeSelectionDialog extends StatelessWidget {
  const HabitTypeSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.selectHabitTypeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle_outline, color: Colors.blue),
            title: Text(l10n.habitTypeExecution),
            subtitle: Text(l10n.habitTypeExecutionDescription),
            onTap: () => Navigator.pop(context, 'execution'),
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: Colors.green),
            title: Text(l10n.habitTypeMeasurable),
            subtitle: Text(l10n.habitTypeMeasurableDescription),
            onTap: () => Navigator.pop(context, 'measurable'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
      ],
    );
  }
}

// Диалог для привычек типа выполнение
class HabitExecutionDialog extends StatefulWidget {
  final HabitExecution? habit;
  final List<FrequencyType> frequencyTypes;
  final FrequencyType? habitFrequencyType;

  const HabitExecutionDialog({
    super.key,
    this.habit,
    required this.frequencyTypes,
    this.habitFrequencyType,
  });

  @override
  State<HabitExecutionDialog> createState() => _HabitExecutionDialogState();
}

class _HabitExecutionDialogState extends State<HabitExecutionDialog> {
  final _databaseHelper = DatabaseHelper();
  late TextEditingController nameController;
  late int selectedFrequencyType;
  late int? intervalValue; // Для типов 2 и 4
  late List<int> selectedDaysOfWeek; // Для типа 3
  late DateTime? startDate;
  late DateTime? endDate;
  late TimeOfDay? reminderTime; // Nullable для возможности не выбирать время
  bool isAtStart = true;

  final List<String> frequencyTypeNames = [
    'Каждый день',
    'Каждый X день',
    'Дни недели',
    'X раз в неделю',
  ];

  final List<String> dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.habit?.name);
    
    // Инициализация частоты
    if (widget.habit != null && widget.habitFrequencyType != null) {
      // При редактировании используем конкретный FrequencyType привычки
      selectedFrequencyType = widget.habitFrequencyType!.type;
      intervalValue = widget.habitFrequencyType!.intervalValue;
      selectedDaysOfWeek = List.from(widget.habitFrequencyType!.selectedDaysOfWeek ?? []);
    } else {
      selectedFrequencyType = 1;
      intervalValue = 2;
      selectedDaysOfWeek = []; // По умолчанию пустой список - никакие дни не выбраны
    }

    startDate = widget.habit?.startDate;
    endDate = widget.habit?.endDate;
    
    // Инициализация времени напоминания
    TimeOfDay? initialReminderTime;
    if (widget.habit?.reminderTime.isNotEmpty == true) {
      final timeParts = widget.habit!.reminderTime.split(':');
      initialReminderTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
    reminderTime = initialReminderTime; // Оставляем null, если время не выбрано

    nameController.addListener(_updateKeyboardState);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _updateKeyboardState() {
    final currentPosition = nameController.selection.extentOffset;
    final newIsAtStart = currentPosition == 0;
    
    if (newIsAtStart != isAtStart) {
      setState(() {
        isAtStart = newIsAtStart;
      });
    }
  }

  void _onFrequencyTypeChanged(int newType) {
    setState(() {
      selectedFrequencyType = newType;
      
      // Сброс дополнительных параметров в зависимости от типа
      switch (newType) {
        case 1: // Каждый день
          intervalValue = null;
          selectedDaysOfWeek.clear();
          break;
        case 2: // Каждый X день
          intervalValue = intervalValue ?? 2;
          selectedDaysOfWeek.clear();
          break;
        case 3: // Дни недели
          intervalValue = null;
          // Не устанавливаем дни по умолчанию - пользователь сам выбирает
          break;
        case 4: // X раз в неделю
          intervalValue = intervalValue ?? 3;
          selectedDaysOfWeek.clear();
          break;
      }
    });
  }

  void _onDayToggle(int dayNumber) {
    setState(() {
      if (selectedDaysOfWeek.contains(dayNumber)) {
        selectedDaysOfWeek.remove(dayNumber);
      } else {
        selectedDaysOfWeek.add(dayNumber);
        selectedDaysOfWeek.sort();
      }
    });
  }

  Future<void> _pickReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked != null) {
      setState(() {
        reminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(widget.habit == null ? l10n.addHabitExecutionTitle : l10n.editHabitExecutionTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.habitNameLabel),
              autofocus: widget.habit == null,
              textCapitalization: isAtStart 
                  ? TextCapitalization.sentences
                  : TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
            // Выбор типа частоты
            DropdownButtonFormField<int>(
              value: selectedFrequencyType,
              decoration: InputDecoration(labelText: l10n.habitFrequencyLabel),
              items: List.generate(4, (index) {
                return DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text(frequencyTypeNames[index]),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  _onFrequencyTypeChanged(value);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Дополнительные поля в зависимости от типа частоты
            if (selectedFrequencyType == 2) ...[
              // Каждый X день
              TextFormField(
                initialValue: intervalValue?.toString(),
                decoration: InputDecoration(
                  labelText: 'Через сколько дней',
                  hintText: '2',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    intervalValue = int.tryParse(value);
                  });
                },
              ),
              const SizedBox(height: 16),
            ] else if (selectedFrequencyType == 3) ...[
              // Дни недели
              Text('Выберите дни недели:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final dayNumber = index + 1;
                  final isSelected = selectedDaysOfWeek.contains(dayNumber);
                  return FilterChip(
                    label: Text(dayNames[index]),
                    selected: isSelected,
                    onSelected: (_) => _onDayToggle(dayNumber),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ] else if (selectedFrequencyType == 4) ...[
              // X раз в неделю
              TextFormField(
                initialValue: intervalValue?.toString(),
                decoration: InputDecoration(
                  labelText: 'Сколько раз в неделю',
                  hintText: '3',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    intervalValue = int.tryParse(value);
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Даты
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: startDate?.toLocal() ?? DateTime.now().toLocal(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = MyDateUtils.fromLocalDayToUtcDay(picked);
                        });
                      }
                    },
                    child: Text(startDate != null 
                        ? '${l10n.habitStartDateLabel}: ${DateFormat('dd.MM.yyyy').format(startDate!.toLocal())}' 
                        : l10n.pickStartDate),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: endDate?.toLocal() ?? startDate?.toLocal() ?? DateTime.now().toLocal(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = MyDateUtils.fromLocalDayToUtcDay(picked);
                        });
                      }
                    },
                    child: Text(endDate != null 
                        ? '${l10n.habitEndDateLabel}: ${DateFormat('dd.MM.yyyy').format(endDate!.toLocal())}' 
                        : l10n.pickEndDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Время напоминания
            ListTile(
              title: Text(l10n.habitReminderTimeLabel),
              subtitle: Text(reminderTime != null 
                  ? '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}'
                  : 'Выберите время напоминания'),
              trailing: const Icon(Icons.access_time),
              onTap: _pickReminderTime,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: _saveHabit,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }

  Future<void> _saveHabit() async {
    final name = nameController.text.trim();
    
    if (name.isEmpty || startDate == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillAllRequiredFields),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Валидация в зависимости от типа частоты
    if (selectedFrequencyType == 2 && (intervalValue == null || intervalValue! < 2)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректное количество дней (минимум 2)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedFrequencyType == 3 && selectedDaysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы один день недели'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedFrequencyType == 4 && (intervalValue == null || intervalValue! < 1 || intervalValue! > 7)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректное количество раз в неделю (от 1 до 7)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Создаем FrequencyType с актуальными данными
    final customFrequencyType = FrequencyType(
      id: widget.habit?.frequencyId, // Сохраняем ID при редактировании
      type: selectedFrequencyType,
      intervalValue: intervalValue,
      selectedDaysOfWeek: selectedDaysOfWeek.isNotEmpty ? List.from(selectedDaysOfWeek) : null,
    );

    // Сохраняем FrequencyType в БД
    int frequencyTypeId;
    if (widget.habit != null && widget.habitFrequencyType != null) {
      // При редактировании обновляем существующий FrequencyType
      await _databaseHelper.updateFrequencyType(customFrequencyType);
      frequencyTypeId = widget.habit!.frequencyId; // Сохраняем тот же ID
    } else {
      // При создании нового создаем новый FrequencyType
      frequencyTypeId = await _databaseHelper.insertFrequencyType(customFrequencyType);
    }

    // Форматируем время напоминания (может быть пустым)
    final reminderTimeString = reminderTime != null 
        ? '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}'
        : '';

    final newHabit = HabitExecution(
      id: widget.habit?.id,
      name: name,
      frequencyId: frequencyTypeId,
      reminderTime: reminderTimeString,
      startDate: startDate!,
      endDate: endDate,
    );

    Navigator.pop(context, newHabit);
  }
}

// Диалог для привычек типа измеримый результат
class HabitMeasurableDialog extends StatefulWidget {
  final HabitMeasurable? habit;
  final List<FrequencyType> frequencyTypes;
  final FrequencyType? habitFrequencyType;

  const HabitMeasurableDialog({
    super.key,
    this.habit,
    required this.frequencyTypes,
    this.habitFrequencyType,
  });

  @override
  State<HabitMeasurableDialog> createState() => _HabitMeasurableDialogState();
}

class _HabitMeasurableDialogState extends State<HabitMeasurableDialog> {
  final _databaseHelper = DatabaseHelper();
  late TextEditingController nameController;
  late TextEditingController goalController;
  late TextEditingController unitController;
  late int selectedFrequencyType;
  late int? intervalValue; // Для типов 2 и 4
  late List<int> selectedDaysOfWeek; // Для типа 3
  late DateTime? startDate;
  late DateTime? endDate;
  late TimeOfDay? reminderTime; // Nullable для возможности не выбирать время
  bool isAtStart = true;

  final List<String> frequencyTypeNames = [
    'Каждый день',
    'Каждый X день',
    'Дни недели',
    'X раз в неделю',
  ];

  final List<String> dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.habit?.name);
    goalController = TextEditingController(text: widget.habit?.goal.toString() ?? '');
    unitController = TextEditingController(text: widget.habit?.unit ?? '');
    
    // Инициализация частоты
    if (widget.habit != null && widget.habitFrequencyType != null) {
      // При редактировании используем конкретный FrequencyType привычки
      selectedFrequencyType = widget.habitFrequencyType!.type;
      intervalValue = widget.habitFrequencyType!.intervalValue;
      selectedDaysOfWeek = List.from(widget.habitFrequencyType!.selectedDaysOfWeek ?? []);
    } else {
      selectedFrequencyType = 1;
      intervalValue = 2;
      selectedDaysOfWeek = []; // По умолчанию пустой список - никакие дни не выбраны
    }

    startDate = widget.habit?.startDate;
    endDate = widget.habit?.endDate;
    
    // Инициализация времени напоминания
    TimeOfDay? initialReminderTime;
    if (widget.habit?.reminderTime.isNotEmpty == true) {
      final timeParts = widget.habit!.reminderTime.split(':');
      initialReminderTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
    reminderTime = initialReminderTime; // Оставляем null, если время не выбрано

    nameController.addListener(_updateKeyboardState);
  }

  @override
  void dispose() {
    nameController.dispose();
    goalController.dispose();
    unitController.dispose();
    super.dispose();
  }

  void _updateKeyboardState() {
    final currentPosition = nameController.selection.extentOffset;
    final newIsAtStart = currentPosition == 0;
    
    if (newIsAtStart != isAtStart) {
      setState(() {
        isAtStart = newIsAtStart;
      });
    }
  }

  void _onFrequencyTypeChanged(int newType) {
    setState(() {
      selectedFrequencyType = newType;
      
      // Сброс дополнительных параметров в зависимости от типа
      switch (newType) {
        case 1: // Каждый день
          intervalValue = null;
          selectedDaysOfWeek.clear();
          break;
        case 2: // Каждый X день
          intervalValue = intervalValue ?? 2;
          selectedDaysOfWeek.clear();
          break;
        case 3: // Дни недели
          intervalValue = null;
          // Не устанавливаем дни по умолчанию - пользователь сам выбирает
          break;
        case 4: // X раз в неделю
          intervalValue = intervalValue ?? 3;
          selectedDaysOfWeek.clear();
          break;
      }
    });
  }

  void _onDayToggle(int dayNumber) {
    setState(() {
      if (selectedDaysOfWeek.contains(dayNumber)) {
        selectedDaysOfWeek.remove(dayNumber);
      } else {
        selectedDaysOfWeek.add(dayNumber);
        selectedDaysOfWeek.sort();
      }
    });
  }

  Future<void> _pickReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked != null) {
      setState(() {
        reminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(widget.habit == null ? l10n.addHabitMeasurableTitle : l10n.editHabitMeasurableTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.habitNameLabel),
              autofocus: widget.habit == null,
              textCapitalization: isAtStart 
                  ? TextCapitalization.sentences
                  : TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: goalController,
                    decoration: InputDecoration(labelText: l10n.habitGoalLabel),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: unitController,
                    decoration: InputDecoration(labelText: l10n.habitUnitLabel),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Выбор типа частоты
            DropdownButtonFormField<int>(
              value: selectedFrequencyType,
              decoration: InputDecoration(labelText: l10n.habitFrequencyLabel),
              items: List.generate(4, (index) {
                return DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text(frequencyTypeNames[index]),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  _onFrequencyTypeChanged(value);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Дополнительные поля в зависимости от типа частоты
            if (selectedFrequencyType == 2) ...[
              // Каждый X день
              TextFormField(
                initialValue: intervalValue?.toString(),
                decoration: InputDecoration(
                  labelText: 'Через сколько дней',
                  hintText: '2',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    intervalValue = int.tryParse(value);
                  });
                },
              ),
              const SizedBox(height: 16),
            ] else if (selectedFrequencyType == 3) ...[
              // Дни недели
              Text('Выберите дни недели:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final dayNumber = index + 1;
                  final isSelected = selectedDaysOfWeek.contains(dayNumber);
                  return FilterChip(
                    label: Text(dayNames[index]),
                    selected: isSelected,
                    onSelected: (_) => _onDayToggle(dayNumber),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ] else if (selectedFrequencyType == 4) ...[
              // X раз в неделю
              TextFormField(
                initialValue: intervalValue?.toString(),
                decoration: InputDecoration(
                  labelText: 'Сколько раз в неделю',
                  hintText: '3',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    intervalValue = int.tryParse(value);
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Даты
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: startDate?.toLocal() ?? DateTime.now().toLocal(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = MyDateUtils.fromLocalDayToUtcDay(picked);
                        });
                      }
                    },
                    child: Text(startDate != null 
                        ? '${l10n.habitStartDateLabel}: ${DateFormat('dd.MM.yyyy').format(startDate!.toLocal())}' 
                        : l10n.pickStartDate),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: endDate?.toLocal() ?? startDate?.toLocal() ?? DateTime.now().toLocal(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = MyDateUtils.fromLocalDayToUtcDay(picked);
                        });
                      }
                    },
                    child: Text(endDate != null 
                        ? '${l10n.habitEndDateLabel}: ${DateFormat('dd.MM.yyyy').format(endDate!.toLocal())}' 
                        : l10n.pickEndDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Время напоминания
            ListTile(
              title: Text(l10n.habitReminderTimeLabel),
              subtitle: Text(reminderTime != null 
                  ? '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}'
                  : 'Выберите время напоминания'),
              trailing: const Icon(Icons.access_time),
              onTap: _pickReminderTime,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: _saveHabit,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }

  Future<void> _saveHabit() async {
    final name = nameController.text.trim();
    final goalText = goalController.text.trim();
    final unit = unitController.text.trim();
    
    if (name.isEmpty || goalText.isEmpty || unit.isEmpty || startDate == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillAllRequiredFields),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final goal = double.tryParse(goalText);
    if (goal == null || goal <= 0) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invalidGoalValue),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Валидация в зависимости от типа частоты
    if (selectedFrequencyType == 2 && (intervalValue == null || intervalValue! < 2)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректное количество дней (минимум 2)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedFrequencyType == 3 && selectedDaysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы один день недели'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedFrequencyType == 4 && (intervalValue == null || intervalValue! < 1 || intervalValue! > 7)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректное количество раз в неделю (от 1 до 7)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Создаем FrequencyType с актуальными данными
    final customFrequencyType = FrequencyType(
      id: widget.habit?.frequencyId, // Сохраняем ID при редактировании
      type: selectedFrequencyType,
      intervalValue: intervalValue,
      selectedDaysOfWeek: selectedDaysOfWeek.isNotEmpty ? List.from(selectedDaysOfWeek) : null,
    );

    // Сохраняем FrequencyType в БД
    int frequencyTypeId;
    if (widget.habit != null && widget.habitFrequencyType != null) {
      // При редактировании обновляем существующий FrequencyType
      await _databaseHelper.updateFrequencyType(customFrequencyType);
      frequencyTypeId = widget.habit!.frequencyId; // Сохраняем тот же ID
    } else {
      // При создании нового создаем новый FrequencyType
      frequencyTypeId = await _databaseHelper.insertFrequencyType(customFrequencyType);
    }

    // Форматируем время напоминания (может быть пустым)
    final reminderTimeString = reminderTime != null 
        ? '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}'
        : '';

    final newHabit = HabitMeasurable(
      id: widget.habit?.id,
      name: name,
      goal: goal,
      unit: unit,
      frequencyId: frequencyTypeId,
      reminderTime: reminderTimeString,
      startDate: startDate!,
      endDate: endDate,
    );

    Navigator.pop(context, newHabit);
  }
}