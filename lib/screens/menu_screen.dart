//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
//import 'package:yandex_mobileads/ad_widget.dart';
//import 'package:yandex_mobileads/mobile_ads.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late BannerAd banner;
  var isBannerAlreadyCreated = false;

  _createBanner() {
    final screenWidth = MediaQuery.of(context).size.width.round();
    final adSize = BannerAdSize.sticky(width: screenWidth);
    
    return BannerAd(
      adUnitId: 'R-M-17946414-1',
      adSize: adSize,
      adRequest: const AdRequest(),
      onAdLoaded: () {},
      onAdFailedToLoad: (error) {},
      onAdClicked: () {},
      onLeftApplication: () {},
      onReturnedToApplication: () {},
      onImpression: (impressionData) {}
    );
  }

  @override
  void initState() {
    super.initState();
    _createAdBanner();
  }

  void _createAdBanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          banner = _createBanner();
          setState(() {
            isBannerAlreadyCreated = true;
          });
        } catch (e) {
          // Игнорируем ошибки создания баннера
        }
      }
    });
  }

  void _onMenuItemTap(int index) {
    final l10n = AppLocalizations.of(context)!;
    String message = '';
    
    switch (index) {
      case 0:
        message = l10n.menuItem1; // Добавить в локализацию
        break;
      case 1:
        message = l10n.menuItem2; // Добавить в локализацию
        break;
      case 2:
        message = l10n.menuItem3; // Добавить в локализацию
        break;
      case 3:
        message = l10n.menuItem4; // Добавить в локализацию
        break;
      case 4:
        message = l10n.menuItem5; // Добавить в локализацию
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.menuTitle), // Добавить в локализацию
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fon1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
        children: [
          // Центральная часть - 5 кнопок в виде плиток (одна под другой)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.favorite,
                    title: l10n.menuAnalytics,
                    color: Colors.pink[200]!,
                    onTap: () => _onMenuItemTap(0),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    icon: Icons.schedule,
                    title: l10n.menuMedications,
                    color: Colors.pink[200]!,
                    onTap: () => _onMenuItemTap(1),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    icon: Icons.checklist,
                    title: l10n.menuInsights,
                    color: Colors.pink[200]!,
                    onTap: () => _onMenuItemTap(2),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    icon: Icons.loop,
                    title: l10n.menuReminders,
                    color: Colors.pink[200]!,
                    onTap: () => _onMenuItemTap(3),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    icon: Icons.note,
                    title: l10n.menuHelp,
                    color: Colors.pink[200]!,
                    onTap: () => _onMenuItemTap(4),
                  ),
                ],
              ),
            ),
          ),
          
          // Блок рекламы внизу
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 8),
            child: isBannerAlreadyCreated ? AdWidget(bannerAd: banner) : null,
          ),
        ],
      ),
      ),
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
            color: color.withOpacity(0.4), // Увеличиваем непрозрачность
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
                  color: Colors.white.withOpacity(0.9), // Белый фон для иконки
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.pink[600], // Более светлый розовый для иконки
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // Белый цвет для текста
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white, // Белый цвет для стрелки
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}