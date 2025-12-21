import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/widgets/medications_tab.dart';
import '../services/ad_banner_service.dart';
// import 'package:yandex_mobileads/mobile_ads.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  _MedicationsScreenState createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _adBannerService = AdBannerService();
  static const _backgroundImage = AssetImage('assets/images/fon1.png');
  bool _hasChanges = false; // Флаг для отслеживания изменений

  @override
  void initState() {
    super.initState();
  }

  

  

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTabMedications),
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
              child: MedicationsTab(
                onDataChanged: (hasChanges) {
                  setState(() {
                    _hasChanges = hasChanges;
                  });
                },
              ),
            ),
            
            // Блок рекламы
            _adBannerService.createBannerWidget(),
          ],
        ),
      ),
    );
  }
}