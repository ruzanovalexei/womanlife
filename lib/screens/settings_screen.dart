import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
//import 'package:period_tracker/services/notification_service.dart';

import '../database/database_helper.dart';
import '../models/settings.dart';
import '../services/locale_service.dart';
import '../services/permissions_service.dart';
// import '../services/ad_banner_service.dart';
import '../widgets/settings_tab.dart';
// import '../widgets/symptoms_tab.dart';
// import '../widgets/cache_management_tab.dart';
// import 'package:yandex_mobileads/mobile_ads.dart';
//import 'package:yandex_mobileads/ad_widget.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _databaseHelper = DatabaseHelper();
  // final _adBannerService = AdBannerService();
  late Settings _settings;
  bool _isLoading = true;
  String? _errorMessage;
  static const _backgroundImage = AssetImage('assets/images/fon1.png');

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  // Оптимизированная инициализация экрана
  void _initializeScreen() {
    _loadSettings();
  }

  // Оптимизированная загрузка настроек - один setState
  Future<void> _loadSettings() async {
    try {
      final settings = await _databaseHelper.getSettings();
      
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        debugPrint('Error loading settings: $e');
      }
    }
  }

  Future<void> _saveSettings(Settings newSettings) async {
    try {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
      
      await _databaseHelper.updateSettings(newSettings);
      
      if (mounted) {
        setState(() {
          _settings = newSettings;
        });
        localeService.updateLocale(Locale(newSettings.locale));
        
        // Проверяем разрешения после сохранения настроек
        await PermissionsService.checkAndRequestPermissions(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.settingsSaved),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true); // Возвращаем true, чтобы HomeScreen перезагрузил данные
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.settingsSaveError),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint('Error saving settings: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return DefaultTabController(
      length: 1, //количество вкладок
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.settingsTabGeneral),
              // Tab(text: l10n.settingsTabSymptoms),
              // Tab(text: l10n.settingsTabCache),
            ],
          ),
        ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: _backgroundImage,
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
              // _adBannerService.createBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }

  // Вынесенный основной контент
  Widget _buildMainContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorWidget(l10n);
    }
    
    return TabBarView(
      children: [
        SettingsTab(
          settings: _settings,
          onSave: _saveSettings,
        ),
        // Убрал вкладку симптомов, пока думаю что она не нужн
        // const SymptomsTab(),
        // const CacheManagementTab(),
      ],
    );
  }

  // Виджет ошибки
  Widget _buildErrorWidget(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            l10n.errorWithMessage(_errorMessage!),
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSettings,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  
}