import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Сервис для управления баннерами и рекламой с вознаграждением с пулом и мониторингом Platform Views
class AdBannerService {
  static final AdBannerService _instance = AdBannerService._internal();
  factory AdBannerService() => _instance;
  AdBannerService._internal();

  // Флаг инициализации для предотвращения повторной инициализации
  bool _isInitialized = false;

  // Константы для оптимизации
  static const int _maxPoolSize = 3;
  static const Duration _cleanupInterval = Duration(seconds: 30);
  // Список adUnitId для round-robin ротации баннеров DEV
  static const List<String> _bannerAdUnitIds = [
    'R-M-17946414-6',
    'R-M-17946414-6',
    'R-M-17946414-6',
  ];
  // Список adUnitId для round-robin ротации баннеров Прод
  // static const List<String> _bannerAdUnitIds = [
  //   'R-M-17946414-3',
  //   'R-M-17946414-4',
  //   'R-M-17946414-5',
  // ];



  // adUnitId для рекламы с вознаграждением DEV
  static const String _rewardedAdUnitId = 'R-M-17946414-7';
  // adUnitId для рекламы с вознаграждением Прод
  // static const String _rewardedAdUnitId = 'R-M-17946414-2';

  // Пул баннеров
  final List<BannerAd> _bannerPool = [];
  final List<BannerAd> _activeBanners = [];
  
  // Rewarded Ads - загружаются только при показе
  
  // Round-robin индекс для выбора adUnitId баннеров
  int _currentBannerIndex = 0;
  
  // Мониторинг Platform Views
  int _platformViewCount = 0;
  int _totalBannersCreated = 0;
  int _totalBannersDestroyed = 0;
  
  // Статистика баннеров
  DateTime? _lastCleanup;
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
  int get activeBannerCount => _activeBanners.length;
  int get poolSize => _bannerPool.length;
  int get platformViewCount => _platformViewCount;
  int get totalBannersCreated => _totalBannersCreated;
  int get totalBannersDestroyed => _totalBannersDestroyed;
  int get failedBannerLoads => _failedBannerLoads;
  int get successfulBannerLoads => _successfulBannerLoads;
  bool get hasAvailableBanner => _bannerPool.isNotEmpty || _activeBanners.length < _maxPoolSize;

  // Getters для мониторинга rewarded ads
  int get rewardedAdShownCount => _rewardedAdShownCount;
  int get rewardedAdCompletedCount => _rewardedAdCompletedCount;

  /// Инициализация сервиса
  Future<void> initialize() async {
    // Предотвращаем повторную инициализацию
    if (_isInitialized) {
      log('AdBannerService: Already initialized, skipping...');
      return;
    }
    
    log('AdBannerService: Initializing...');
    
    // Предварительно создаем пул баннеров
    await _createBannerPool();
    
    // Запускаем периодическую очистку
    _startCleanupTimer();
    
    _isInitialized = true;
    _emitStats();
    // Rewarded ads больше не инициализируются заранее
    log('AdBannerService: Initialized successfully');
  }

  /// Создание пула баннеров заранее с разными adUnitId
  Future<void> _createBannerPool() async {
    for (int i = 0; i < _maxPoolSize; i++) {
      try {
        final adUnitId = _bannerAdUnitIds[i % _bannerAdUnitIds.length]; // Используем разные adUnitId
        final banner = await _createBanner(adUnitId);
        _bannerPool.add(banner);
        _totalBannersCreated++;
        log('AdBannerService: Created banner $i with adUnitId: $adUnitId');
      } catch (e) {
        log('AdBannerService: Failed to create banner for pool: $e');
      }
    }
  }

  /// Создание одного баннера с переиспользованием объектов
  Future<BannerAd> _createBanner(String adUnitId) async {
    // Переиспользуем объекты размеров для избежания создания новых
    final screenWidth = 320; // Стандартная ширина
    final adSize = BannerAdSize.sticky(width: screenWidth);
    
    final banner = BannerAd(
      adUnitId: adUnitId,
      adSize: adSize,
      adRequest: const AdRequest(), // Переиспользуем объект запроса
      onAdLoaded: () {
        _successfulBannerLoads++;
        _emitStats();
        log('AdBannerService: Banner loaded successfully with adUnitId: $adUnitId');
      },
      onAdFailedToLoad: (error) {
        _failedBannerLoads++;
        _emitStats();
        log('AdBannerService: Ad failed to load with adUnitId $adUnitId: $error');
      },
      onAdClicked: () => log('AdBannerService: Banner clicked with adUnitId: $adUnitId'),
      onLeftApplication: () => log('AdBannerService: Left application with adUnitId: $adUnitId'),
      onReturnedToApplication: () => log('AdBannerService: Returned to application with adUnitId: $adUnitId'),
      onImpression: (impressionData) => log('AdBannerService: Impression tracked with adUnitId: $adUnitId'),
    );
    
    return banner;
  }

