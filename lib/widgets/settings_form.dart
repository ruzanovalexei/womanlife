// lib/widgets/settings_form.dart
import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';

import '../models/settings.dart';

class SettingsForm extends StatefulWidget {
  final Settings settings;
  final Function(Settings) onSave;

  const SettingsForm({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  _SettingsFormState createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  late TextEditingController _cycleLengthController;
  late TextEditingController _periodLengthController;
  late TextEditingController _planningMonthsController;
  late TextEditingController _dataRetentionController;
  late String _selectedLocale;
  late String _selectedFirstDay;
  late bool _isDataRetentionEnabled;
  late String _dayStartTime;
  late String _dayEndTime;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cycleLengthController = TextEditingController(text: widget.settings.cycleLength.toString());
    _periodLengthController = TextEditingController(text: widget.settings.periodLength.toString());
    _planningMonthsController = TextEditingController(text: widget.settings.planningMonths.toString());
    _dataRetentionController = TextEditingController(
      text: widget.settings.dataRetentionPeriod?.toString() ?? ''
    );
    _selectedLocale = widget.settings.locale;
    _selectedFirstDay = widget.settings.firstDayOfWeek;
    _isDataRetentionEnabled = widget.settings.dataRetentionPeriod != null;
    _dayStartTime = widget.settings.dayStartTime;
    // Если в БД 24:00, отображаем как 00:00
     _dayEndTime = widget.settings.dayEndTime;
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Вычисляет разницу в минутах между временем окончания и начала дня
  /// Учитывает случай, когда окончание = "24:00" (следующий день)
  int _calculateTimeDifferenceInMinutes(String startTime, String endTime) {
    final start = _parseTime(startTime);
    final endHour = endTime == '24:00' ? 24 : int.parse(endTime.split(':')[0]);
    final end = TimeOfDay(hour: endHour, minute: int.parse(endTime.split(':')[1]));

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    // Если окончание "24:00", это следующий день
    return end.hour == 24 ? (24 * 60 - startMinutes) : (endMinutes - startMinutes);
  }

  /// Проверяет, что разница между окончанием и началом дня >= 1 час
  bool _validateDayTimeRange() {
    final diffMinutes = _calculateTimeDifferenceInMinutes(_dayStartTime, _dayEndTime);
    return diffMinutes >= 60;
  }

  Future<void> _selectDayTime({required bool isStart}) async {
    final currentTime = isStart ? _parseTime(_dayStartTime) : _parseTime(_dayEndTime);
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _dayStartTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        } else {
          // При выборе 00:00 для окончания дня записываем 24:00 в БД
          if (picked.hour == 0 && picked.minute == 0) {
            _dayEndTime = '24:00';
          } else {
            _dayEndTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNumberField(
            controller: _cycleLengthController,
            label: l10n.settingsFormCycleLength,
            min: 21,
            max: 35,
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            controller: _periodLengthController,
            label: l10n.settingsFormPeriodLength,
            min: 3,
            max: 7,
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            controller: _planningMonthsController,
            label: l10n.settingsFormPlanningMonths,
            min: 1,
            max: 12,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedFirstDay,
            decoration: InputDecoration(
              labelText: l10n.settingsFormFirstDayLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'monday',
                child: Text(l10n.settingsFormFirstDayMonday),
              ),
              DropdownMenuItem(
                value: 'sunday',
                child: Text(l10n.settingsFormFirstDaySunday),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedFirstDay = value;
              });
            },
          ),
          const SizedBox(height: 24),
          // Настройки ежедневника
          Text(
            l10n.plannerTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(l10n.dayStartTime),
                  subtitle: Text(_dayStartTime),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _selectDayTime(isStart: true),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text(l10n.dayEndTime),
                  subtitle: Text(_dayEndTime),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _selectDayTime(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveSettings,
            child: Text(l10n.settingsFormSaveButton),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required int min,
    required int max,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        final l10n = AppLocalizations.of(context)!;
        if (value == null || value.isEmpty) return l10n.settingsFormValueMissing;
        final numValue = int.tryParse(value);
        if (numValue == null) return l10n.settingsFormInvalidNumber;
        if (numValue < min || numValue > max) return l10n.settingsFormRangeError(min, max);
        return null;
      },
    );
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      // Проверка: разница между окончанием и началом дня должна быть >= 1 час
      if (!_validateDayTimeRange()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dayTimeRangeError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      int? dataRetentionPeriod;
      if (_isDataRetentionEnabled && _dataRetentionController.text.isNotEmpty) {
        dataRetentionPeriod = int.parse(_dataRetentionController.text);
      }

      final newSettings = widget.settings.copyWith(
        cycleLength: int.parse(_cycleLengthController.text),
        periodLength: int.parse(_periodLengthController.text),
        planningMonths: int.parse(_planningMonthsController.text),
        locale: _selectedLocale,
        firstDayOfWeek: _selectedFirstDay,
        dataRetentionPeriod: dataRetentionPeriod,
        dayStartTime: _dayStartTime,
        dayEndTime: _dayEndTime,
      );
      
      widget.onSave(newSettings);
    }
  }

  @override
  void dispose() {
    _cycleLengthController.dispose();
    _periodLengthController.dispose();
    _planningMonthsController.dispose();
    _dataRetentionController.dispose();
    super.dispose();
  }
}