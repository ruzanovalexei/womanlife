// lib/screens/planner_task_screen.dart

import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/models/planner_task.dart';

class PlannerTaskScreen extends StatefulWidget {
  final DateTime date;
  final PlannerTask? task;

  const PlannerTaskScreen({
    super.key,
    required this.date,
    this.task,
  });

  @override
  _PlannerTaskScreenState createState() => _PlannerTaskScreenState();
}

class _PlannerTaskScreenState extends State<PlannerTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _databaseHelper = DatabaseHelper();

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description ?? '';
      _startTime = widget.task!.startTime;
      _endTime = widget.task!.endTime;
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Future<void> _selectTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          if (_timeToMinutes(picked) >= _timeToMinutes(_endTime)) {
             _endTime = TimeOfDay(hour: picked.hour + 1, minute: picked.minute);
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final task = PlannerTask(
      id: widget.task?.id,
      date: widget.date,
      startTime: _startTime,
      endTime: _endTime,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
    );

    if (widget.task == null) {
      await _databaseHelper.insertPlannerTask(task);
    } else {
      await _databaseHelper.updatePlannerTask(task);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _deleteTask() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTask),
        content: Text(l10n.deleteTaskConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteTask),
          ),
        ],
      ),
    );

    if (confirm == true && widget.task != null) {
      await _databaseHelper.deletePlannerTask(widget.task!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.deleteTask : l10n.addTask),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteTask,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: Text(l10n.selectDate),
              subtitle: Text(
                '${widget.date.day}.${widget.date.month}.${widget.date.year}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.taskStartTime),
              subtitle: Text(_startTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(isStart: true),
            ),
            ListTile(
              title: Text(l10n.taskEndTime),
              subtitle: Text(_endTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(isStart: false),
            ),
            const Divider(),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: l10n.taskTitle),
              validator: (value) => value == null || value.isEmpty ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(labelText: l10n.taskDescription),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveTask,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
