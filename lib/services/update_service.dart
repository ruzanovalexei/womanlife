import 'dart:async';
// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис проверки обновлений приложения из RuStore
class UpdateService {
  /// ID приложения в RuStore (замените на реальный)
  static const String _rustoreAppId = 'com.ruzanov.womancalendar';

  /// Ключ для хранения времени последней проверки
  static const String _lastCheckTimeKey = 'last_update_check_time';

  /// Ключ для хранения флага "не показывать снова"
  static const String _skipVersionKey = 'skip_update_version';

  /// Период между проверками (24 часа)
  static const Duration _checkInterval = Duration(hours: 24);

  /// Единичный экземпляр сервиса
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Текущая версия приложения
  String _currentVersion = '';

  /// Последняя доступная версия в RuStore
  String _latestVersion = '';

  /// URL страницы приложения в RuStore
  String _storeUrl = '';

  /// Флаг, нужно ли показывать уведомление об обновлении
  bool _updateAvailable = false;

  /// Инициализация сервиса
  Future<void> initialize() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;
    _storeUrl = 'https://www.rustore.ru/catalog/app/$_rustoreAppId';
    debugPrint('UpdateService: Current app version: $_currentVersion');
  }

  /// Проверить наличие обновлений
  Future<bool> checkForUpdates() async {
    try {
      // Проверяем, нужно ли делать проверку (не чаще раза в 24 часа)
      final prefs = await SharedPreferences.getInstance();
      final lastCheckTime = prefs.getInt(_lastCheckTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Если прошло меньше 24 часов с последней проверки, используем кэш
      if (now - lastCheckTime < _checkInterval.inMilliseconds) {
        debugPrint('UpdateService: Skipping check, last check was recent');
        return _updateAvailable;
      }

      // Проверяем, не отключено ли обновление для этой версии
      final skippedVersion = prefs.getString(_skipVersionKey);
      if (skippedVersion != null && _compareVersions(skippedVersion, _currentVersion) >= 0) {
        debugPrint('UpdateService: Update skipped for version $skippedVersion');
        return false;
      }

      // Получаем информацию о последней версии из RuStore
      await _fetchLatestVersion();

      // Сохраняем время проверки
      await prefs.setInt(_lastCheckTimeKey, now);

      return _updateAvailable;
    } catch (e) {
      debugPrint('UpdateService: Error checking for updates: $e');
      return false;
    }
  }

  /// Получить информацию о последней версии из RuStore
  Future<void> _fetchLatestVersion() async {
    // Сразу парсим страницу магазина, API RuStore может быть недоступен
    debugPrint('UpdateService: Parsing store page directly...');
    await _parseStorePage();
  }

  /// Парсинг страницы магазина для получения версии
  Future<void> _parseStorePage() async {
    try {
      debugPrint('UpdateService: Parsing store page: $_storeUrl');
      final response = await http.get(Uri.parse(_storeUrl));
      debugPrint('UpdateService: Store page status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final html = response.body;
        debugPrint('UpdateService: HTML length: ${html.length} bytes');

        // Ищем версию в HTML (простой парсинг)
        final versionRegex = RegExp(r'"softwareVersion"\s*:\s*"([^"]+)"');
        final match = versionRegex.firstMatch(html);
        debugPrint('UpdateService: Version regex match: ${match != null}');

        if (match != null) {
          _latestVersion = match.group(1) ?? '';
          debugPrint('UpdateService: Parsed version: $_latestVersion');

          if (_compareVersions(_latestVersion, _currentVersion) > 0) {
            _updateAvailable = true;
            debugPrint('UpdateService: Update found via HTML parsing');
          } else {
            debugPrint('UpdateService: No newer version found');
          }
        } else {
          debugPrint('UpdateService: No version found in HTML');
        }
      }
    } catch (e) {
      debugPrint('UpdateService: Error parsing store page: $e');
    }
  }

  /// Сравнение версий (возвращает: >0 если v1 > v2, <0 если v1 < v2, 0 если равны)
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).toList();
    final parts2 = v2.split('.').map(int.tryParse).toList();

    for (int i = 0; i < parts1.length && i < parts2.length; i++) {
      final p1 = parts1[i] ?? 0;
      final p2 = parts2[i] ?? 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }

    return 0;
  }

  /// Показать диалог обновления
  Future<bool> showUpdateDialog(BuildContext context) async {
    if (!_updateAvailable) {
      debugPrint('UpdateService: No update available, skipping dialog');
      return false;
    }

    debugPrint('UpdateService: Showing update dialog for version $_latestVersion');
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Доступно обновление'),
        content: Text(
          'Доступна новая версия $_latestVersion (текущая: $_currentVersion).\n\n'
          'Рекомендуется обновить приложение для получения последних исправлений и функций.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _skipThisVersion();
              Navigator.of(context).pop(false);
            },
            child: Text('Напомнить позже'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateNow();
              Navigator.of(context).pop(true);
            },
            child: Text('Обновить сейчас'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Переход в RuStore для обновления
  void _updateNow() async {
    debugPrint('UpdateService: Opening store URL: $_storeUrl');
    try {
      final canLaunch = await canLaunchUrlString(_storeUrl);
      debugPrint('UpdateService: Can launch URL: $canLaunch');

      if (canLaunch) {
        await launchUrlString(_storeUrl);
        debugPrint('UpdateService: Store opened successfully');
      } else {
        debugPrint('UpdateService: Could not launch URL: $_storeUrl');
      }
    } catch (e) {
      debugPrint('UpdateService: Error opening store: $e');
    }
  }

  /// Пропустить это обновление
  Future<void> _skipThisVersion() async {
    debugPrint('UpdateService: Skipping version $_latestVersion');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skipVersionKey, _latestVersion);
    _updateAvailable = false;
    debugPrint('UpdateService: Skip saved for version $_latestVersion');
  }

  /// Сбросить пропущенные обновления
  Future<void> resetSkippedUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skipVersionKey);
  }

  /// Получить текущую версию
  String get currentVersion => _currentVersion;

  /// Получить последнюю версию
  String get latestVersion => _latestVersion;

  /// Есть ли доступное обновление
  bool get updateAvailable => _updateAvailable;
}

/// Глобальный экземпляр сервиса
final updateService = UpdateService();