import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
//import 'package:period_tracker/services/notification_service.dart';

import '../database/database_helper.dart';
import '../models/settings.dart';
import '../services/locale_service.dart';
import '../services/permissions_service.dart';
import '../widgets/settings_tab.dart';
import '../widgets/medications_tab.dart';
import '../widgets/symptoms_tab.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
//import 'package:yandex_mobileads/ad_widget.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _databaseHelper = DatabaseHelper();
  late Settings _settings;
  bool _isLoading = true;
  String? _errorMessage;
  static const _backgroundImage = AssetImage('assets/images/fon1.png');
  late BannerAd banner;
  var isBannerAlreadyCreated = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  // Оптимизированная инициализация экрана
  void _initializeScreen() {
    _createAdBanner();
    _loadSettings();
  }

  // Создание баннера
  BannerAd _createBanner() {
    final screenWidth = MediaQuery.of(context).size.width.round();
    final adSize = BannerAdSize.sticky(width: screenWidth);
    
    return BannerAd(
      adUnitId: 'R-M-17946414-5',
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.settingsTabGeneral),
              Tab(text: l10n.settingsTabMedications),
              Tab(text: l10n.settingsTabSymptoms),
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
              _buildBannerWidget(),
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
        const MedicationsTab(),
        const SymptomsTab(),
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

  // Вынесенный виджет баннера
  Widget _buildBannerWidget() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 8),
      height: isBannerAlreadyCreated ? 60 : 0, // Фиксированная высота
      child: isBannerAlreadyCreated 
          ? AdWidget(bannerAd: banner)
          : const SizedBox.shrink(),
    );
  }
}