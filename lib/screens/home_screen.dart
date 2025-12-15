import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import '../widgets/calendar_widget.dart';
import '../models/settings.dart';
import '../models/period_record.dart';
import 'day_detail_screen.dart';
// import 'settings_screen.dart';
// import 'menu_screen.dart';




import 'package:yandex_mobileads/mobile_ads.dart';






//import 'analytics_screen.dart'; // вернуть, когда воскресим экран аналитики
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../services/permissions_service.dart';
//import '../utils/date_utils.dart'; // Добавляем импорт
class HomeScreen extends StatefulWidget {
  final bool calledFromDetailScreen; // Указывает, был ли вызван из детального экрана

  const HomeScreen({
    super.key,
    this.calledFromDetailScreen = false,
  });

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
  DateTime _lastSelectedDate = DateTime.now(); // Добавляем последнюю выбранную дату
  static const _backgroundImage = AssetImage('assets/images/fon1.png');

  late BannerAd banner;
  var isBannerAlreadyCreated = false;

  _createBanner() {
    final screenWidth = MediaQuery.of(context).size.width.round();
    final adSize = BannerAdSize.sticky(width: screenWidth);
    
    return BannerAd(
      adUnitId: 'R-M-17946414-4',
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
    _initializeBanner();
    _loadData(includeBanner: false);
  }


  void _initializeBanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        banner = _createBanner();
        setState(() {
          isBannerAlreadyCreated = true;
        });
      }
    });
  }


  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    
    // Проверяем и предлагаем включить разрешения при необходимости
    if (mounted) {
      await PermissionsService.checkAndRequestPermissions(context);
    }
  }


  Future<void> _loadData({bool includeBanner = false}) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
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

  // void _openSettings() async {
  //   final result = await Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => const SettingsScreen()),
  //   );
    
  //   if (result == true) {
  //     _loadData(includeBanner: true);
  //   }
  // }

  // void _openMenu() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => const MenuScreen()),
  //   );
  // }
//Аналитику пока скрыли, позже к ней вернемся
  // void _openAnalytics() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
  //   );
  // }

  void _openDayDetail(DateTime day) {
    setState(() {
      _lastSelectedDate = day; // Обновляем последнюю выбранную дату
    });
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayDetailScreen(
          selectedDate: day,
          periodRecords: _periodRecords,
          settings: _settings,
          shouldReturnResult: true, // Указываем, что нужно возвращать результат
        ),
      ),
    ).then((returnedDate) {
      // Если из детального экрана вернулась дата, обновляем _lastSelectedDate
      if (returnedDate != null && returnedDate is DateTime) {
        setState(() {
          _lastSelectedDate = returnedDate;
        });
      }
      _loadData(includeBanner: true);
    });
  }

  void _backToDayDetail() {
    if (widget.calledFromDetailScreen) {
      // Если были вызваны из детального экрана, просто возвращаемся назад
      Navigator.pop(context, _lastSelectedDate);
    } else {
      // Иначе открываем новый детальный экран
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DayDetailScreen(
            selectedDate: _lastSelectedDate,
            periodRecords: _periodRecords,
            settings: _settings,
            shouldReturnResult: true,
          ),
        ),
      ).then((returnedDate) {
        // Если из детального экрана вернулась дата, обновляем _lastSelectedDate
        if (returnedDate != null && returnedDate is DateTime) {
          setState(() {
            _lastSelectedDate = returnedDate;
          });
        }
        _loadData(includeBanner: true);
      });
    }
  }

  // void _closeApp() {
  //   SystemNavigator.pop();
  // }

  @override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _backToDayDetail,
        tooltip: 'Назад к деталям дня',
      ),
      title: Text(l10n.calendar),
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
          Expanded(
            child: _buildMainContent(l10n),
          ),
          _buildBanner(),
        ],
      ),
    ),
  );
}


  Widget _buildMainContent(AppLocalizations l10n) {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  
  if (_errorMessage != null) {
    return _buildErrorWidget(l10n);
  }
  
  return CalendarWidget(
    onDaySelected: _openDayDetail,
    settings: _settings,
    periodRecords: _periodRecords,
  );
}

Widget _buildErrorWidget(AppLocalizations l10n) {
  return Center(
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
  );
}

// Widget _buildBanner() {
//   return Container(
//     alignment: Alignment.bottomCenter,
//     child: isBannerAlreadyCreated ? AdWidget(bannerAd: banner) : const SizedBox.shrink(),
//   );
// }
  Widget _buildBanner() {
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