  /// Получение баннера из пула или создание нового с round-robin
  Future<BannerAd?> getBanner() async {
    BannerAd? banner;
    
    // Пытаемся взять из пула
    if (_bannerPool.isNotEmpty) {
      banner = _bannerPool.removeLast();
      log('AdBannerService: Reusing banner from pool');
    } 
    // Создаем новый, если пул пуст и лимит не превышен
    else if (_activeBanners.length < _maxPoolSize) {
      try {
        // Round-robin выбор adUnitId
        final adUnitId = _bannerAdUnitIds[_currentBannerIndex % _bannerAdUnitIds.length];
        _currentBannerIndex++; // Переходим к следующему adUnitId
        
        banner = await _createBanner(adUnitId);
        _totalBannersCreated++;
        log('AdBannerService: Created new banner with adUnitId: $adUnitId (round-robin index: $_currentBannerIndex)');
      } catch (e) {
        log('AdBannerService: Failed to create new banner: $e');
        return null;
      }
    } else {
      log('AdBannerService: Maximum pool size reached');
      return null;
    }
    
    _activeBanners.add(banner);
    _platformViewCount++;
    _emitStats();
    
    return banner;
  }

  /// Возврат баннера в пул
  void returnBanner(BannerAd banner) {
    if (_activeBanners.remove(banner)) {
      _platformViewCount--;
      
      // Очищаем баннер перед возвратом в пул
      _cleanupBanner(banner);
      
      // Добавляем в пул, если есть место
      if (_bannerPool.length < _maxPoolSize) {
        _bannerPool.add(banner);
        log('AdBannerService: Banner returned to pool');
      } else {
        // Удаляем ссылку, если пул переполнен
        _destroyBanner(banner);
        log('AdBannerService: Banner reference removed (pool full)');
      }
      
      _emitStats();
    }
  }

  /// Очистка баннера для переиспользования
  void _cleanupBanner(BannerAd banner) {
    // Сброс состояния баннера для переиспользования
    // Note: BannerAd не имеет публичного метода reset, но мы можем
    // подготовить его для повторного использования
  }

