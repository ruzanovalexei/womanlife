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
    );
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