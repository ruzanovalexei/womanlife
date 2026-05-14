import 'dart:async';

// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/models/settings.dart';
import 'package:period_tracker/models/period_record.dart';
import 'package:period_tracker/utils/date_utils.dart';
import 'package:period_tracker/services/ad_banner_service.dart';
import 'package:period_tracker/services/speech_service.dart';
// import 'package:period_tracker/services/update_service.dart';
import 'package:period_tracker/screens/day_detail_screen.dart';
import 'package:period_tracker/screens/settings_screen.dart';
import 'package:period_tracker/screens/lists_screen.dart';
import 'package:period_tracker/screens/notes_screen.dart';
import 'package:period_tracker/screens/habits_screen.dart';
// import 'package:period_tracker/screens/analytics_screen.dart';
import 'package:period_tracker/screens/day_report_screen.dart';
import 'package:period_tracker/screens/planner_screen.dart';
// import 'package:period_tracker/screens/medications_screen.dart';
// import 'package:yandex_mobileads/mobile_ads.dart';analytics_screen.dart
// import 'package:yandex_mobileads/ad_widget.dart'; // Добавляем импорт AdWidget

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _databaseHelper = DatabaseHelper();
  final _adBannerService = AdBannerService();
  final _speechService = SpeechService();
  
  late Settings _settings;
  List<PeriodRecord> _periodRecords = [];
  bool _isLoading = true;
    Timer? _bannerRefreshTimer;
  // Виджет баннера создается один раз и переиспользуется
  Widget? _bannerWidget;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _initializeBannerWidget();
  }

  void _initializeBannerWidget() {
    if (_bannerWidget == null) {
      _bannerWidget = _adBannerService.createBannerWidget();
      if (mounted) {
        setState(() {});
      }
    }
    // Запускаем таймер обновления баннера каждые 4 секунды
    _bannerRefreshTimer?.cancel();
    _bannerRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _refreshBanner();
      }
    });
  }

  @override
  void dispose() {
    // Очищаем виджет баннера при уничтожении экрана
     _bannerRefreshTimer?.cancel();
    _bannerWidget = null;
    super.dispose();
  }

  void _refreshBanner() {
    _bannerWidget = _adBannerService.createBannerWidget();
    if (mounted) {
      setState(() {});
    }
  }
  // Оптимизированная инициализация экрана - только легкие операции
  void _initializeScreen() {
    // Переносим загрузку данных в post-frame callback для лучшей производительности
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
        _initializeServices();
        _initializeBannerWidget();
        // _checkForUpdates();
      }
    });
  }

  // Проверка обновлений приложения
  // Future<void> _checkForUpdates() async {
  //   try {
  //     final hasUpdate = await updateService.checkForUpdates();
  //     if (hasUpdate && mounted) {
  //       await updateService.showUpdateDialog(context);
  //     }
  //   } catch (e) {
  //     debugPrint('UpdateService: Error showing dialog: $e');
  //   }
  // }

  // Инициализация виджета баннера - создается один раз
  // void _initializeBannerWidget() {
  //   if (_bannerWidget == null) {
  //     _bannerWidget = _adBannerService.createBannerWidget();
  //     if (mounted) {
  //       setState(() {});
  //     }
  //   }
  // }

  // Инициализация сервисов
  Future<void> _initializeServices() async {
    try {
      // Инициализируем сервис баннеров
      // await _adBannerService.initialize();
      // await _adBannerService.loadRewardedAd(); // Загружаем рекламу при инициализации экрана
      
      // Инициализируем сервис распознавания речи
      await _speechService.initialize();
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  // Оптимизированная загрузка данных - один setState
  Future<void> _loadData() async {
    try {
      // Параллельная загрузка данных
      final results = await Future.wait([
        _databaseHelper.getSettings(),
        _databaseHelper.getAllPeriodRecords(),
      ]);
      
      final settings = results[0] as Settings;
      final periodRecords = results[1] as List<PeriodRecord>;
      
      if (mounted) {
        setState(() {
          _settings = settings;
          _periodRecords = periodRecords;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('Error loading data: $e');
      }
    }
  }

  Future<void> _onMenuItemTap(int index) async {
    switch (index) {
      case 0:
        // Кнопка "Здоровье" - открываем детальный экран на текущую дату
        if (!_isLoading) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DayDetailScreen(
                selectedDate: MyDateUtils.getUtcToday(),
                periodRecords: _periodRecords,
                settings: _settings,
                shouldReturnResult: false,
              ),
            ),
          ).then((_) {
            _loadData(); // Обновляем данные при возврате
            // Убираем создание нового виджета баннера - он уже существует
          });
        }
        break;
      case 111:
      //Вызов рекламы за вознаграждение
        // await _adBannerService.showRewardedAd(
        //   context: context,
        //   onAdCompleted: (reward) {
        //   // Выдать награду пользователю
        //           Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => const DayReportScreen()),
        // ).then((_) {
        //   _loadData();
        //   // Убираем создание нового виджета баннера - он уже существует
        // });
        //   print('Получено: ${reward.amount} ${reward.type}');
        //   },
        //     onAdDismissed: () {
        //       print('Реклама закрыта');
        //   },
        //   );
        // break;
                Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DayReportScreen()),
        ).then((_) {
          _loadData();
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListsScreen()),
        ).then((_) {
          _loadData();
          // Убираем создание нового виджета баннера - он уже существует
        });
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HabitsScreen()),
        ).then((_) {
          _loadData();
          // Убираем создание нового виджета баннера - он уже существует
        });
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotesScreen()),
        ).then((_) {
          _loadData();
          // Убираем создание нового виджета баннера - он уже существует
        });
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlannerScreen()),
        ).then((_) {
          _loadData();
        });
        break;
      case 6:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        ).then((_) {
          _loadData();
          // Убираем создание нового виджета баннера - он уже существует
        });
        break;
    }
  }
