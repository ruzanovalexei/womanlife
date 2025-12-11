import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import '../widgets/calendar_widget.dart';
import '../models/settings.dart';
import '../models/period_record.dart';
import 'day_detail_screen.dart';
import 'settings_screen.dart';
import 'menu_screen.dart';




import 'package:yandex_mobileads/mobile_ads.dart';






//import 'analytics_screen.dart'; // вернуть, когда воскресим экран аналитики
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../services/permissions_service.dart';
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


  // BannerAdSize _getAdSize() {
  //   final screenWidth = MediaQuery.of(context).size.width.round();
  //   return BannerAdSize.sticky(width: screenWidth);
  // }

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


  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadData(includeBanner: false);
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    
    // Проверяем и предлагаем включить разрешения при необходимости
    if (mounted) {
      await PermissionsService.checkAndRequestPermissions(context);
    }
  }
//Этот блок нужен для ручного вызова уведомлений по кнопке - делался для проверки
  // Future<void> _simulateNotification() async {
  //   await _notificationService.showImmediateNotification();
  // }

  Future<void> _loadData({bool includeBanner = false}) async {
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
      _loadData(includeBanner: true);
    }
  }

  void _openMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MenuScreen()),
    );
  }
//Аналитику пока скрыли, позже к ней вернемся
  // void _openAnalytics() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
  //   );
  // }

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
      _loadData(includeBanner: true);
    });
  }

  // void _closeApp() {
  //   SystemNavigator.pop();
  // }

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
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _openMenu,
            tooltip: l10n.menuTitle,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: l10n.settingsTooltip,
          ),
        ],
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
          
          // Виджет рекламы
          Container(
            alignment: Alignment.bottomCenter,
            child: isBannerAlreadyCreated ? AdWidget(bannerAd: banner) : null,
          ),
        ],
      ),
    )
    );
  }
}