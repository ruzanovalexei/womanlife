import 'package:flutter/material.dart';

class LocaleService extends ChangeNotifier {
  LocaleService(this._locale);

  Locale _locale;

  Locale get locale => _locale;

  void updateLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}

late LocaleService localeService;

