import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Сервис для управления баннерами и рекламой с вознаграждением
class AdBannerService {
  static final AdBannerService _instance = AdBannerService._internal();
  factory AdBannerService() => _instance;
  AdBannerService._internal();

  // Флаг инициализации для предотвращения повторной инициализации
  bool _isInitialized = false;

  // Список adUnitId для round-robin ротации баннеров DEV
  static const List<String> _bannerAdUnitIds = [
    'R-M-17946414-13',
    'R-M-17946414-14',
    'R-M-17946414-15',
    'R-M-17946414-16',
    'R-M-17946414-17',
    'R-M-17946414-18',
    'R-M-17946414-19',
    'R-M-17946414-20',
    'R-M-17946414-21',
    'R-M-17946414-22',
  ];
  // Список adUnitId для round-robin ротации баннеров Прод R-M-17946414-6
  // static const List<String> _bannerAdUnitIds = [
  //   'R-M-17946414-3',
  //   'R-M-17946414-4',
  //   'R-M-17946414-5',
  // ];



  // adUnitId для рекламы с вознаграждением DEV
  static const String _rewardedAdUnitId = 'R-M-17946414-2';
  // adUnitId для рекламы с вознаграждением Прод
  //  static const String _rewardedAdUnitId = 'R-M-17946414-2';

  // Счётчик созданных баннеров
  int _totalBannersCreated = 0;
  
  // Round-robin индекс для выбора adUnitId баннеров
  int _currentBannerIndex = 0;
  
  // Статистика баннеров
  int _failedBannerLoads = 0;
  int _successfulBannerLoads = 0;
  
  // Статистика rewarded ads
  int _rewardedAdShownCount = 0;
  int _rewardedAdCompletedCount = 0;

  // Stream для мониторинга
  final StreamController<BannerStats> _statsController = 
      StreamController<BannerStats>.broadcast();
  Stream<BannerStats> get statsStream => _statsController.stream;

  

  // Getters для мониторинга баннеров
  int get totalBannersCreated => _totalBannersCreated;
  int get failedBannerLoads => _failedBannerLoads;
  int get successfulBannerLoads => _successfulBannerLoads;

  // Getters для мониторинга rewarded ads
  int get rewardedAdShownCount => _rewardedAdShownCount;
  int get rewardedAdCompletedCount => _rewardedAdCompletedCount;

  /// Инициализация сервиса
  Future<void> initialize() async {
    // Предотвращаем повторную инициализацию
    if (_isInitialized) {
      // debugPrint('AdBannerService: Already initialized, skipping...');
      return;
    }
    
    // debugPrint('AdBannerService: Initializing...');
    
    _isInitialized = true;
    _emitStats();
    // debugPrint('AdBannerService: Initialized successfully');
  }

  /// Создание одного баннера
  Future<BannerAd> _createBanner(String adUnitId) async {
    final screenWidth = 320;
    final adSize = BannerAdSize.sticky(width: screenWidth);
    
    final banner = BannerAd(
      adUnitId: adUnitId,
      adSize: adSize,
      adRequest: const AdRequest(),
      onAdLoaded: () {
        _successfulBannerLoads++;
        _emitStats();
        debugPrint('AdBannerService: Banner loaded successfully with adUnitId: $adUnitId');
      },
      onAdFailedToLoad: (error) {
        _failedBannerLoads++;
        _emitStats();
        // debugPrint('AdBannerService: Ad failed to load with adUnitId $adUnitId: $error');
      },
      // onAdClicked: () => debugPrint('AdBannerService: Banner clicked with adUnitId: $adUnitId'),
      // onLeftApplication: () => debugPrint('AdBannerService: Left application with adUnitId: $adUnitId'),
      // onReturnedToApplication: () => debugPrint('AdBannerService: Returned to application with adUnitId: $adUnitId'),
      // onImpression: (impressionData) => debugPrint('AdBannerService: Impression tracked with adUnitId: $adUnitId'),
    );
    
    return banner;
  }