static const _backgroundImage = AssetImage('assets/images/fon1.png');


@override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.menuTitle),
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMenuContent(l10n),
            ),
          // // Добавляем отступ в 20 пикселей
          //   const SizedBox(height: 20.0),
            // Блок рекламы - используем созданный один раз виджет
            if (_bannerWidget != null) ...[
              _bannerWidget!,
            ] else ...[
              // Показываем загрузку, если виджет еще не создан
              const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Вынесенный в отдельный метод контент меню с автовысотой
  // Вынесенный в отдельный метод контент меню
  Widget _buildMenuContent(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.book,
            title: l10n.menu0,
            color: Colors.pink[200]!,
            onTap: () => _onMenuItemTap(111),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.favorite,
            title: l10n.menu1,
            color: Colors.pink[200]!,
            onTap: () => _onMenuItemTap(0),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.calendar_today,
            title: l10n.plannerTitle,
            color: Colors.pink[200]!,
            onTap: () => _onMenuItemTap(5),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.checklist,
            title: l10n.menu3,
            color: Colors.pink[200]!,
            onTap: () => _onMenuItemTap(2),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.loop,
            title: l10n.menu4,
            color:  Colors.pink[200]!,
            onTap: () => _onMenuItemTap(3),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.note,
            title: l10n.menu5,
            color: Colors.pink[200]!,
            onTap: () => _onMenuItemTap(4),
          ),

          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.settings,
            title: l10n.settingsTitle,
            color: Colors.pink[200]!,
            onTap: () => _onMenuItemTap(6),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Обновленный виджет баннера с использованием сервиса
  // Widget _buildBannerWidget() {
  //   return _adBannerService.createBannerWidget();
  // }

  // // Отладочный виджет для мониторинга производительности
  // Widget _buildDebugInfo() {
  //   return SizedBox(
  //     height: 120,
  //     child: Container(
  //       margin: const EdgeInsets.all(8),
  //       padding: const EdgeInsets.all(8),
  //       decoration: BoxDecoration(
  //         color: Colors.black54,
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const Text(
  //             '🔍 Performance Debug Info',
  //             style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 4),
  //           Expanded(
  //             child: StreamBuilder<BannerStats>(
  //               stream: _adBannerService.statsStream,
  //               builder: (context, snapshot) {
  //                 if (!snapshot.hasData) return const SizedBox.shrink();
                  
  //                 final stats = snapshot.data!;
  //                 return Text(
  //                   '📊 Active: ${stats.activeBanners} | Pool: ${stats.poolSize} | Views: ${stats.platformViewCount}\n'
  //                   '✅ Created: ${stats.totalCreated} | 🗑️ Destroyed: ${stats.totalDestroyed}\n'
  //                   '📈 Success: ${stats.successfulLoads} | ❌ Failed: ${stats.failedLoads}',
  //                   style: const TextStyle(color: Colors.white70, fontSize: 10),
  //                 );
  //               },
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

   Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.pink[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}