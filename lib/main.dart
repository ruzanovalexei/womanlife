import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/models/settings.dart';
import 'package:period_tracker/screens/home_screen.dart';
import 'package:period_tracker/services/locale_service.dart';
import 'package:period_tracker/services/simple_background_service.dart';
//import 'package:period_tracker/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();
  Settings settings;
  try {
    settings = await dbHelper.getSettings();
  } catch (_) {
    settings = const Settings(
      id: 1,
      cycleLength: 28,
      periodLength: 5,
      ovulationDay: 14,
      planningMonths: 3,
      locale: 'ru',
      firstDayOfWeek: 'monday',
    );
  }
  localeService = LocaleService(Locale(settings.locale));

    // Запускаем фоновый сервис
  await SimpleBackgroundService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeService,
      builder: (context, _) {
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
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}