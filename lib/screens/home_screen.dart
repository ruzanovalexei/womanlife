import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import '../widgets/calendar_widget.dart';
import '../models/settings.dart';
import '../models/period_record.dart';
import 'day_detail_screen.dart';
import 'settings_screen.dart';




import 'package:yandex_mobileads/mobile_ads.dart';






//import 'analytics_screen.dart'; // вернуть, когда воскресим экран аналитики
import '../database/database_helper.dart';
import '../services/notification_service.dart';
//import '../utils/date_utils.dart'; // Добавляем импорт
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _databaseHelper = DatabaseHelper();
  final _notificationService = NotificationService();
  late Settings _settings;
  List<PeriodRecord> _periodRecords = [];
  bool _isLoading = true;
  String? _errorMessage;


  late BannerAd banner;
  var isBannerAlreadyCreated = false;


  BannerAdSize _getAdSize() {
    final screenWidth = MediaQuery.of(context).size.width.round();
    return BannerAdSize.sticky(width: screenWidth);
  }

  _createBanner() {
    print('🎯 HomeScreen: _createBanner() НАЧАЛСЯ');
    try {
      print('📱 HomeScreen: получаем размер экрана...');
      final screenWidth = MediaQuery.of(context).size.width.round();
      print('✅ HomeScreen: ширина экрана: $screenWidth');
      
      print('📏 HomeScreen: создаем BannerAdSize...');
      final adSize = BannerAdSize.sticky(width: screenWidth);
      print('✅ HomeScreen: BannerAdSize создан: $adSize');
      
      print('🏗️ HomeScreen: создаем BannerAd...');
      final bannerAd = BannerAd(
        adUnitId: 'demo-banner-yandex',
        adSize: adSize,
        adRequest: const AdRequest(),
        onAdLoaded: () {
          print('✅ HomeScreen: баннер загружен успешно');
        },
        onAdFailedToLoad: (error) {
          print('❌ HomeScreen: ошибка загрузки баннера: $error');
        },
        onAdClicked: () {
          print('👆 HomeScreen: клик по баннеру');
        },
        onLeftApplication: () {
          print('🚪 HomeScreen: уход из приложения');
        },
        onReturnedToApplication: () {
          print('↩️ HomeScreen: возврат в приложение');
        },
        onImpression: (impressionData) {
          print('👀 HomeScreen: показ баннера (impression)');
        }
      );
      
      print('✅ HomeScreen: BannerAd создан успешно');
      return bannerAd;
      
    } catch (e) {
      print('❌ HomeScreen: _createBanner() ошибка: $e');
      rethrow;
    }
  }


  @override
  void initState() {
    print('🏠 HomeScreen: initState() НАЧАЛСЯ');
    super.initState();
    print('🏠 HomeScreen: super.initState() завершен');
    
    print('🏠 HomeScreen: вызываем _initializeNotifications()...');
    _initializeNotifications();
    
    print('🏠 HomeScreen: вызываем _loadData() (без баннера)...');
    _loadData(includeBanner: false);
    
    print('🏠 HomeScreen: initState() ЗАВЕРШЕН');
  }

  Future<void> _initializeNotifications() async {
    print('🔔 HomeScreen: _initializeNotifications() НАЧАЛСЯ');
    try {
      await _notificationService.initialize();
      print('✅ HomeScreen: _initializeNotifications() успешно завершен');
    } catch (e) {
      print('❌ HomeScreen: _initializeNotifications() ошибка: $e');
      rethrow;
    }
  }
