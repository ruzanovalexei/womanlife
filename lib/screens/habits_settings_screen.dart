import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import '../widgets/habits_tab.dart';
import '../services/ad_banner_service.dart';
// import 'package:yandex_mobileads/mobile_ads.dart';

class HabitsSettingsScreen extends StatefulWidget {
  const HabitsSettingsScreen({super.key});

  @override
  _HabitsSettingsScreenState createState() => _HabitsSettingsScreenState();
}

class _HabitsSettingsScreenState extends State<HabitsSettingsScreen> {
  final _adBannerService = AdBannerService();
  static const _backgroundImage = AssetImage('assets/images/fon1.png');
  bool _hasChanges = false; // Флаг для отслеживания изменений

  // Виджет баннера создается один раз и переиспользуется
  Widget? _bannerWidget;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _initializeBannerWidget();
  }

  // Оптимизированная инициализация экрана
  void _initializeScreen() {
    // Инициализация экрана без создания баннера
  }

  // Инициализация виджета баннера - создается один раз
  void _initializeBannerWidget() {
    if (_bannerWidget == null) {
      _bannerWidget = _adBannerService.createBannerWidget();
      if (mounted) {
        setState(() {});
      }
    }
  }
  

@override
  void dispose() {
    // Очищаем виджет баннера при уничтожении экрана
    _bannerWidget = null;
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTabHabits),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _hasChanges);
          },
        ),
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
              child: _buildMainContent(),
            ),
            
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

  // Вынесенный основной контент
  Widget _buildMainContent() {
    return HabitsTab(
      onDataChanged: (hasChanges) {
        setState(() {
          _hasChanges = hasChanges;
        });
      },
    );
  }

  
}