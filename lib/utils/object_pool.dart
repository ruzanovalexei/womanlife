import 'dart:developer';
import 'dart:async';

/// Универсальный пул объектов для оптимизации памяти
class ObjectPool<T> {
  final T Function() _objectFactory;
  final void Function(T)? _resetObject;
  final void Function(T)? _disposeObject;
  final int _maxPoolSize;
  
  final List<T> _pool = [];
  int _totalCreated = 0;
  int _totalDisposed = 0;
  int _activeObjects = 0;

  ObjectPool({
    required T Function() objectFactory,
    void Function(T)? resetObject,
    void Function(T)? disposeObject,
    int maxPoolSize = 10,
  }) : _objectFactory = objectFactory,
       _resetObject = resetObject,
       _disposeObject = disposeObject,
       _maxPoolSize = maxPoolSize;

  /// Получение объекта из пула
  T get() {
    T object;
    
    if (_pool.isNotEmpty) {
      object = _pool.removeLast();
      log('ObjectPool: Reused object from pool (size: ${_pool.length})');
    } else {
      object = _objectFactory();
      _totalCreated++;
      log('ObjectPool: Created new object (total created: $_totalCreated)');
    }
    
    _activeObjects++;
    return object;
  }

  /// Возврат объекта в пул
  void returnObject(T object) {
    _activeObjects--;
    
    // Сбрасываем состояние объекта перед возвратом
    _resetObject?.call(object);
    
    // Добавляем в пул, если есть место
    if (_pool.length < _maxPoolSize) {
      _pool.add(object);
      log('ObjectPool: Object returned to pool (size: ${_pool.length})');
    } else {
      // Уничтожаем, если пул переполнен
      _disposeObject?.call(object);
      _totalDisposed++;
      log('ObjectPool: Object disposed (pool full)');
    }
  }

  /// Принудительная очистка пула
  void clear() {
    for (final object in _pool) {
      _disposeObject?.call(object);
    }
    _pool.clear();
    log('ObjectPool: Pool cleared');
  }

  /// Получение статистики
  ObjectPoolStats get stats => ObjectPoolStats(
    poolSize: _pool.length,
    activeObjects: _activeObjects,
    totalCreated: _totalCreated,
    totalDisposed: _totalDisposed,
    maxPoolSize: _maxPoolSize,
  );

  /// Получение отчета
  String get report {
    return '''
ObjectPool Stats:
- Pool size: ${_pool.length}
- Active objects: $_activeObjects
- Total created: $_totalCreated
- Total disposed: $_totalDisposed
- Max pool size: $_maxPoolSize
- Utilization: ${(_activeObjects / (_pool.length + _activeObjects) * 100).toStringAsFixed(1)}%
''';
  }
}

/// Статистика пула объектов
class ObjectPoolStats {
  final int poolSize;
  final int activeObjects;
  final int totalCreated;
  final int totalDisposed;
  final int maxPoolSize;

  const ObjectPoolStats({
    required this.poolSize,
    required this.activeObjects,
    required this.totalCreated,
    required this.totalDisposed,
    required this.maxPoolSize,
  });

  @override
  String toString() {
    return 'Pool(pool:$poolSize, active:$activeObjects, created:$totalCreated)';
  }
}

/// Мониторинг производительности и памяти
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final StreamController<PerformanceMetrics> _metricsController = 
      StreamController<PerformanceMetrics>.broadcast();
  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;

  DateTime? _lastFrameTime;
  int _frameCount = 0;
  int _skippedFrames = 0;
  final List<int> _frameTimes = [];
  static const int _maxFrameTimes = 60; // Последние 60 кадров

  /// Запуск мониторинга кадров
  void startFrameMonitoring() {
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateFrameMetrics();
    });
  }

  void _updateFrameMetrics() {
    final now = DateTime.now();
    
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMilliseconds;
      _frameTimes.add(frameTime);
      
      // Ограничиваем размер списка
      if (_frameTimes.length > _maxFrameTimes) {
        _frameTimes.removeAt(0);
      }
      
      // Подсчет пропущенных кадров (больше 16ms)
      if (frameTime > 16) {
        _skippedFrames++;
      }
    }
    
    _lastFrameTime = now;
    _frameCount++;

    // Отправляем метрики каждые 30 кадров
    if (_frameCount % 30 == 0) {
      _emitMetrics();
    }
  }

  void _emitMetrics() {
    final avgFrameTime = _frameTimes.isEmpty 
        ? 0.0 
        : _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    
    final fps = avgFrameTime > 0 ? 1000.0 / avgFrameTime : 0.0;
    
    final metrics = PerformanceMetrics(
      fps: fps,
      avgFrameTime: avgFrameTime,
      skippedFrames: _skippedFrames,
      frameCount: _frameCount,
      memoryInfo: _getMemoryInfo(),
      timestamp: DateTime.now(),
    );
    
    _metricsController.add(metrics);
  }

  PerformanceMemoryInfo _getMemoryInfo() {
    // В реальном приложении здесь был бы код для получения информации о памяти
    // На Android можно использовать dart:io для получения RSS
    return PerformanceMemoryInfo(
      usedMemoryMB: 0, // Здесь должен быть реальный код
      availableMemoryMB: 0,
      garbageCollectionCount: 0,
    );
  }

  /// Получение текущих метрик
  PerformanceMetrics? get currentMetrics {
    if (_frameTimes.isEmpty) return null;
    
    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final fps = 1000 / avgFrameTime;
    
    return PerformanceMetrics(
      fps: fps,
      avgFrameTime: avgFrameTime,
      skippedFrames: _skippedFrames,
      frameCount: _frameCount,
      memoryInfo: _getMemoryInfo(),
      timestamp: DateTime.now(),
    );
  }

  /// Остановка мониторинга
  void dispose() {
    _metricsController.close();
  }
}

