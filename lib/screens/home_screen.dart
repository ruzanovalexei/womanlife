import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import '../widgets/calendar_widget.dart';
import '../models/settings.dart';
import '../models/period_record.dart';
import 'day_detail_screen.dart';
import 'settings_screen.dart';
import '../database/database_helper.dart';
import '../utils/date_utils.dart'; // Добавляем импорт
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _databaseHelper = DatabaseHelper();
  late Settings _settings;
  List<PeriodRecord> _periodRecords = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Загружаем настройки и записи о периодах
      _settings = await _databaseHelper.getSettings();
      _periodRecords = await _databaseHelper.getAllPeriodRecords();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    
    if (result == true) {
      _loadData();
    }
  }

  void _openDayDetail(DateTime day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayDetailScreen(
          selectedDate: day,
          periodRecords: _periodRecords,
          settings: _settings,
        ),
      ),
    ).then((_) {
      // Перезагружаем данные после возвращения из деталей дня
      _loadData();
    });
  }

  void _closeApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: l10n.refreshTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: l10n.settingsTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.exitTooltip,
            onPressed: _closeApp,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text(l10n.errorWithMessage(_errorMessage!)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                    child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : CalendarWidget(
                  onDaySelected: _openDayDetail,
                  settings: _settings,
                  periodRecords: _periodRecords,
                ),
    );
  }
    }