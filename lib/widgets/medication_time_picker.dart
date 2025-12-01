// lib/widgets/medication_time_picker.dart
import 'package:flutter/material.dart';
//import '../models/medication.dart';
import '../models/medication_time.dart';

class MedicationTimePicker extends StatefulWidget {
  final List<MedicationTime> initialTimes;
  final ValueChanged<List<MedicationTime>> onTimesChanged;

  const MedicationTimePicker({
    super.key,
    required this.initialTimes,
    required this.onTimesChanged,
  });

  @override
  _MedicationTimePickerState createState() => _MedicationTimePickerState();
}

class _MedicationTimePickerState extends State<MedicationTimePicker> {
  late List<MedicationTime> _selectedTimes;

  @override
  void initState() {
    super.initState();
    _selectedTimes = List.from(widget.initialTimes);
  }

  Future<void> _addTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final newTime = MedicationTime(hour: picked.hour, minute: picked.minute);
      setState(() {
        _selectedTimes.add(newTime);
        _selectedTimes.sort((a, b) => a.hour == b.hour ? a.minute.compareTo(b.minute) : a.hour.compareTo(b.hour));
        widget.onTimesChanged(_selectedTimes);
      });
    }
  }

  void _removeTime(MedicationTime time) {
    setState(() {
      _selectedTimes.remove(time);
      widget.onTimesChanged(_selectedTimes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Время приема:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedTimes.map((time) => Chip(
            label: Text(time.toString()),
            onDeleted: () => _removeTime(time),
          )).toList(),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _addTime(context),
          icon: const Icon(Icons.add_alarm),
          label: const Text('Добавить время'),
        ),
      ],
    );
  }
}