  /// Получение баннера по запросу с round-robin
  Future<BannerAd?> getBanner() async {
    // Round-robin выбор adUnitId
    final adUnitId = _bannerAdUnitIds[_currentBannerIndex % _bannerAdUnitIds.length];
    // debugPrint('AdBannerService: Requesting banner with adUnitId: $adUnitId (index: ${_currentBannerIndex % _bannerAdUnitIds.length})');
    
    // Переходим к следующему adUnitId для следующего запроса
    _currentBannerIndex++;
    
    try {
      final banner = await _createBanner(adUnitId);
      _totalBannersCreated++;
      // debugPrint('AdBannerService: Created new banner with adUnitId: $adUnitId');
      _emitStats();
      return banner;
    } catch (e) {
      // debugPrint('AdBannerService: Failed to create banner: $e');
      return null;
    }
  }
    
  /// Создание виджета баннера с автоматическим управлением
  Widget createBannerWidget() {
    return FutureBuilder<BannerAd?>(
      future: getBanner(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 50, // Ожидаемая высота баннера
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          // Если произошла ошибка при загрузке баннера, отображаем пустой контейнер на месте баннера,
          // чтобы не нарушать разметку.
          return const SizedBox.shrink(); // Или можно показать запасной виджет
        } else if (snapshot.hasData && snapshot.data != null) {
          return BannerWidget(bannerAd: snapshot.data!);
        } else {
          // Если данных нет (например getBanner вернул null), также показываем пустой контейнер.
          return const SizedBox.shrink();
        }
      },
    );
  }

  /// Принудительная очистка всех ресурсов
  void dispose() {
    // debugPrint('AdBannerService: Disposing all resources...');
    
    _isInitialized = false;
    _statsController.close();
    
    // debugPrint('AdBannerService: All resources disposed');
  }

  /// Отправка статистики
  void _emitStats() {
    final stats = BannerStats(
      totalCreated: _totalBannersCreated,
      successfulLoads: _successfulBannerLoads,
      failedLoads: _failedBannerLoads,
    );
    
    _statsController.add(stats);
  }

  

  

  /// Показ rewarded ad с загрузкой рекламы на лету
  Future<Reward?> showRewardedAd({
    required BuildContext context,
    Function()? onAdShown,
    Function(Reward)? onAdCompleted,
    Function()? onAdDismissed,
    Function()? onAdClicked,
  }) async {
    if (!_isInitialized) {
      // debugPrint('AdBannerService: Service not initialized. Call initialize() first.');
      return null;
    }
    
    // debugPrint('AdBannerService: Starting to load RewardedAd for display...');
    
    RewardedAd? ad;
    bool adLoaded = false;
    
    try {
      // Создаем RewardedAdLoader на лету
      final rewardedAdLoader = await RewardedAdLoader.create(
        onAdLoaded: (loadedAd) {
          ad = loadedAd;
          adLoaded = true;
          // debugPrint('AdBannerService: RewardedAd loaded successfully for display');
        },
        onAdFailedToLoad: (error) {
          // debugPrint('AdBannerService: Failed to load RewardedAd: $error');
          adLoaded = false;
        },
      );
      
      // Загружаем рекламу
      await rewardedAdLoader.loadAd(
        adRequestConfiguration: AdRequestConfiguration(adUnitId: _rewardedAdUnitId),
      );
      
      // Ждем загрузки с таймаутом
      int attempts = 0;
      const maxAttempts = 100; // Максимум 5 секунд (50 * 100ms)
      
      while (!adLoaded && attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      if (!adLoaded || ad == null) {
        // debugPrint('AdBannerService: RewardedAd failed to load within timeout');
        
        // Показываем диалог с ошибкой
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Реклама недоступна'),
                content: const Text(
                  'Нет рекламы для показа: проверьте соединение с интернетом или отключите блокировщик рекламы'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Понятно'),
                  ),
                ],
              );
            },
          );
        }
        
        return null;
      }
      
      _rewardedAdShownCount++;
      onAdShown?.call();
      
      // Устанавливаем слушатель событий
      ad!.setAdEventListener(
        eventListener: RewardedAdEventListener(
          onAdShown: () {
            // debugPrint('AdBannerService: RewardedAd shown');
          },
          onAdFailedToShow: (error) {
            // debugPrint('AdBannerService: RewardedAd failed to show: $error');
            ad!.destroy();
          },
          onAdClicked: () {
            onAdClicked?.call();
            // debugPrint('AdBannerService: RewardedAd clicked');
          },
          onAdDismissed: () {
            // debugPrint('AdBannerService: RewardedAd dismissed');
            ad!.destroy();
            onAdDismissed?.call();
          },
          onAdImpression: (impressionData) {
            // debugPrint('AdBannerService: RewardedAd impression recorded');
          },
          onRewarded: (Reward reward) {
            _rewardedAdCompletedCount++;
            onAdCompleted?.call(reward);
            // debugPrint('AdBannerService: RewardedAd completed - reward granted: ${reward.amount} ${reward.type}');
          },
        ),
      );
      
      // Показываем рекламу
      await ad!.show();
      
      // Ждем завершения просмотра
      final reward = await ad!.waitForDismiss();
      
      // Уничтожаем ad после показа
      ad!.destroy();
      
      return reward;
    } catch (e) {
      // debugPrint('AdBannerService: Error showing RewardedAd: $e');
      
      // Показываем диалог с ошибкой при исключении
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Ошибка загрузки рекламы'),
              content: const Text(
                'Нет рекламы для показа: проверьте соединение с интернетом или отключите блокировщик рекламы'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Понятно'),
                ),
              ],
            );
          },
        );
      }
      
      return null;
    }
  }

  

  /// Получение отчета о состоянии
  String getReport() {
    return '''
AdBannerService Report:
- Total created: $_totalBannersCreated
- Successful banner loads: $_successfulBannerLoads
- Failed banner loads: $_failedBannerLoads
- RewardedAd shown count: $_rewardedAdShownCount
- RewardedAd completed count: $_rewardedAdCompletedCount
''';
  }
}

