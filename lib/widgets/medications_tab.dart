import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/medication.dart';
import '../widgets/medication_time_picker.dart';
import '../utils/period_calculator.dart';
import '../database/database_helper.dart';
import '../utils/date_utils.dart'; // Добавлен импорт MyDateUtils
import '../models/medication_time.dart';

class MedicationsTab extends StatefulWidget {
  final Function(bool hasChanges)? onDataChanged;
  
  const MedicationsTab({super.key, this.onDataChanged});

  @override
  _MedicationsTabState createState() => _MedicationsTabState();
}

class _MedicationsTabState extends State<MedicationsTab> {
  final _databaseHelper = DatabaseHelper();
  List<Medication> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    try {
      final medications = await _databaseHelper.getAllMedications();
      setState(() {
        _medications = medications;
        _isLoading = false;
      });
      print('DEBUG: Loaded ${medications.length} medications.');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // TODO: Обработка ошибки загрузки лекарств
    }
  }

  Future<void> _showMedicationDialog({Medication? medication}) async {
    final result = await showDialog<Medication>(
      context: context,
      builder: (context) {
        return MedicationDialog(medication: medication);
      },
    );

    // Если пользователь сохранил лекарство, обрабатываем результат
    if (result != null) {
      try {
        if (medication == null) {
          await _databaseHelper.insertMedication(result);
        } else {
          await _databaseHelper.updateMedication(result);
        }
        await _loadMedications();
        
        // Уведомляем об изменении данных
        widget.onDataChanged?.call(true);
        
        if (mounted) {
          // Сообщение об успехе можно добавить при необходимости
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.medicationSaveError(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteMedication(Medication medication) async {
    try {
      await _databaseHelper.deleteMedication(medication.id!);
      await _loadMedications();
      
      // Уведомляем об изменении данных
      widget.onDataChanged?.call(true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.medicationDeleteSuccess(medication.name)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.medicationDeleteError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                  l10n.addMedicationTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FloatingActionButton(
                  onPressed: () => _showMedicationDialog(),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Список лекарств
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _medications.isEmpty
                      ? Center(child: Text(l10n.noMedications))
                      : ListView.builder(
                          itemCount: _medications.length,
                          itemBuilder: (context, index) {
                            final medication = _medications[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Text(medication.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${l10n.medicationStartDateLabel}: ${DateFormat('dd.MM.yyyy').format(medication.startDate.toLocal())}'
                                    ),
                                    Text(
                                      medication.endDate != null 
                                          ? '${l10n.medicationEndDateLabel}: ${DateFormat('dd.MM.yyyy').format(medication.endDate!.toLocal())}'
                                          : l10n.medicationEndDateNotSet
                                    ),
                                    if (medication.times.isNotEmpty) Text('${l10n.medicationTimes}: ${medication.timesAsString}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                      onPressed: () => _showMedicationDialog(medication: medication),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _showDeleteConfirmationDialog(context, medication),
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
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Medication medication) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.medicationDeleteConfirmTitle), // localization
          content: Text(l10n.medicationDeleteConfirmMessage(medication.name)), // localization
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(l10n.cancelButton), // localization
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteMedication(medication);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text(l10n.deleteButton), // localization
            ),
          ],
        );
      },
    );
  }
}

// Отдельный виджет для диалога добавления/редактирования лекарства
class MedicationDialog extends StatefulWidget {
  final Medication? medication;
  
  const MedicationDialog({super.key, this.medication});

  @override
  State<MedicationDialog> createState() => _MedicationDialogState();
}

class _MedicationDialogState extends State<MedicationDialog> {
  late TextEditingController nameController;
  late DateTime? startDate;
  late DateTime? endDate;
  late List<MedicationTime> times;
  bool isAtStart = true; // Отслеживаем, находится ли курсор в начале

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.medication?.name);
    startDate = widget.medication?.startDate;
    endDate = widget.medication?.endDate;
    times = List.from(widget.medication?.times ?? []);
    
    // Добавляем listener для отслеживания позиции курсора
    nameController.addListener(_updateKeyboardState);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  // Функция для обновления состояния клавиатуры
  void _updateKeyboardState() {
    final currentPosition = nameController.selection.extentOffset;
    final newIsAtStart = currentPosition == 0;
    
    if (newIsAtStart != isAtStart) {
      setState(() {
        isAtStart = newIsAtStart;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(widget.medication == null ? l10n.addMedicationTitle : l10n.editMedicationTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.medicationNameLabel),
              autofocus: widget.medication == null, // Автофокус только при добавлении
              textCapitalization: isAtStart 
                  ? TextCapitalization.sentences // Первая буква заглавная, остальные строчные
                  : TextCapitalization.none,      // Все строчные буквы в середине
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: startDate == null ? PeriodCalculator.getToday().toLocal() : startDate!.toLocal(),
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
                        ? '${l10n.medicationStartDateLabel}: ${DateFormat('dd.MM.yyyy').format(startDate!.toLocal())}' 
                        : l10n.medicationPickStartDate),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: endDate == null ? startDate?.toLocal() ?? PeriodCalculator.getToday().toLocal() : endDate!.toLocal(),
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
                        ? '${l10n.medicationEndDateLabel}: ${DateFormat('dd.MM.yyyy').format(endDate!.toLocal())}' 
                        : l10n.medicationPickEndDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            MedicationTimePicker(
              initialTimes: times,
              onTimesChanged: (newTimes) {
                setState(() {
                  times = newTimes;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: _saveMedication,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }

  void _saveMedication() {
    final name = nameController.text.trim();
    
    if (name.isEmpty || startDate == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.medicationNameMissingError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newMedication = Medication(
      id: widget.medication?.id,
      name: name,
      startDate: startDate!,
      endDate: endDate,
      times: times,
    );

    Navigator.of(context).pop(newMedication);
  }
}