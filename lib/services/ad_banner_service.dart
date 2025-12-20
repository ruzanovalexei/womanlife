import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Сервис для управления баннерами с пулом и мониторингом Platform Views
class AdBannerService {
  static final AdBannerService _instance = AdBannerService._internal();
  factory AdBannerService() => _instance;
  AdBannerService._internal();

  // Константы для оптимизации
  static const int _maxPoolSize = 3;
  static const Duration _cleanupInterval = Duration(seconds: 30);
  // Тестовый adUnitId для разработки
  static const String _adUnitId = 'R-M-17946414-3';

  // Пул баннеров
  final List<BannerAd> _bannerPool = [];
  final List<BannerAd> _activeBanners = [];
  
  // Мониторинг Platform Views
  int _platformViewCount = 0;
  int _totalBannersCreated = 0;
  int _totalBannersDestroyed = 0;
  
  // Статистика
  DateTime? _lastCleanup;
  int _failedAdLoads = 0;
  int _successfulAdLoads = 0;

  // Stream для мониторинга
  final StreamController<BannerStats> _statsController = 
      StreamController<BannerStats>.broadcast();
  Stream<BannerStats> get statsStream => _statsController.stream;

  // Getters для мониторинга
  int get activeBannerCount => _activeBanners.length;
  int get poolSize => _bannerPool.length;
  int get platformViewCount => _platformViewCount;
  int get totalBannersCreated => _totalBannersCreated;
  int get totalBannersDestroyed => _totalBannersDestroyed;
  int get failedAdLoads => _failedAdLoads;
  int get successfulAdLoads => _successfulAdLoads;
  bool get hasAvailableBanner => _bannerPool.isNotEmpty || _activeBanners.length < _maxPoolSize;

  /// Инициализация сервиса
  Future<void> initialize() async {
    log('AdBannerService: Initializing...');
    
    // Предварительно создаем пул баннеров
    await _createBannerPool();
    
    // Запускаем периодическую очистку
    _startCleanupTimer();
    
    _emitStats();
    log('AdBannerService: Initialized successfully');
  }

  /// Создание пула баннеров заранее
  Future<void> _createBannerPool() async {
    for (int i = 0; i < _maxPoolSize; i++) {
      try {
        final banner = await _createBanner();
        _bannerPool.add(banner);
        _totalBannersCreated++;
      } catch (e) {
        log('AdBannerService: Failed to create banner for pool: $e');
      }
    }
  }

  /// Создание одного баннера с переиспользованием объектов
  Future<BannerAd> _createBanner() async {
    // Переиспользуем объекты размеров для избежания создания новых
    final screenWidth = 320; // Стандартная ширина
    final adSize = BannerAdSize.sticky(width: screenWidth);
    
    final banner = BannerAd(
      adUnitId: _adUnitId,
      adSize: adSize,
      adRequest: const AdRequest(), // Переиспользуем объект запроса
      onAdLoaded: () {
        _successfulAdLoads++;
        _emitStats();
        log('AdBannerService: Banner loaded successfully');
      },
      onAdFailedToLoad: (error) {
        _failedAdLoads++;
        _emitStats();
        log('AdBannerService: Ad failed to load: $error');
      },
      onAdClicked: () => log('AdBannerService: Banner clicked'),
      onLeftApplication: () => log('AdBannerService: Left application'),
      onReturnedToApplication: () => log('AdBannerService: Returned to application'),
      onImpression: (impressionData) => log('AdBannerService: Impression tracked'),
    );
    
    return banner;
  }

  /// Получение баннера из пула или создание нового
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
        banner = await _createBanner();
        _totalBannersCreated++;
        log('AdBannerService: Created new banner');
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
    
    _platformViewCount = 0;
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
      successfulLoads: _successfulAdLoads,
      failedLoads: _failedAdLoads,
      lastCleanup: _lastCleanup,
    );
    
    _statsController.add(stats);
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
- Successful loads: $_successfulAdLoads
- Failed loads: $_failedAdLoads
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
    // Удаляем жесткие ограничения на размер контейнера,
    // позволяя AdWidget самому определить свои габариты.
    // Если AdWidget сам не корректно расширяется, можно задать
    // минимальную высоту, но без `maxHeight`.
    return SizedBox( 
      // Yandex sticky баннер обычно имеет высоту 50px
      height: 50, // Задаем ожидаемую высоту, чтобы зарезервировать место
      child: _createAdWidget(),
    );
  }

  Widget _createAdWidget() {
    // Используем рефлексию для доступа к AdWidget, если он доступен
    try {
      return AdWidget(bannerAd: widget.bannerAd);
    } catch (e) {
      log('BannerWidget: AdWidget not available, using placeholder: $e');
      return Container(
        height: 50, // Соответствует ожидаемому размеру баннера
        width: double.infinity,
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