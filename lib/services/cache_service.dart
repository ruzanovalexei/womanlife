// import 'dart:io';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isInitialized = false;
  // DateTime? _lastCleanup;

  /// Инициализация сервиса кеша
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Выполняем периодическую очистку при запуске
      await _dbHelper.performPeriodicCleanup();
      _isInitialized = true;
      
      if (kDebugMode) {
        print('CacheService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing CacheService: $e');
      }
    }
  }

  /// Очистка кеша приложения
  Future<void> clearCache() async {
    try {
      await _dbHelper.clearCache();
      // _lastCleanup = DateTime.now();
      
      if (kDebugMode) {
        print('Cache cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cache: $e');
      }
      rethrow;
    }
  }

  /// Оптимизация базы данных
  Future<void> optimizeDatabase() async {
    try {
      await _dbHelper.optimizeDatabase();
      
      if (kDebugMode) {
        print('Database optimized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error optimizing database: $e');
      }
      rethrow;
    }
  }

  /// Получение информации о размере базы данных
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      return await _dbHelper.getDatabaseInfo();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting database info: $e');
      }
      return {};
    }
  }

  /// Получение статистики использования приложения
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      return await _dbHelper.getUsageStatistics();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting usage statistics: $e');
      }
      return {};
    }
  }

  /// Очистка кеша при закрытии приложения
  Future<void> cleanupOnExit() async {
    try {
      await _dbHelper.cleanupOnExit();
      
      if (kDebugMode) {
        print('Cleanup on exit completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during cleanup on exit: $e');
      }
    }
  }

  /// Проверка необходимости очистки кеша
  Future<bool> needsCleanup() async {
    try {
      final dbInfo = await getDatabaseInfo();
      final fileSizeMB = dbInfo['fileSizeMB'] ?? 0.0;
      
      // Очищаем кеш, если размер БД превышает 100 МБ
      return fileSizeMB > 100.0;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if cleanup is needed: $e');
      }
      return false;
    }
  }

  /// Автоматическая очистка при превышении лимита размера
  Future<void> autoCleanupIfNeeded() async {
    try {
      if (await needsCleanup()) {
        await clearCache();
        await optimizeDatabase();
        
        if (kDebugMode) {
          print('Auto cleanup performed due to large database size');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during auto cleanup: $e');
      }
    }
  }

  /// Получение отформатированной информации о размере БД
  Future<String> getFormattedDatabaseSize() async {
    try {
      final dbInfo = await getDatabaseInfo();
      final sizeInBytes = dbInfo['fileSizeBytes'] ?? 0;
      
      if (sizeInBytes < 1024) {
        return '$sizeInBytes Б';
      } else if (sizeInBytes < 1024 * 1024) {
        return '${(sizeInBytes / 1024).toStringAsFixed(1)} КБ';
      } else {
        return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
      }
    } catch (e) {
      return 'Неизвестно';
    }
  }

  /// Получение рекомендаций по оптимизации
  Future<List<String>> getOptimizationRecommendations() async {
    final recommendations = <String>[];
    
    try {
      final dbInfo = await getDatabaseInfo();
      final stats = await getUsageStatistics();
      
      final sizeMB = dbInfo['fileSizeMB'] ?? 0.0;
      final dayNotesCount = stats['dayNotes'] ?? 0;
      final notesCount = stats['notes'] ?? 0;
      final medicationRecordsCount = stats['medicationRecords'] ?? 0;
      
      // Рекомендации по размеру
      if (sizeMB > 100) {
        recommendations.add('Размер базы данных превышает 100 МБ. Рекомендуется выполнить очистку кеша.');
      } else if (sizeMB > 50) {
        recommendations.add('Размер базы данных превышает 50 МБ. Рассмотрите возможность очистки старых данных.');
      }
      
      // Рекомендации по количеству записей
      if (dayNotesCount > 1000) {
        recommendations.add('Большое количество записей заметок по дням ($dayNotesCount). Старые записи можно архивировать.');
      }
      
      if (notesCount > 500) {
        recommendations.add('Большое количество заметок ($notesCount). Рассмотрите удаление ненужных заметок.');
      }
      
      if (medicationRecordsCount > 10000) {
        recommendations.add('Большое количество записей приема лекарств ($medicationRecordsCount). Старые записи можно удалить.');
      }
      
      if (recommendations.isEmpty) {
        recommendations.add('База данных в хорошем состоянии. Рекомендуется периодическая оптимизация.');
      }
      
    } catch (e) {
      recommendations.add('Ошибка при анализе базы данных: $e');
    }
    
    return recommendations;
  }

  /// Закрытие сервиса
  Future<void> dispose() async {
    try {
      await _dbHelper.closeDatabase();
      _isInitialized = false;
      
      if (kDebugMode) {
        print('CacheService disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing CacheService: $e');
      }
    }
  }
}