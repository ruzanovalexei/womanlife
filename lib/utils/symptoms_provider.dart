import 'package:period_tracker/l10n/app_localizations.dart';

class SymptomsProvider {
  static List<String> getDefaultSymptoms(AppLocalizations l10n) {
    return [
      l10n.symptomHeadache,
      l10n.symptomFatigue,
      l10n.symptomBloating,
      l10n.symptomIrritability,
      l10n.symptomAbdominalPain,
      l10n.symptomAcne,
      l10n.symptomSweetCravings,
      l10n.symptomBreastPain,
      l10n.symptomCramps,
      l10n.symptomNausea,
      l10n.symptomInsomnia,
    ];
  }
}