/// Виджет баннера
class BannerWidget extends StatefulWidget {
  final BannerAd bannerAd;
  
  const BannerWidget({
    super.key,
    required this.bannerAd,
  });

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  @override
  void initState() {
    super.initState();
    // debugPrint('BannerWidget: Initialized');
  }

  @override
  void dispose() {
    super.dispose();
    // debugPrint('BannerWidget: Disposed');
  }

  @override
 Widget build(BuildContext context) {
    // Оборачиваем AdWidget в IgnorePointer, чтобы избежать случайных нажатий,
    // если это нежелательное поведение для текущего сценария.
    return IgnorePointer(
      ignoring: true, // Всегда игнорировать жесты
      child: SizedBox( 
        // Yandex sticky баннер обычно имеет высоту 50px
        height: 50, // Задаем ожидаемую высоту, чтобы зарезервировать место, если нужно
        child: _createAdWidget(),
      ),
    );
  }

  Widget _createAdWidget() {
    // Используем рефлексию для доступа к AdWidget, если он доступен
    try {
      return AdWidget(bannerAd: widget.bannerAd);
    } catch (e) {
      // debugPrint('BannerWidget: AdWidget not available, using placeholder: $e');
      return Container(
        height: 50, // Соответствует ожидаемому размеру баннера
        // width: double.infinity,
        color: Colors.grey[300],
        child: const Center(
          child: Text('Ad loading...'),
        ),
      );
    }
  }
}

/// Класс для статистики баннеров
class BannerStats {
  final int totalCreated;
  final int successfulLoads;
  final int failedLoads;

  const BannerStats({
    required this.totalCreated,
    required this.successfulLoads,
    required this.failedLoads,
  });

  @override
  String toString() {
    return 'BannerStats(created: $totalCreated, success: $successfulLoads, failed: $failedLoads)';
  }
}

/// Класс для статистики rewarded ads
class RewardedAdStats {
  final int shownCount;
  final int completedCount;

  const RewardedAdStats({
    required this.shownCount,
    required this.completedCount,
  });

  @override
  String toString() {
    return 'RewardedAdStats(shown: $shownCount, completed: $completedCount)';
  }
}