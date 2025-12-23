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
  
  // Rewarded Ads
  RewardedAdLoader? _rewardedAdLoader;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;
  bool _isRewardedAdLoaded = false;
  
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
  int _rewardedAdLoadAttempts = 0;
  int _successfulRewardedAdLoads = 0;
  int _failedRewardedAdLoads = 0;
  int _rewardedAdShownCount = 0;
  int _rewardedAdCompletedCount = 0;

  // Stream для мониторинга
  final StreamController<BannerStats> _statsController = 
      StreamController<BannerStats>.broadcast();
  Stream<BannerStats> get statsStream => _statsController.stream;

  // Stream для мониторинга rewarded ads
  final StreamController<RewardedAdStats> _rewardedStatsController = 
      StreamController<RewardedAdStats>.broadcast();
  Stream<RewardedAdStats> get rewardedAdStatsStream => _rewardedStatsController.stream;

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
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isRewardedAdLoading => _isRewardedAdLoading;
  int get rewardedAdLoadAttempts => _rewardedAdLoadAttempts;
  int get successfulRewardedAdLoads => _successfulRewardedAdLoads;
  int get failedRewardedAdLoads => _failedRewardedAdLoads;
  int get rewardedAdShownCount => _rewardedAdShownCount;
  int get rewardedAdCompletedCount => _rewardedAdCompletedCount;
  bool get hasAvailableRewardedAd => _isRewardedAdLoaded && _rewardedAd != null;

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
    _emitRewardedAdStats();
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
    // _cleanupRewardedAd();
    
    // // Уничтожаем RewardedAdLoader если он существует
    // if (_rewardedAdLoader != null) {
    //   try {
    //     _rewardedAdLoader!.destroy();
    //   } catch (e) {
    //     log('AdBannerService: Error destroying RewardedAdLoader: $e');
    //   }
    //   _rewardedAdLoader = null;
    // }
    
    _platformViewCount = 0;
    _isInitialized = false;
    _statsController.close();
    // _rewardedStatsController.close();
    
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

  /// Отправка статистики rewarded ads
  void _emitRewardedAdStats() {
    final rewardedStats = RewardedAdStats(
      isLoaded: _isRewardedAdLoaded,
      isLoading: _isRewardedAdLoading,
      loadAttempts: _rewardedAdLoadAttempts,
      successfulLoads: _successfulRewardedAdLoads,
      failedLoads: _failedRewardedAdLoads,
      shownCount: _rewardedAdShownCount,
      completedCount: _rewardedAdCompletedCount,
    );
    
    _rewardedStatsController.add(rewardedStats);
  }

  /// Инициализация rewarded ad
  Future<void> _initializeRewardedAd() async {
    if (_rewardedAdLoader != null) {
      log('AdBannerService: RewardedAdLoader already initialized');
      return;
    }
    
    try {
      // Создаем RewardedAdLoader через фабричный метод
      _rewardedAdLoader = await RewardedAdLoader.create(
        onAdLoaded: _onRewardedAdLoaded,
        onAdFailedToLoad: _onRewardedAdFailedToLoad,
      );
      
      log('AdBannerService: RewardedAdLoader initialized');
    } catch (e) {
      log('AdBannerService: Failed to initialize RewardedAdLoader: $e');
      rethrow;
    }
  }

  /// Callback для успешной загрузки rewarded ad
  void _onRewardedAdLoaded(RewardedAd ad) {
    _rewardedAd = ad;
    _isRewardedAdLoaded = true;
    _isRewardedAdLoading = false;
    _successfulRewardedAdLoads++;
    _emitRewardedAdStats();
    log('AdBannerService: RewardedAd loaded successfully');
  }

  /// Callback для неудачной загрузки rewarded ad
  void _onRewardedAdFailedToLoad(dynamic error) {
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
    _isRewardedAdLoading = false;
    _failedRewardedAdLoads++;
    _emitRewardedAdStats();
    log('AdBannerService: RewardedAd failed to load: $error');
  }

  /// Загрузка rewarded ad
  Future<bool> loadRewardedAd() async {
    if (!_isInitialized) {
      log('AdBannerService: Service not initialized. Call initialize() first.');
      return false;
    }
    
    if (_isRewardedAdLoading) {
      log('AdBannerService: RewardedAd is already loading...');
      return false;
    }
    
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      log('AdBannerService: RewardedAd already loaded and ready');
      return true;
    }
    
    // Инициализируем loader если нужно
    if (_rewardedAdLoader == null) {
      await _initializeRewardedAd();
    }
    
    _isRewardedAdLoading = true;
    _rewardedAdLoadAttempts++;
    _emitRewardedAdStats();
    
    try {
      await _rewardedAdLoader!.loadAd(
        adRequestConfiguration: AdRequestConfiguration(adUnitId: _rewardedAdUnitId),
      );
      log('AdBannerService: RewardedAd load request sent');
      return true;
    } catch (e) {
      _isRewardedAdLoading = false;
      _failedRewardedAdLoads++;
      _emitRewardedAdStats();
      log('AdBannerService: Failed to load RewardedAd: $e');
      return false;
    }
  }

  /// Получение загруженного rewarded ad
  Future<RewardedAd?> getRewardedAd() async {
    if (!_isInitialized) {
      log('AdBannerService: Service not initialized. Call initialize() first.');
      return null;
    }
    
    // Если ad уже загружен, возвращаем его
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      return _rewardedAd;
    }
    
    // Иначе пытаемся загрузить
    final loaded = await loadRewardedAd();
    if (loaded) {
      // Ждем немного для загрузки
      await Future.delayed(const Duration(milliseconds: 100));
      return _rewardedAd;
    }
    
    return null;
  }

  /// Показ rewarded ad с обработкой результата
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
    
    RewardedAd? ad = await getRewardedAd();
    if (ad == null) {
      log('AdBannerService: No RewardedAd available to show');
      return null;
    }
    
    _rewardedAdShownCount++;
    _emitRewardedAdStats();
    onAdShown?.call();
    
    try {
      // Устанавливаем слушатель событий
      ad.setAdEventListener(
        eventListener: RewardedAdEventListener(
          onAdShown: () {
            log('AdBannerService: RewardedAd shown');
          },
          onAdFailedToShow: (error) {
            log('AdBannerService: RewardedAd failed to show: $error');
            ad.destroy();
            _rewardedAd = null;
            _isRewardedAdLoaded = false;
            _emitRewardedAdStats();
            loadRewardedAd();
          },
          onAdClicked: () {
            onAdClicked?.call();
            log('AdBannerService: RewardedAd clicked');
          },
          onAdDismissed: () {
            log('AdBannerService: RewardedAd dismissed');
            ad.destroy();
            _rewardedAd = null;
            _isRewardedAdLoaded = false;
            _emitRewardedAdStats();
            onAdDismissed?.call();
            // Загружаем новую рекламу после закрытия
            loadRewardedAd();
          },
          onAdImpression: (impressionData) {
            log('AdBannerService: RewardedAd impression recorded');
          },
          onRewarded: (Reward reward) {
            _rewardedAdCompletedCount++;
            _emitRewardedAdStats();
            onAdCompleted?.call(reward);
            log('AdBannerService: RewardedAd completed - reward granted: ${reward.amount} ${reward.type}');
          },
        ),
      );
      
      // Показываем рекламу
      await ad.show();
      
      // Ждем завершения просмотра
      final reward = await ad.waitForDismiss();
      
      return reward;
    } catch (e) {
      log('AdBannerService: Error showing RewardedAd: $e');
      return null;
    }
  }

  // /// Очистка rewarded ad
  // void _cleanupRewardedAd() {
  //   if (_rewardedAd != null) {
  //     _rewardedAd = null;
  //   }
  //   _isRewardedAdLoaded = false;
  //   _isRewardedAdLoading = false;
  //   _emitRewardedAdStats();
  // }

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
- RewardedAd loaded: $_isRewardedAdLoaded
- RewardedAd loading: $_isRewardedAdLoading
- RewardedAd load attempts: $_rewardedAdLoadAttempts
- Successful RewardedAd loads: $_successfulRewardedAdLoads
- Failed RewardedAd loads: $_failedRewardedAdLoads
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
  final bool isLoaded;
  final bool isLoading;
  final int loadAttempts;
  final int successfulLoads;
  final int failedLoads;
  final int shownCount;
  final int completedCount;

  const RewardedAdStats({
    required this.isLoaded,
    required this.isLoading,
    required this.loadAttempts,
    required this.successfulLoads,
    required this.failedLoads,
    required this.shownCount,
    required this.completedCount,
  });

  @override
  String toString() {
    return 'RewardedAdStats(loaded: $isLoaded, loading: $isLoading, shown: $shownCount, completed: $completedCount)';
  }
}