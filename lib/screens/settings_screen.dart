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


  late BannerAd banner;
  var isBannerAlreadyCreated = false;


  @override
  void initState() {
    super.initState();
    _loadSettings(includeBanner: false);
  }


  _createBanner() {
    final screenWidth = MediaQuery.of(context).size.width.round();
    final adSize = BannerAdSize.sticky(width: screenWidth);
    
    return BannerAd(
      adUnitId: 'R-M-17946414-1',
      adSize: adSize,
      adRequest: const AdRequest(),
      onAdLoaded: () {},
      onAdFailedToLoad: (error) {},
      onAdClicked: () {},
      onLeftApplication: () {},
      onReturnedToApplication: () {},
      onImpression: (impressionData) {}
    );
  }



  Future<void> _loadSettings({bool includeBanner = false}) async {
    try {
        if (includeBanner) {
        banner = _createBanner();
        
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          isBannerAlreadyCreated = true;
        });
      } else {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final settings = await _databaseHelper.getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings(Settings newSettings) async {
    try {
      setState(() {
        _errorMessage = null;
      });
      
      await _databaseHelper.updateSettings(newSettings);
      setState(() {
        _settings = newSettings;
      });
      localeService.updateLocale(Locale(newSettings.locale));
      
      // Если уведомления отключены, отменяем все
      // if (!newSettings.delayNotificationEnabled) {
      //   await NotificationService().cancelAllNotifications();
      // }
      
      // Проверяем разрешения после сохранения настроек
      if (mounted) {
        await PermissionsService.checkAndRequestPermissions(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.settingsSaved),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true); // Возвращаем true, чтобы HomeScreen перезагрузил данные
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.settingsSaveError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Создаем баннер только если его еще нет и мы не в процессе загрузки
    if (!isBannerAlreadyCreated && !_isLoading) {
      try {
        banner = _createBanner();
        setState(() {
          isBannerAlreadyCreated = true;
        });
      } catch (e) {
        // Игнорируем ошибки создания баннера
      }
    }
    
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
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fon1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Основной контент
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
                                onPressed: _loadSettings,
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        )
                      : TabBarView(
                          children: [
                            SettingsTab(
                              settings: _settings,
                              onSave: _saveSettings,
                            ),
                            const MedicationsTab(),
                            const SymptomsTab(),
                          ],
                        ),
            ),
            
            // Виджет рекламы
            Container(
              alignment: Alignment.bottomCenter,
              child: isBannerAlreadyCreated ? AdWidget(bannerAd: banner) : null,
            ),
          ],
        ),
      ),
      ),
    );
  }
}