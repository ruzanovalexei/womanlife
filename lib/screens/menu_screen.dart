import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/models/settings.dart';
import 'package:period_tracker/models/period_record.dart';
import 'package:period_tracker/utils/date_utils.dart';
import 'package:period_tracker/screens/day_detail_screen.dart';
import 'package:period_tracker/screens/settings_screen.dart';
import 'package:period_tracker/screens/lists_screen.dart';
import 'package:period_tracker/screens/notes_screen.dart';
import 'package:period_tracker/screens/habits_screen.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
// import 'package:yandex_mobileads/ad_widget.dart'; // Добавляем импорт AdWidget

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _databaseHelper = DatabaseHelper();
  late Settings _settings;
  List<PeriodRecord> _periodRecords = [];
  bool _isLoading = true;
  
  // Исправлено: правильное объявление баннера и флага
  BannerAd? _bannerAd;
  bool _isBannerLoading = false;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    // Очищаем баннер при уничтожении виджета
    _bannerAd?.destroy();
    super.dispose();
  }

  // Оптимизированная инициализация экрана
  void _initializeScreen() {
    _loadData();
    _createAdBanner();
  }

  // Оптимизированная загрузка данных - один setState
  Future<void> _loadData() async {
    try {
      final settings = await _databaseHelper.getSettings();
      final periodRecords = await _databaseHelper.getAllPeriodRecords();
      
      if (mounted) {
        setState(() {
          _settings = settings;
          _periodRecords = periodRecords;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('Error loading data: $e');
      }
    }
  }

  // Исправленное создание баннера с защитой от повторного вызова
  void _createAdBanner() {
    // Проверяем, не создается ли уже баннер
    if (_isBannerLoading || _isBannerLoaded || _bannerAd != null) {
      return;
    }

    _isBannerLoading = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isBannerLoading = false;
        return;
      }

      try {
        final bannerAd = _createBanner();
        if (mounted) {
          setState(() {
            _bannerAd = bannerAd;
            _isBannerLoading = false;
            _isBannerLoaded = true;
          });
        }
      } catch (e) {
        _isBannerLoading = false;
        debugPrint('Banner creation failed: $e');
      }
    });
  }

  // Создание баннера
  BannerAd _createBanner() {
    final screenWidth = MediaQuery.of(context).size.width.round();
    final adSize = BannerAdSize.sticky(width: screenWidth);
    
    return BannerAd(
      adUnitId: 'R-M-17946414-3',
      adSize: adSize,
      adRequest: const AdRequest(),
      onAdLoaded: () {
        debugPrint('Banner loaded successfully');
      },
      onAdFailedToLoad: (error) {
        debugPrint('Ad failed to load: $error');
        if (mounted) {
          setState(() {
            _isBannerLoaded = false;
            _bannerAd = null;
          });
        }
      },
      onAdClicked: () {},
      onLeftApplication: () {},
      onReturnedToApplication: () {},
      onImpression: (impressionData) {}
    );
  }

  void _onMenuItemTap(int index) {
    switch (index) {
      case 0:
        // Кнопка "Здоровье" - открываем детальный экран на текущую дату
        if (!_isLoading) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DayDetailScreen(
                selectedDate: MyDateUtils.getUtcToday(),
                periodRecords: _periodRecords,
                settings: _settings,
                shouldReturnResult: false,
              ),
            ),
          ).then((_) {
            _loadData(); // Обновляем данные при возврате
          });
        }
        break;
      case 1:
        // Планируется реализация
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListsScreen()),
        ).then((_) {
          _loadData();
        });
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HabitsScreen()),
        ).then((_) {
          _loadData();
        });
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotesScreen()),
        ).then((_) {
          _loadData();
        });
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        ).then((_) {
          _loadData();
        });
        break;
    }
  }
static const _backgroundImage = AssetImage('assets/images/fon1.png');
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.menuTitle),
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMenuContent(l10n),
            ),
            
            // Блок рекламы
            _buildBannerWidget(),
          ],
        ),
      ),
    );
  }

  // Вынесенный в отдельный метод контент меню
  Widget _buildMenuContent(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.favorite,
            title: l10n.menu1,
            color: Colors.pink[200]!,
            onTap: () => _onMenuItemTap(0),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.schedule,
            title: l10n.menu2,
            color: const Color.fromARGB(255, 116, 114, 115),
            onTap: () => _onMenuItemTap(1),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.checklist,
            title: l10n.menu3,
            color: Colors.pink[200]!,
            onTap: () => _onMenuItemTap(2),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.loop,
            title: l10n.menu4,
            color:  Colors.pink[200]!,
            onTap: () => _onMenuItemTap(3),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.note,
            title: l10n.menu5,
            color: Colors.pink[200]!,
            onTap: () => _onMenuItemTap(4),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.settings,
            title: l10n.settingsTitle,
            color: Colors.pink[200]!,
            onTap: () => _onMenuItemTap(5),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Исправленный виджет баннера
  Widget _buildBannerWidget() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 8),
      height: _isBannerLoaded ? 60 : 0,
      child: _bannerAd != null && _isBannerLoaded
          ? AdWidget(bannerAd: _bannerAd!)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.pink[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}