//Этот блок нужен для ручного вызова уведомлений по кнопке - делался для проверки
  // Future<void> _simulateNotification() async {
  //   await _notificationService.showImmediateNotification();
  // }

  Future<void> _loadData({bool includeBanner = false}) async {
    print('📊 HomeScreen: _loadData() НАЧАЛСЯ (includeBanner: $includeBanner)');
    try {
      if (includeBanner) {
        print('🏗️ HomeScreen: создаем баннер...');
        banner = _createBanner();
        print('✅ HomeScreen: баннер создан');
        
        print('⏳ HomeScreen: устанавливаем isLoading = true и isBannerAlreadyCreated = true...');
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          isBannerAlreadyCreated = true;
        });
      } else {
        print('⏳ HomeScreen: устанавливаем isLoading = true (без баннера)...');
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
      print('✅ HomeScreen: состояние обновлено');
      
      print('💾 HomeScreen: загружаем настройки из БД...');
      _settings = await _databaseHelper.getSettings();
      print('✅ HomeScreen: настройки загружены: $_settings');
      
      print('📅 HomeScreen: загружаем записи о периодах из БД...');
      _periodRecords = await _databaseHelper.getAllPeriodRecords();
      print('✅ HomeScreen: загружено периодов: ${_periodRecords.length}');
      
      print('⏳ HomeScreen: устанавливаем isLoading = false...');
      setState(() {
        _isLoading = false;
      });
      print('✅ HomeScreen: _loadData() успешно завершен');
      
    } catch (e) {
      print('❌ HomeScreen: _loadData() ошибка: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('❌ HomeScreen: состояние ошибки установлено');
    }
  }

  void _openSettings() async {
    print('⚙️ HomeScreen: _openSettings() НАЧАЛСЯ');
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
      print('✅ HomeScreen: вернулись из настроек, результат: $result');
      
      if (result == true) {
        print('🔄 HomeScreen: результат true, вызываем _loadData() с баннером...');
        _loadData(includeBanner: true);
      }
      print('✅ HomeScreen: _openSettings() завершен');
    } catch (e) {
      print('❌ HomeScreen: _openSettings() ошибка: $e');
    }
  }
//Аналитику пока скрыли, позже к ней вернемся
  // void _openAnalytics() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
  //   );
  // }

  void _openDayDetail(DateTime day) {
    print('📅 HomeScreen: _openDayDetail() НАЧАЛСЯ для даты: $day');
    try {
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
        print('↩️ HomeScreen: вернулись из деталей дня, перезагружаем данные с баннером...');
        _loadData(includeBanner: true);
      });
      print('✅ HomeScreen: _openDayDetail() навигация выполнена');
    } catch (e) {
      print('❌ HomeScreen: _openDayDetail() ошибка: $e');
    }
  }

  // void _closeApp() {
  //   SystemNavigator.pop();
  // }

  @override
  Widget build(BuildContext context) {
    print('🏗️ HomeScreen: build() НАЧАЛСЯ');
    try {
      final l10n = AppLocalizations.of(context)!;
      print('✅ HomeScreen: l10n получен: ${l10n.runtimeType}');
      
      // Создаем баннер только если его еще нет и мы не в процессе загрузки
      if (!isBannerAlreadyCreated && !_isLoading) {
        print('🎯 HomeScreen: создаем баннер в build()...');
        try {
          banner = _createBanner();
          setState(() {
            isBannerAlreadyCreated = true;
          });
          print('✅ HomeScreen: баннер создан в build()');
        } catch (e) {
          print('❌ HomeScreen: ошибка создания баннера в build(): $e');
        }
      }
      
      print('🎨 HomeScreen: создаем Scaffold...');
      final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          //Кнопка колокольчик для ручного вызовауведомлений - нужно было для проверки
          // IconButton(
          //   icon: const Icon(Icons.notifications),
          //   onPressed: _simulateNotification,
          //   tooltip: 'Имитация уведомления',
          // ),
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   onPressed: _loadData,
          //   tooltip: l10n.refreshTooltip,
          // ),
          //Аналитику пока скроем, после к ней вернемся
          // IconButton(
          //   icon: const Icon(Icons.analytics),
          //   onPressed: _openAnalytics,
          //   tooltip: l10n.analyticsTitle,
          // ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: l10n.settingsTooltip,
          ),
          // IconButton(
          //   icon: const Icon(Icons.close),
          //   tooltip: l10n.exitTooltip,
          //   onPressed: _closeApp,
          // ),
        ],
      ),
      body: Column(
        children: [
          // Основной контент - календарь
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
                              onPressed: () => _loadData(includeBanner: true),
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
          ),
          
          // Виджет с названием приложения внизу
          Container(
                    alignment: Alignment.bottomCenter,
                    child: isBannerAlreadyCreated ? AdWidget(bannerAd: banner) : null,
          ),
        ],
      ),
    );
    
    print('✅ HomeScreen: Scaffold создан успешно');
    return scaffold;
    
    } catch (e) {
      print('❌ HomeScreen: build() ошибка: $e');
      rethrow;
    }
  }
}