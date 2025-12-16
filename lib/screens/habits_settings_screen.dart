import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import '../widgets/habits_tab.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

class HabitsSettingsScreen extends StatefulWidget {
  const HabitsSettingsScreen({super.key});

  @override
  _HabitsSettingsScreenState createState() => _HabitsSettingsScreenState();
}

class _HabitsSettingsScreenState extends State<HabitsSettingsScreen> {
  late BannerAd banner;
  var isBannerAlreadyCreated = false;
  static const _backgroundImage = AssetImage('assets/images/fon1.png');

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  // Оптимизированная инициализация экрана
  void _initializeScreen() {
    _createAdBanner();
  }

  // Создание баннера
  BannerAd _createBanner() {
    final screenWidth = MediaQuery.of(context).size.width.round();
    final adSize = BannerAdSize.sticky(width: screenWidth);
    
    return BannerAd(
      adUnitId: 'R-M-17946414-5',
      adSize: adSize,
      adRequest: const AdRequest(),
      onAdLoaded: () {
        if (mounted) {
          setState(() {}); // Обновляем только для показа баннера
        }
      },
      onAdFailedToLoad: (error) {
        debugPrint('Ad failed to load: $error');
      },
      onAdClicked: () {},
      onLeftApplication: () {},
      onReturnedToApplication: () {},
      onImpression: (impressionData) {}
    );
  }

  // Оптимизированное создание баннера
  void _createAdBanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !isBannerAlreadyCreated) {
        try {
          banner = _createBanner();
          setState(() {
            isBannerAlreadyCreated = true;
          });
        } catch (e) {
          debugPrint('Banner creation failed: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTabHabits),
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
            
            // Блок рекламы
            _buildBannerWidget(),
          ],
        ),
      ),
    );
  }

  // Вынесенный основной контент
  Widget _buildMainContent() {
    return const HabitsTab();
  }

  // Вынесенный виджет баннера
  Widget _buildBannerWidget() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 8),
      height: isBannerAlreadyCreated ? 60 : 0, // Фиксированная высота
      child: isBannerAlreadyCreated 
          ? AdWidget(bannerAd: banner)
          : const SizedBox.shrink(),
    );
  }
}