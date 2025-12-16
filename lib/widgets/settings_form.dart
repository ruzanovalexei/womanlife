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
            initialValue: _selectedLocale,
            decoration: InputDecoration(
              labelText: l10n.settingsFormLanguageLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Text(l10n.settingsFormLanguageEnglish),
              ),
              DropdownMenuItem(
                value: 'ru',
                child: Text(l10n.settingsFormLanguageRussian),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedLocale = value;
              });
            },
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
          const SizedBox(height: 16),
          // Настройка периода хранения данных
          // CheckboxListTile(
          //   title: const Text('Автоматическая очистка старых данных'),
          //   subtitle: const Text('Удалять записи старше указанного периода'),
          //   value: _isDataRetentionEnabled,
          //   onChanged: (value) {
          //     setState(() {
          //       _isDataRetentionEnabled = value ?? false;
          //       if (!_isDataRetentionEnabled) {
          //         _dataRetentionController.clear();
          //       }
          //     });
          //   },
          // ),
          // if (_isDataRetentionEnabled) ...[
          //   const SizedBox(height: 8),
          //   TextFormField(
          //     controller: _dataRetentionController,
          //     decoration: const InputDecoration(
          //       labelText: 'Период хранения данных (месяцев)',
          //       border: OutlineInputBorder(),
          //       helperText: '0 = без ограничений, null = не удалять автоматически',
          //     ),
          //     keyboardType: TextInputType.number,
          //     validator: (value) {
          //       if (_isDataRetentionEnabled && (value == null || value.isEmpty)) {
          //         return 'Введите период хранения данных';
          //       }
          //       if (value != null && value.isNotEmpty) {
          //         final numValue = int.tryParse(value);
          //         if (numValue == null || numValue < 0) {
          //           return 'Введите корректное число (0 или больше)';
          //         }
          //       }
          //       return null;
          //     },
          //   ),
          // ],
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