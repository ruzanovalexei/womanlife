import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart' as perm;

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _currentWords = '';
  String _selectedLanguage = 'ru_RU'; // По умолчанию русский язык

  // Список доступных языков
  final Map<String, String> _availableLanguages = {
    'Русский': 'ru_RU',
    'English': 'en_US',
    'Español': 'es_ES',
    'Français': 'fr_FR',
    'Deutsch': 'de_DE',
    'Italiano': 'it_IT',
    'Português': 'pt_PT',
    '中文 (Chinese)': 'zh_CN',
    '日本語 (Japanese)': 'ja_JP',
    '한국어 (Korean)': 'ko_KR',
  };

  // Геттеры для состояния
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get currentWords => _currentWords;
  String get selectedLanguage => _selectedLanguage;
  Map<String, String> get availableLanguages => _availableLanguages;

  // Инициализация speech-to-text
  Future<bool> initialize() async {
    debugPrint('=== Starting speech recognition initialization ===');
    
    try {
      debugPrint('Checking permissions...');
      final microphoneStatus = await perm.Permission.microphone.status;
      final speechStatus = await perm.Permission.speech.status;
      debugPrint('Microphone permission: $microphoneStatus');
      debugPrint('Speech permission: $speechStatus');
      
      // Если разрешения не предоставлены, пробуем их запросить
      if (!microphoneStatus.isGranted || !speechStatus.isGranted) {
        debugPrint('Permissions not granted, requesting...');
        final permissionsGranted = await requestPermissions();
        if (!permissionsGranted) {
          debugPrint('Permissions not granted after request');
          _isAvailable = false;
          return false;
        }
      }

      debugPrint('Checking if speech recognition is available...');
      
      _isAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error during init: $error');
          debugPrint('Error type: ${error.runtimeType}');
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('Speech recognition status during init: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      debugPrint('Initialization result: $_isAvailable');
      
      if (_isAvailable) {
        debugPrint('=== Speech recognition initialized successfully ===');
        debugPrint('Selected language: $_selectedLanguage');
        debugPrint('Available languages in service: $_availableLanguages');
        
        // Дополнительная проверка - можно ли слушать
        debugPrint('Testing if listening is available...');
        try {
          final isListeningAvailable = await _speech.isAvailable;
          debugPrint('Listening availability test: $isListeningAvailable');
        } catch (e) {
          debugPrint('Error testing listening availability: $e');
        }
        
      } else {
        debugPrint('=== Failed to initialize speech recognition ===');
        debugPrint('This might be due to:');
        debugPrint('1. No internet connection');
        debugPrint('2. Speech recognition not available on device');
        debugPrint('3. Missing permissions');
        debugPrint('4. Device compatibility issues');
        debugPrint('5. Google Speech-to-Text service unavailable');
        
        // Дополнительная диагностика
        debugPrint('Checking internet connectivity...');
        // Можно добавить проверку интернета здесь
      }
      
      return _isAvailable;
    } catch (e, stackTrace) {
      debugPrint('=== Exception during speech recognition initialization ===');
      debugPrint('Exception: $e');
      debugPrint('Stack trace: $stackTrace');
      _isAvailable = false;
      return false;
    }
  }

  // Запрос разрешений
  Future<bool> requestPermissions() async {
    try {
      debugPrint('=== Requesting permissions ===');
      
      // Проверяем текущий статус разрешений
      final microphoneStatus = await perm.Permission.microphone.status;
      final speechStatus = await perm.Permission.speech.status;
      
      debugPrint('Current microphone permission status: $microphoneStatus');
      debugPrint('Current speech permission status: $speechStatus');
      
      // Если разрешения уже предоставлены
      if (microphoneStatus.isGranted && speechStatus.isGranted) {
        debugPrint('Permissions already granted');
        return true;
      }
      
      debugPrint('Requesting permissions...');
      
      // Запрашиваем разрешения
      final result = await [
        perm.Permission.microphone,
        perm.Permission.speech,
      ].request();
      
      debugPrint('Permission request result: $result');
      
      // Проверяем результат
      final microphoneGranted = result[perm.Permission.microphone]?.isGranted ?? false;
      final speechGranted = result[perm.Permission.speech]?.isGranted ?? false;
      
      debugPrint('Microphone granted: $microphoneGranted');
      debugPrint('Speech granted: $speechGranted');
      
      // Дополнительная проверка статуса после запроса
      await Future.delayed(const Duration(milliseconds: 500)); // Даем время системе
      
      final finalMicrophoneStatus = await perm.Permission.microphone.status;
      final finalSpeechStatus = await perm.Permission.speech.status;
      
      debugPrint('Final microphone permission status: $finalMicrophoneStatus');
      debugPrint('Final speech permission status: $finalSpeechStatus');
      
      final allGranted = finalMicrophoneStatus.isGranted && finalSpeechStatus.isGranted;
      
      if (allGranted) {
        debugPrint('All permissions successfully granted');
        return true;
      } else {
        debugPrint('Permissions not granted after request');
        debugPrint('Microphone status: $finalMicrophoneStatus');
        debugPrint('Speech status: $finalSpeechStatus');
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  // Проверка доступности разрешений
  Future<bool> hasPermissions() async {
    try {
      final microphoneStatus = await perm.Permission.microphone.status;
      final speechStatus = await perm.Permission.speech.status;
      
      debugPrint('hasPermissions check:');
      debugPrint('Microphone: $microphoneStatus (granted: ${microphoneStatus.isGranted})');
      debugPrint('Speech: $speechStatus (granted: ${speechStatus.isGranted})');
      
      final hasAllPermissions = microphoneStatus.isGranted && speechStatus.isGranted;
      debugPrint('Has all permissions: $hasAllPermissions');
      
      return hasAllPermissions;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  // Открытие настроек приложения
  Future<bool> openAppSettings() async {
    try {
      debugPrint('Opening app settings for permissions...');
      final result = await perm.openAppSettings();
      debugPrint('App settings opened: $result');
      return result;
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  // Настройка языка распознавания
  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode;
    debugPrint('Language set to: $languageCode');
  }

  // Получение названия языка по коду
  String getLanguageName(String languageCode) {
    return _availableLanguages.entries
        .firstWhere(
          (entry) => entry.value == languageCode,
          orElse: () => const MapEntry('Unknown', ''),
        )
        .key;
  }

  // Запуск распознавания речи
  Future<bool> startListening({
    required Function(String words) onResult,
    required Function() onListeningStarted,
    required Function() onListeningStopped,
    required Function(String error) onError,
  }) async {
    try {
      debugPrint('=== Starting speech recognition ===');
      debugPrint('Current _isListening: $_isListening');
      debugPrint('Current _isAvailable: $_isAvailable');
      debugPrint('Selected language: $_selectedLanguage');

      // Проверяем доступность и разрешения
      if (!_isAvailable) {
        debugPrint('Speech service not available, initializing...');
        final initialized = await initialize();
        if (!initialized) {
          onError('Не удалось инициализировать распознавание речи');
          return false;
        }
      }

      final hasPerms = await hasPermissions();
      if (!hasPerms) {
        debugPrint('Permissions not available, requesting...');
        final granted = await requestPermissions();
        if (!granted) {
          onError('Необходимо предоставить разрешения для доступа к микрофону');
          return false;
        }
      }

      // Проверяем, не слушаем ли уже
      if (_isListening) {
        debugPrint('Already listening, ignoring start request');
        return true;
      }

      // Начинаем слушать
      debugPrint('Setting _isListening to true');
      _isListening = true;
      _currentWords = '';
      
      debugPrint('Calling _speech.listen()...');
      await _speech.listen(
        onResult: (result) {
          _currentWords = result.recognizedWords;
          debugPrint('Speech result received: "${result.recognizedWords}"');
          onResult(result.recognizedWords);
        },
        listenFor: const Duration(seconds: 30), // Максимум 30 секунд
        pauseFor: const Duration(seconds: 3), // Пауза 3 секунды
        partialResults: true,
        localeId: _selectedLanguage,
        onSoundLevelChange: (double level) {
          // Можно добавить визуализацию уровня звука
          debugPrint('Sound level: $level');
        },
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      debugPrint('=== Speech recognition started successfully ===');
      onListeningStarted();
      return true;
    } catch (e) {
      debugPrint('=== Error starting speech recognition ===');
      debugPrint('Error: $e');
      _isListening = false;
      debugPrint('Set _isListening to false due to error');
      onError('Ошибка запуска распознавания речи: $e');
      return false;
    }
  }

  // Остановка распознавания речи
  Future<void> stopListening({
    required Function() onListeningStopped,
  }) async {
    try {
      debugPrint('=== Stopping speech recognition ===');
      debugPrint('Current _isListening before stop: $_isListening');
      
      if (_isListening) {
        debugPrint('Calling _speech.stop()...');
        await _speech.stop();
        debugPrint('=== Speech recognition stopped successfully ===');
        debugPrint('Setting _isListening to false');
        _isListening = false;
        debugPrint('Calling onListeningStopped callback');
        onListeningStopped();
      } else {
        debugPrint('Not currently listening, nothing to stop');
        onListeningStopped();
      }
    } catch (e) {
      debugPrint('=== Error stopping speech recognition ===');
      debugPrint('Error: $e');
      _isListening = false;
      debugPrint('Set _isListening to false due to error');
      onListeningStopped();
    }
  }

  // Остановка распознавания (альтернативный метод)
  Future<void> stop() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  // Сброс текущих слов
  void resetWords() {
    _currentWords = '';
  }

  // Получение последних распознанных слов
  String getLastWords() {
    return _currentWords;
  }

  // Проверка, слушает ли сервис в данный момент
  bool getIsListening() {
    return _isListening;
  }

  // Очистка ресурсов
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _isListening = false;
    _currentWords = '';
  }
}