/// Метрики производительности
class PerformanceMetrics {
  final double fps;
  final double avgFrameTime;
  final int skippedFrames;
  final int frameCount;
  final PerformanceMemoryInfo memoryInfo;
  final DateTime timestamp;

  const PerformanceMetrics({
    required this.fps,
    required this.avgFrameTime,
    required this.skippedFrames,
    required this.frameCount,
    required this.memoryInfo,
    required this.timestamp,
  });

  bool get isLowPerformance => fps < 55 || avgFrameTime > 20;
  bool get isHighMemoryUsage => memoryInfo.usedMemoryMB > 100;

  @override
  String toString() {
    return 'FPS: ${fps.toStringAsFixed(1)}, Avg frame: ${avgFrameTime.toStringAsFixed(1)}ms, '
           'Skipped: $skippedFrames, Memory: ${memoryInfo.usedMemoryMB}MB';
  }
}

/// Информация о памяти
class PerformanceMemoryInfo {
  final double usedMemoryMB;
  final double availableMemoryMB;
  final int garbageCollectionCount;

  const PerformanceMemoryInfo({
    required this.usedMemoryMB,
    required this.availableMemoryMB,
    required this.garbageCollectionCount,
  });
}

/// Менеджер ресурсов для автоматического управления жизненным циклом
class ResourceManager {
  static final ResourceManager _instance = ResourceManager._internal();
  factory ResourceManager() => _instance;
  ResourceManager._internal();

  final List<Disposable> _disposables = [];
  final Map<String, Timer> _timers = {};
  final ObjectPool<StringBuffer> _stringBuilderPool = ObjectPool<StringBuffer>(
    objectFactory: () => StringBuffer(),
    resetObject: (sb) => sb.clear(),
    disposeObject: (sb) => sb.clear(),
    maxPoolSize: 5,
  );

  /// Регистрация ресурса для автоматического освобождения
  void registerDisposable(Disposable disposable) {
    _disposables.add(disposable);
    log('ResourceManager: Registered disposable resource');
  }

  /// Удаление ресурса из списка
  void unregisterDisposable(Disposable disposable) {
    _disposables.remove(disposable);
    log('ResourceManager: Unregistered disposable resource');
  }

  /// Создание таймера с автоматической очисткой
  Timer createTimer(Duration duration, void Function(Timer) callback, {String? name}) {
    final timer = Timer.periodic(duration, callback);
    if (name != null) {
      _timers[name] = timer;
      log('ResourceManager: Created timer: $name');
    }
    return timer;
  }

  /// Получение StringBuffer из пула
  StringBuffer getStringBuilder() {
    return _stringBuilderPool.get();
  }

  /// Возврат StringBuffer в пул
  void returnStringBuilder(StringBuffer sb) {
    _stringBuilderPool.returnObject(sb);
  }

  /// Очистка всех ресурсов
  void disposeAll() {
    log('ResourceManager: Disposing all resources...');
    
    // Останавливаем все таймеры
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    
    // Освобождаем все зарегистрированные ресурсы
    for (final disposable in _disposables) {
      try {
        disposable.dispose();
      } catch (e) {
        log('ResourceManager: Error disposing resource: $e');
      }
    }
    _disposables.clear();
    
    // Очищаем пулы
    _stringBuilderPool.clear();
    
    log('ResourceManager: All resources disposed');
  }

  /// Получение отчета
  String get report {
    return '''
ResourceManager Report:
- Registered disposables: ${_disposables.length}
- Active timers: ${_timers.length}
- StringBuffer pool: ${_stringBuilderPool.report}
''';
  }
}

/// Интерфейс для ресурсов, которые можно освободить
abstract class Disposable {
  void dispose();
}

/// Утилиты для оптимизации циклов
class LoopOptimizations {
  /// Создание фиксированного списка для избежания аллокаций в циклах
  static List<T> createFixedList<T>(int size, T Function(int) factory) {
    return List<T>.generate(size, factory, growable: false);
  }

  /// Предварительно выделенная карта
  static Map<K, V> createFixedMap<K, V>(int size) {
    return {}; // Простая пустая карта
  }

  /// Оптимизированное создание строки с StringBuffer
  static String buildString(List<String> parts) {
    final sb = ResourceManager().getStringBuilder();
    try {
      for (final part in parts) {
        sb.write(part);
      }
      return sb.toString();
    } finally {
      ResourceManager().returnStringBuilder(sb);
    }
  }

  /// Предотвращение создания временных объектов в циклах
  static void safeLoop<T>(Iterable<T> items, void Function(T, int) action) {
    int index = 0;
    for (final item in items) {
      action(item, index);
      index++;
    }
  }

  /// Эффективное сравнение строк без создания новых объектов
  static bool safeStringEquals(String? a, String? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a == b;
  }
}