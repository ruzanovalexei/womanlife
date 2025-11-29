// lib/widgets/settings_tab.dart
import 'package:flutter/material.dart';

import '../models/settings.dart';
import 'settings_form.dart';

class SettingsTab extends StatelessWidget {
  final Settings settings;
  final Function(Settings) onSave;

  const SettingsTab({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsForm(
      settings: settings,
      onSave: onSave,
    );
  }
}