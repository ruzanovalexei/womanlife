import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/models/settings.dart';
import 'package:period_tracker/screens/menu_screen.dart';
import 'package:period_tracker/services/locale_service.dart';
import 'package:period_tracker/services/simple_background_service.dart';
import 'package:period_tracker/services/cache_service.dart';
import 'package:period_tracker/services/ad_banner_service.dart';
import 'package:period_tracker/utils/object_pool.dart';
//import 'package:period_tracker/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Закрепляем портретную ориентацию
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  final dbHelper = DatabaseHelper();
  Settings settings;
  try {
    settings = await dbHelper.getSettings();
  } catch (_) {
    settings = const Settings(
      id: 1,
      cycleLength: 28,
      periodLength: 5,
      planningMonths: 3,
      locale: 'ru',
      firstDayOfWeek: 'monday',
      dataRetentionPeriod: null, // null = неограниченно
    );
  }
  localeService = LocaleService(Locale(settings.locale));

  // Инициализируем сервис кеша для оптимизации БД
  final cacheService = CacheService();
  await cacheService.initialize();

  // Инициализируем сервис управления баннерами
  final adBannerService = AdBannerService();
  await adBannerService.initialize();
  await adBannerService.loadRewardedAd();
  // Запускаем фоновый сервис
  await SimpleBackgroundService.initialize();

  // Очистка кеша при закрытии приложения не поддерживается на всех платформах
  // Вместо этого используем автоматическую очистку при запуске приложения

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: localeService.locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: LocalizedMenuScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return LifecycleWatcher(child: child);
      },
    );
  }
}

/// Виджет для отслеживания lifecycle событий приложения
class LifecycleWatcher extends StatefulWidget {
  final Widget? child;
  
  const LifecycleWatcher({super.key, this.child});

  @override
  State<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // Приложение свернуто - можно освободить ресурсы
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        // Приложение отсоединено - освобождаем все ресурсы
        _onAppDetached();
        break;
      case AppLifecycleState.resumed:
        // Приложение восстановлено - можно переинициализировать сервисы
        _onAppResumed();
        break;
      case AppLifecycleState.inactive:
        // Неактивное состояние
        break;
      case AppLifecycleState.hidden:
        // Скрытое состояние
        break;
    }
  }

  void _onAppPaused() {
    debugPrint('App paused - releasing non-critical resources');
    // Можно приостановить некоторые сервисы
  }

  void _onAppDetached() {
    debugPrint('App detached - disposing all resources');
    // Освобождаем все ресурсы
    ResourceManager().disposeAll();
  }

  void _onAppResumed() {
    debugPrint('App resumed - reinitializing services if needed');
    // Переинициализируем сервисы при необходимости
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox.shrink();
  }
}

// Отдельный виджет для локализованного экрана меню
class LocalizedMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeService,
      builder: (context, _) {
        // Только локализация обновляется, остальная часть не перестраивается
        return MenuScreen();
      },
    );
  }
}