  /// Удаление баннера из памяти
  void _destroyBanner(BannerAd banner) {
    try {
      // BannerAd не имеет метода destroy в текущей версии плагина
      // Просто удаляем ссылку и полагаемся на сборщик мусора
      _totalBannersDestroyed++;
      log('AdBannerService: Banner reference removed from memory');
    } catch (e) {
      log('AdBannerService: Error removing banner reference: $e');
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

  /// Запуск таймера периодической очистки
  void _startCleanupTimer() {
    Timer.periodic(_cleanupInterval, (timer) {
      _performCleanup();
    });
  }

  /// Периодическая очистка неиспользуемых баннеров
  void _performCleanup() {
    final now = DateTime.now();
    _lastCleanup = now;
    
    log('AdBannerService: Performing cleanup. Pool size: ${_bannerPool.length}, Active: ${_activeBanners.length}');
    
    // Удаляем старые баннеры из пула, если их слишком много
    while (_bannerPool.length > _maxPoolSize ~/ 2) {
      final oldBanner = _bannerPool.removeAt(0);
      _destroyBanner(oldBanner);
    }
    
    _emitStats();
  }

  /// Принудительная очистка всех ресурсов
  void dispose() {
    log('AdBannerService: Disposing all resources...');
    
    // Удаляем все баннеры из пула
    for (final banner in _bannerPool) {
      _destroyBanner(banner);
    }
    _bannerPool.clear();
    
    // Удаляем все активные баннеры
    for (final banner in _activeBanners) {
      _destroyBanner(banner);
    }
    _activeBanners.clear();
    
    // Очищаем rewarded ads
    // Rewarded ads больше не требуют дополнительной очистки
    
    _platformViewCount = 0;
    _isInitialized = false;
    _statsController.close();
    
    log('AdBannerService: All resources disposed');
  }

  /// Отправка статистики
  void _emitStats() {
    final stats = BannerStats(
      activeBanners: _activeBanners.length,
      poolSize: _bannerPool.length,
      platformViewCount: _platformViewCount,
      totalCreated: _totalBannersCreated,
      totalDestroyed: _totalBannersDestroyed,
      successfulLoads: _successfulBannerLoads,
      failedLoads: _failedBannerLoads,
      lastCleanup: _lastCleanup,
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
      log('AdBannerService: Service not initialized. Call initialize() first.');
      return null;
    }
    
    log('AdBannerService: Starting to load RewardedAd for display...');
    
    RewardedAd? ad;
    bool adLoaded = false;
    
    try {
      // Создаем RewardedAdLoader на лету
      final rewardedAdLoader = await RewardedAdLoader.create(
        onAdLoaded: (loadedAd) {
          ad = loadedAd;
          adLoaded = true;
          log('AdBannerService: RewardedAd loaded successfully for display');
        },
        onAdFailedToLoad: (error) {
          log('AdBannerService: Failed to load RewardedAd: $error');
          adLoaded = false;
        },
      );
      
      // Загружаем рекламу
      await rewardedAdLoader.loadAd(
        adRequestConfiguration: AdRequestConfiguration(adUnitId: _rewardedAdUnitId),
      );
      
      // Ждем загрузки с таймаутом
      int attempts = 0;
      const maxAttempts = 50; // Максимум 5 секунд (50 * 100ms)
      
      while (!adLoaded && attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      if (!adLoaded || ad == null) {
        log('AdBannerService: RewardedAd failed to load within timeout');
        
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
            log('AdBannerService: RewardedAd shown');
          },
          onAdFailedToShow: (error) {
            log('AdBannerService: RewardedAd failed to show: $error');
            ad!.destroy();
          },
          onAdClicked: () {
            onAdClicked?.call();
            log('AdBannerService: RewardedAd clicked');
          },
          onAdDismissed: () {
            log('AdBannerService: RewardedAd dismissed');
            ad!.destroy();
            onAdDismissed?.call();
          },
          onAdImpression: (impressionData) {
            log('AdBannerService: RewardedAd impression recorded');
          },
          onRewarded: (Reward reward) {
            _rewardedAdCompletedCount++;
            onAdCompleted?.call(reward);
            log('AdBannerService: RewardedAd completed - reward granted: ${reward.amount} ${reward.type}');
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
      log('AdBannerService: Error showing RewardedAd: $e');
      
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
- Active banners: $_activeBanners.length
- Pool size: ${_bannerPool.length}
- Platform Views: $_platformViewCount
- Total created: $_totalBannersCreated
- Total references removed: $_totalBannersDestroyed
- Successful banner loads: $_successfulBannerLoads
- Failed banner loads: $_failedBannerLoads
- RewardedAd shown count: $_rewardedAdShownCount
- RewardedAd completed count: $_rewardedAdCompletedCount
- Last cleanup: ${_lastCleanup ?? 'Never'}
''';
  }
}

/// Виджет баннера с автоматическим управлением жизненным циклом
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
    log('BannerWidget: Initialized');
    // Загружаем баннер, когда виджет инициализируется
    // widget.bannerAd.load();
  }

  @override
  void dispose() {
    // Возвращаем баннер в пул при уничтожении виджета
    AdBannerService().returnBanner(widget.bannerAd);
    super.dispose();
    log('BannerWidget: Disposed and banner returned to pool');
  }

  @override
 Widget build(BuildContext context) {
    // Оборачиваем AdWidget в IgnorePointer, чтобы избежать случайных нажатий,
    // если это нежелательное поведение для текущего сценария.
    return IgnorePointer(
      ignoring: true, // Всегда игнорировать жесты
      child: SizedBox( 
        // Yandex sticky баннер обычно имеет высоту 50px
        // height: 50, // Задаем ожидаемую высоту, чтобы зарезервировать место, если нужно
        child: _createAdWidget(),
      ),
    );
  }

  Widget _createAdWidget() {
    // Используем рефлексию для доступа к AdWidget, если он доступен
    try {
      return AdWidget(bannerAd: widget.bannerAd);
    } catch (e) {
      log('BannerWidget: AdWidget not available, using placeholder: $e');
      return Container(
        // height: 50, // Соответствует ожидаемому размеру баннера
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
/// totalDestroyed - количество баннеров, чьи ссылки были удалены из памяти
class BannerStats {
  final int activeBanners;
  final int poolSize;
  final int platformViewCount;
  final int totalCreated;
  final int totalDestroyed;
  final int successfulLoads;
  final int failedLoads;
  final DateTime? lastCleanup;

  const BannerStats({
    required this.activeBanners,
    required this.poolSize,
    required this.platformViewCount,
    required this.totalCreated,
    required this.totalDestroyed,
    required this.successfulLoads,
    required this.failedLoads,
    required this.lastCleanup,
  });

  @override
  String toString() {
    return 'BannerStats(active: $activeBanners, pool: $poolSize, views: $platformViewCount)';
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