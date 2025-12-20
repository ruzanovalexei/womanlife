import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart'; // Для Locale
import 'package:period_tracker/l10n/app_localizations.dart';
import '../models/settings.dart';
import '../models/day_note.dart';
import '../models/period_record.dart';
import '../models/medication.dart'; // Импортируем Medication
import '../models/medication_taken_record.dart'; // Импортируем MedicationTakenRecord
import '../utils/date_utils.dart'; // Импортируем MyDateUtils
import '../utils/symptoms_provider.dart'; //для getDefaultSymptoms
import '../models/symptom.dart'; // Импортируем модель Symptom
import '../models/list_model.dart'; // Импортируем модель списка
import '../models/list_item_model.dart'; // Импортируем модель элемента списка
import '../models/note_model.dart'; // Импортируем модель заметки
import '../models/frequency_type.dart'; // Импортируем модель типов частоты
import '../models/habit_execution.dart'; // Импортируем модель привычек типа выполнение
import '../models/habit_measurable.dart'; // Импортируем модель привычек типа измеримый результат
import '../models/habit_execution_record.dart'; // Импортируем модель записей выполнения привычек
import '../models/habit_measurable_record.dart'; // Импортируем модель записей выполнения измеримых привычек
//import '../utils/date_utils.dart';

class DatabaseHelper {
  static const _databaseName = "PeriodTracker.db";
  static const _databaseVersion = 22; // Добавляем настраиваемый период хранения данных

  static const settingsTable = 'settings';
  static const dayNotesTable = 'day_notes';
  static const periodsTable = 'periods';
  static const symptomsTable = 'symptoms';
  static const medicationsTable = 'medications';
  static const medicationTakenRecordsTable = 'medication_taken_records';
  static const listsTable = 'lists';
  static const listItemsTable = 'list_items';
  static const notesTable = 'notes';
  static const frequencyTypesTable = 'frequency_types'; // Таблица для типов частоты
  static const habitsExecutionTable = 'habits_execution'; // Таблица для привычек типа выполнение
  static const habitsMeasurableTable = 'habits_measurable'; // Таблица для привычек типа измеримый результат
  static const habitExecutionRecordsTable = 'habit_execution_records'; // Таблица для записей выполнения привычек
  static const habitMeasurableRecordsTable = 'habit_measurable_records'; // Таблица для записей выполнения измеримых привычек

  // Singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper _instance = DatabaseHelper._privateConstructor();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $settingsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cycleLength INTEGER NOT NULL,
        periodLength INTEGER NOT NULL,
        ovulationDay INTEGER NOT NULL,
        planningMonths INTEGER NOT NULL,
        locale TEXT NOT NULL,
        firstDayOfWeek TEXT NOT NULL,
        dataRetentionPeriod INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $dayNotesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        symptoms TEXT NOT NULL,
        hadSex INTEGER,
        isSafeSex INTEGER,
        hadOrgasm INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $periodsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startDate TEXT NOT NULL,
        endDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $symptomsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        isDefault INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $medicationsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        times TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $medicationTakenRecordsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicationId INTEGER NOT NULL,
        date TEXT NOT NULL,
        scheduledHour INTEGER NOT NULL,
        scheduledMinute INTEGER NOT NULL,
        actualTakenTime TEXT,
        isTaken INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (medicationId) REFERENCES $medicationsTable (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $listsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdDate TEXT NOT NULL,
        updatedDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $listItemsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        listId INTEGER NOT NULL,
        text TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdDate TEXT NOT NULL,
        updatedDate TEXT NOT NULL,
        FOREIGN KEY (listId) REFERENCES $listsTable (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $notesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdDate TEXT NOT NULL,
        updatedDate TEXT NOT NULL
      )
    ''');

    // Создание таблицы для типов частоты привычек
    await db.execute('''
      CREATE TABLE $frequencyTypesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        intervalValue INTEGER,
        selectedDaysOfWeek TEXT
      )
    ''');

    // Создание таблицы для привычек типа выполнение
    await db.execute('''
      CREATE TABLE $habitsExecutionTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        frequencyId INTEGER NOT NULL,
        reminderTime TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        FOREIGN KEY (frequencyId) REFERENCES $frequencyTypesTable (id) ON DELETE CASCADE
      )
    ''');

    // Создание таблицы для привычек типа измеримый результат
    await db.execute('''
      CREATE TABLE $habitsMeasurableTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        goal REAL NOT NULL,
        unit TEXT NOT NULL,
        frequencyId INTEGER NOT NULL,
        reminderTime TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        FOREIGN KEY (frequencyId) REFERENCES $frequencyTypesTable (id) ON DELETE CASCADE
      )
    ''');

    // Создание таблицы для записей выполнения привычек типа выполнение
    await db.execute('''
      CREATE TABLE $habitExecutionRecordsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL,
        executionDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (habitId) REFERENCES $habitsExecutionTable (id) ON DELETE CASCADE
      )
    ''');

    // Создание таблицы для записей выполнения привычек типа измеримый результат
    await db.execute('''
      CREATE TABLE $habitMeasurableRecordsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL,
        actualValue REAL,
        executionDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (habitId) REFERENCES $habitsMeasurableTable (id) ON DELETE CASCADE
      )
    ''');

    // Создание индексов для оптимизации производительности
    await _createIndexes(db);

    // Insert default settings
    await db.insert(settingsTable, {
      'cycleLength': 28,
      'periodLength': 5,
      'ovulationDay': 14,
      'planningMonths': 3,
      'locale': 'ru',
      'firstDayOfWeek': 'monday',
      'dataRetentionPeriod': null, // null = неограниченно
      'lastCacheCleanup': null, // Будет установлено при первой очистке
    });

    // Initialize default symptoms with codes
    await _initializeDefaultSymptoms(db);
    
    // Initialize default frequency types
    await _initializeDefaultFrequencyTypes(db);
  }

  // Вспомогательная функция для генерации кода симптома
  // static String _generateSymptomCode(String symptomName, [int? index]) {
  //   // Удаляем пробелы и приводим к нижнему регистру
  //   final baseCode = symptomName
  //       .toLowerCase()
  //       .replaceAll(RegExp(r'[^a-z0-9]'), '')
  //       .substring(0, 6); // Ограничиваем длину базового кода
    
  //   // Если есть индекс, добавляем его для уникальности
  //   if (index != null) {
  //     return '${baseCode}_$index';
  //   }
    
  //   return baseCode;
  // }

  // Статический метод для инициализации симптомов по умолчанию (для миграций)
  static Future<void> _initializeDefaultSymptoms(Database db) async {
    // Загружаем симптомы по умолчанию
    final l10n = await AppLocalizations.delegate.load(const Locale('ru'));
    final defaultSymptoms = SymptomsProvider.getDefaultSymptoms(l10n);
    
    for (final symptomName in defaultSymptoms) {
      await db.insert(symptomsTable, {
        'name': symptomName,
        'isDefault': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ===================== FREQUENCY TYPE METHODS =====================
  
  Future<int> insertFrequencyType(FrequencyType frequencyType) async {
    Database db = await database;
    return await db.insert(frequencyTypesTable, frequencyType.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateFrequencyType(FrequencyType frequencyType) async {
    Database db = await database;
    return await db.update(frequencyTypesTable, frequencyType.toMap(), where: 'id = ?', whereArgs: [frequencyType.id]);
  }

  Future<int> deleteFrequencyType(int id) async {
    Database db = await database;
    return await db.delete(frequencyTypesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FrequencyType>> getAllFrequencyTypes() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(frequencyTypesTable, orderBy: 'type ASC, intervalValue ASC, selectedDaysOfWeek ASC');
    return maps.map((map) => FrequencyType.fromMap(map)).toList();
  }

  Future<FrequencyType?> getFrequencyTypeById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(frequencyTypesTable, where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? FrequencyType.fromMap(maps[0]) : null;
  }

  Future<List<FrequencyType>> getFrequencyTypesByType(int type) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(frequencyTypesTable, where: 'type = ?', whereArgs: [type], orderBy: 'intervalValue ASC, selectedDaysOfWeek ASC');
    return maps.map((map) => FrequencyType.fromMap(map)).toList();
  }

  // ===================== HABIT EXECUTION METHODS =====================
  
  Future<int> insertHabitExecution(HabitExecution habit) async {
    Database db = await database;
    return await db.insert(habitsExecutionTable, habit.toMap());
  }

  Future<int> updateHabitExecution(HabitExecution habit) async {
    Database db = await database;
    return await db.update(habitsExecutionTable, habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<int> deleteHabitExecution(int id) async {
    Database db = await database;
    return await db.delete(habitsExecutionTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HabitExecution>> getAllHabitExecutions() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(habitsExecutionTable, orderBy: 'name ASC');
    return maps.map((map) => HabitExecution.fromMap(map)).toList();
  }

  Future<HabitExecution?> getHabitExecutionById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(habitsExecutionTable, where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? HabitExecution.fromMap(maps[0]) : null;
  }

  Future<List<HabitExecution>> getActiveHabitExecutions(DateTime date) async {
    Database db = await database;
    final dateStr = MyDateUtils.toUtcDateString(date);
    List<Map<String, dynamic>> maps = await db.query(
      habitsExecutionTable,
      where: '(startDate <= ? AND (endDate IS NULL OR endDate >= ?))',
      whereArgs: [dateStr, dateStr],
      orderBy: 'name ASC',
    );
    return maps.map((map) => HabitExecution.fromMap(map)).toList();
  }

  // ===================== HABIT MEASURABLE METHODS =====================
  
  Future<int> insertHabitMeasurable(HabitMeasurable habit) async {
    Database db = await database;
    return await db.insert(habitsMeasurableTable, habit.toMap());
  }

  Future<int> updateHabitMeasurable(HabitMeasurable habit) async {
    Database db = await database;
    return await db.update(habitsMeasurableTable, habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<int> deleteHabitMeasurable(int id) async {
    Database db = await database;
    return await db.delete(habitsMeasurableTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HabitMeasurable>> getAllHabitMeasurables() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(habitsMeasurableTable, orderBy: 'name ASC');
    return maps.map((map) => HabitMeasurable.fromMap(map)).toList();
  }

  Future<HabitMeasurable?> getHabitMeasurableById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(habitsMeasurableTable, where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? HabitMeasurable.fromMap(maps[0]) : null;
  }

  Future<List<HabitMeasurable>> getActiveHabitMeasurables(DateTime date) async {
    Database db = await database;
    final dateStr = MyDateUtils.toUtcDateString(date);
    List<Map<String, dynamic>> maps = await db.query(
      habitsMeasurableTable,
      where: '(startDate <= ? AND (endDate IS NULL OR endDate >= ?))',
      whereArgs: [dateStr, dateStr],
      orderBy: 'name ASC',
    );
    return maps.map((map) => HabitMeasurable.fromMap(map)).toList();
  }

  // ===================== HABIT EXECUTION RECORD METHODS =====================
  
  Future<int> insertHabitExecutionRecord(HabitExecutionRecord record) async {
    Database db = await database;
    return await db.insert(habitExecutionRecordsTable, record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateHabitExecutionRecord(HabitExecutionRecord record) async {
    Database db = await database;
    return await db.update(habitExecutionRecordsTable, record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> deleteHabitExecutionRecord(int id) async {
    Database db = await database;
    return await db.delete(habitExecutionRecordsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<HabitExecutionRecord?> getHabitExecutionRecordById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(habitExecutionRecordsTable, where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? HabitExecutionRecord.fromMap(maps[0]) : null;
  }

  Future<HabitExecutionRecord?> getHabitExecutionRecord(int habitId, DateTime executionDate) async {
    Database db = await database;
    final dateStr = MyDateUtils.toUtcDateString(executionDate);
    List<Map<String, dynamic>> maps = await db.query(
      habitExecutionRecordsTable,
      where: 'habitId = ? AND executionDate = ?',
      whereArgs: [habitId, dateStr],
      limit: 1,
    );
    return maps.isNotEmpty ? HabitExecutionRecord.fromMap(maps[0]) : null;
  }

  Future<List<HabitExecutionRecord>> getHabitExecutionRecordsByHabitId(int habitId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      habitExecutionRecordsTable,
      where: 'habitId = ?',
      whereArgs: [habitId],
      orderBy: 'executionDate DESC',
    );
    return maps.map((map) => HabitExecutionRecord.fromMap(map)).toList();
  }

  Future<List<HabitExecutionRecord>> getHabitExecutionRecordsForDate(DateTime date) async {
    Database db = await database;
    final dateStr = MyDateUtils.toUtcDateString(date);
    List<Map<String, dynamic>> maps = await db.query(
      habitExecutionRecordsTable,
      where: 'executionDate = ?',
      whereArgs: [dateStr],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => HabitExecutionRecord.fromMap(map)).toList();
  }

  // ===================== HABIT MEASURABLE RECORD METHODS =====================
  
  Future<int> insertHabitMeasurableRecord(HabitMeasurableRecord record) async {
    Database db = await database;
    return await db.insert(habitMeasurableRecordsTable, record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateHabitMeasurableRecord(HabitMeasurableRecord record) async {
    Database db = await database;
    return await db.update(habitMeasurableRecordsTable, record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> deleteHabitMeasurableRecord(int id) async {
    Database db = await database;
    return await db.delete(habitMeasurableRecordsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<HabitMeasurableRecord?> getHabitMeasurableRecordById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(habitMeasurableRecordsTable, where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? HabitMeasurableRecord.fromMap(maps[0]) : null;
  }

  Future<HabitMeasurableRecord?> getHabitMeasurableRecord(int habitId, DateTime executionDate) async {
    Database db = await database;
    final dateStr = MyDateUtils.toUtcDateString(executionDate);
    List<Map<String, dynamic>> maps = await db.query(
      habitMeasurableRecordsTable,
      where: 'habitId = ? AND executionDate = ?',
      whereArgs: [habitId, dateStr],
      limit: 1,
    );
    return maps.isNotEmpty ? HabitMeasurableRecord.fromMap(maps[0]) : null;
  }

  Future<List<HabitMeasurableRecord>> getHabitMeasurableRecordsByHabitId(int habitId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      habitMeasurableRecordsTable,
      where: 'habitId = ?',
      whereArgs: [habitId],
      orderBy: 'executionDate DESC',
    );
    return maps.map((map) => HabitMeasurableRecord.fromMap(map)).toList();
  }

  Future<List<HabitMeasurableRecord>> getHabitMeasurableRecordsForDate(DateTime date) async {
    Database db = await database;
    final dateStr = MyDateUtils.toUtcDateString(date);
    List<Map<String, dynamic>> maps = await db.query(
      habitMeasurableRecordsTable,
      where: 'executionDate = ?',
      whereArgs: [dateStr],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => HabitMeasurableRecord.fromMap(map)).toList();
  }

  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 7:
          try {
            await db.execute('''CREATE TABLE $periodsTable (id INTEGER PRIMARY KEY AUTOINCREMENT, startDate TEXT NOT NULL, endDate TEXT)''');
          } catch (e) {
            // print('Error creating periods table: $e');
          }
          break;
        case 8:
          try {
            await db.execute('ALTER TABLE $settingsTable ADD COLUMN locale TEXT');
            await db.update(settingsTable, {'locale': 'en'}, where: 'locale IS NULL');
          } catch (e) {
            // print('Error adding locale column: $e');
          }
          break;
        case 9:
          try {
            await db.execute('ALTER TABLE $settingsTable ADD COLUMN firstDayOfWeek TEXT');
            await db.update(settingsTable, {'firstDayOfWeek': 'monday'}, where: 'firstDayOfWeek IS NULL');
          } catch (e) {
            // print('Error adding firstDayOfWeek column: $e');
          }
          break;
        case 10:
          try {
            await db.execute('ALTER TABLE $dayNotesTable ADD COLUMN sexualActsCount INTEGER DEFAULT 0');
          } catch (e) {
            // print('Error adding sexualActsCount column: $e');
          }
          break;
        case 11:
          try {
            await db.execute('''CREATE TABLE IF NOT EXISTS $symptomsTable (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)''');
            final List<Map<String, dynamic>> existingSymptoms = await db.query(symptomsTable);
            if (existingSymptoms.isEmpty) {
              await _initializeDefaultSymptoms(db);
            }
          } catch (e) {
            // print('Error creating symptoms table or inserting default symptoms: $e');
          }
          break;
        case 12:
          try {
            await db.execute('''CREATE TABLE $medicationsTable (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, startDate TEXT NOT NULL, endDate TEXT, times TEXT NOT NULL)''');
          } catch (e) {
            // print('Error creating medications table: $e');
          }
          break;
        case 13:
          try {
            await db.execute('''CREATE TABLE $medicationTakenRecordsTable (id INTEGER PRIMARY KEY AUTOINCREMENT, medicationId INTEGER NOT NULL, date TEXT NOT NULL, scheduledHour INTEGER NOT NULL, scheduledMinute INTEGER NOT NULL, actualTakenTime TEXT, isTaken INTEGER NOT NULL DEFAULT 0, FOREIGN KEY (medicationId) REFERENCES $medicationsTable (id) ON DELETE CASCADE)''');
          } catch (e) {
            // print('Error creating medication_taken_records table: $e');
          }
          break;
        case 14:
          try {
            // Удаляем старое поле sexualActsCount и добавляем новые поля для секса
            await db.execute('ALTER TABLE $dayNotesTable DROP COLUMN sexualActsCount');
            await db.execute('ALTER TABLE $dayNotesTable ADD COLUMN hadSex INTEGER');
            await db.execute('ALTER TABLE $dayNotesTable ADD COLUMN isSafeSex INTEGER');
            await db.execute('ALTER TABLE $dayNotesTable ADD COLUMN hadOrgasm INTEGER');
          } catch (e) {
            // Если поле sexualActsCount не существует, просто добавляем новые поля
            try {
              await db.execute('ALTER TABLE $dayNotesTable ADD COLUMN hadSex INTEGER');
              await db.execute('ALTER TABLE $dayNotesTable ADD COLUMN isSafeSex INTEGER');
              await db.execute('ALTER TABLE $dayNotesTable ADD COLUMN hadOrgasm INTEGER');
            } catch (e2) {
              // print('Error adding new sex-related columns: $e2');
            }
          }
          break;
        case 15:
          try {
            // Добавляем поле isDefault в таблицу symptoms (если его еще нет)
            await db.execute('ALTER TABLE $symptomsTable ADD COLUMN isDefault INTEGER DEFAULT 0');
          } catch (e) {
            // print('Error adding isDefault column: $e');
          }
          break;
        case 16:
          try {
            // Создаем таблицы для списков
            await db.execute('''
              CREATE TABLE $listsTable (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                createdDate TEXT NOT NULL,
                updatedDate TEXT NOT NULL
              )
            ''');
            
            await db.execute('''
              CREATE TABLE $listItemsTable (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                listId INTEGER NOT NULL,
                text TEXT NOT NULL,
                isCompleted INTEGER NOT NULL DEFAULT 0,
                createdDate TEXT NOT NULL,
                updatedDate TEXT NOT NULL,
                FOREIGN KEY (listId) REFERENCES $listsTable (id) ON DELETE CASCADE
              )
            ''');
          } catch (e) {
            // print('Error creating lists tables: $e');
          }
          break;
        case 17:
          try {
            // Создаем таблицу для заметок
            await db.execute('''
              CREATE TABLE $notesTable (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                createdDate TEXT NOT NULL,
                updatedDate TEXT NOT NULL
              )
            ''');
          } catch (e) {
            // print('Error creating notes table: $e');
          }
          break;
        case 18:
          try {
            // Создание таблицы для типов частоты привычек
            await db.execute('''
              CREATE TABLE $frequencyTypesTable (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type INTEGER NOT NULL,
                intervalValue INTEGER,
                selectedDaysOfWeek TEXT
              )
            ''');

            // Создание таблицы для привычек типа выполнение
            await db.execute('''
              CREATE TABLE $habitsExecutionTable (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                frequencyId INTEGER NOT NULL,
                reminderTime TEXT NOT NULL,
                startDate TEXT NOT NULL,
                endDate TEXT,
                FOREIGN KEY (frequencyId) REFERENCES $frequencyTypesTable (id) ON DELETE CASCADE
              )
            ''');

            // Создание таблицы для привычек типа измеримый результат
            await db.execute('''
              CREATE TABLE $habitsMeasurableTable (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                goal REAL NOT NULL,
                unit TEXT NOT NULL,
                frequencyId INTEGER NOT NULL,
                reminderTime TEXT NOT NULL,
                startDate TEXT NOT NULL,
                endDate TEXT,
                FOREIGN KEY (frequencyId) REFERENCES $frequencyTypesTable (id) ON DELETE CASCADE
              )
            ''');

            // Создание таблицы для записей выполнения привычек типа выполнение
            await db.execute('''
              CREATE TABLE $habitExecutionRecordsTable (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                habitId INTEGER NOT NULL,
                isCompleted INTEGER NOT NULL,
                executionDate TEXT NOT NULL,
                createdAt TEXT NOT NULL,
                FOREIGN KEY (habitId) REFERENCES $habitsExecutionTable (id) ON DELETE CASCADE
              )
            ''');

            // Создание таблицы для записей выполнения привычек типа измеримый результат
            await db.execute('''
              CREATE TABLE $habitMeasurableRecordsTable (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                habitId INTEGER NOT NULL,
                isCompleted INTEGER NOT NULL,
                actualValue REAL,
                executionDate TEXT NOT NULL,
                createdAt TEXT NOT NULL,
                FOREIGN KEY (habitId) REFERENCES $habitsMeasurableTable (id) ON DELETE CASCADE
              )
            ''');

            // Инициализируем типы частоты по умолчанию
            await _initializeDefaultFrequencyTypes(db);
          } catch (e) {
            // print('Error creating habits tables: $e');
          }
          break;
        case 19:
          try {
            // Добавляем недостающие поля в таблицу frequency_types с проверкой существования
            await db.execute('ALTER TABLE $frequencyTypesTable ADD COLUMN intervalValue INTEGER');
          } catch (e) {
            // Игнорируем ошибку, если колонка уже существует
          }
          
          try {
            await db.execute('ALTER TABLE $frequencyTypesTable ADD COLUMN selectedDaysOfWeek TEXT');
          } catch (e) {
            // Игнорируем ошибку, если колонка уже существует
          }
          break;
        case 20:
          try {
            // Дополнительная проверка и исправление структуры таблицы frequency_types
            // Проверяем, существует ли таблица и какие у неё колонки
            final tableInfo = await db.rawQuery("PRAGMA table_info($frequencyTypesTable)");
            final columns = tableInfo.map((row) => row['name'] as String).toList();
            
            // Добавляем intervalValue, если его нет
            if (!columns.contains('intervalValue')) {
              await db.execute('ALTER TABLE $frequencyTypesTable ADD COLUMN intervalValue INTEGER');
            }
            
            // Добавляем selectedDaysOfWeek, если его нет
            if (!columns.contains('selectedDaysOfWeek')) {
              await db.execute('ALTER TABLE $frequencyTypesTable ADD COLUMN selectedDaysOfWeek TEXT');
            }
          } catch (e) {
            // print('Error checking/fixing frequency_types table structure: $e');
          }
          break;
        case 21:
          try {
            // Создание индексов для оптимизации производительности
            await _createIndexes(db);
            
            // Проверяем и добавляем поле для хранения даты последней очистки кеша в настройки
            try {
              final tableInfo = await db.rawQuery("PRAGMA table_info($settingsTable)");
              final columns = tableInfo.map((row) => row['name'] as String).toList();
              
              if (!columns.contains('lastCacheCleanup')) {
                await db.execute('ALTER TABLE $settingsTable ADD COLUMN lastCacheCleanup TEXT');
                print('Added lastCacheCleanup column to settings table');
              } else {
                print('lastCacheCleanup column already exists in settings table');
              }
            } catch (e) {
              print('Error checking/adding lastCacheCleanup column: $e');
            }
            
            print('Database optimized with indexes and cache cleanup support');
          } catch (e) {
            print('Error optimizing database: $e');
          }
          break;
        case 22:
          try {
            // Добавляем поле для периода хранения данных в настройки
            await db.execute('ALTER TABLE $settingsTable ADD COLUMN dataRetentionPeriod INTEGER');
            print('Added dataRetentionPeriod column to settings table');
          } catch (e) {
            print('Error adding dataRetentionPeriod column: $e');
          }
          break;
      }
    }
  }

  // Settings methods
  Future<int> updateSettings(Settings settings) async {
    Database db = await database;
    return await db.update(settingsTable, settings.toMap(), where: 'id = ?', whereArgs: [settings.id]);
  }

  Future<Settings> getSettings() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(settingsTable);
    if (maps.isNotEmpty) {
      return Settings.fromMap(maps[0]);
    }
    throw Exception('No settings found');
  }

  // Period Records methods
  Future<int> insertPeriodRecord(PeriodRecord record) async {
    Database db = await database;
    return await db.insert(periodsTable, record.toMap());
  }

  Future<int> updatePeriodRecord(PeriodRecord record) async {
    Database db = await database;
    return await db.update(periodsTable, record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> deletePeriodRecord(int id) async {
    Database db = await database;
    return await db.delete(periodsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PeriodRecord>> getAllPeriodRecords() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(periodsTable, orderBy: 'startDate DESC');
    return maps.map((map) => PeriodRecord.fromMap(map)).toList();
  }

  Future<PeriodRecord?> getLastPeriodRecord() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(periodsTable, orderBy: 'startDate DESC', limit: 1);
    return maps.isNotEmpty ? PeriodRecord.fromMap(maps[0]) : null;
  }

  Future<PeriodRecord?> getActivePeriodRecord() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(periodsTable, where: 'endDate IS NULL', orderBy: 'startDate DESC', limit: 1);
    return maps.isNotEmpty ? PeriodRecord.fromMap(maps[0]) : null;
  }

  // DayNote methods
  Future<int> insertOrUpdateDayNote(DayNote note) async {
    Database db = await database;
    return await db.insert(dayNotesTable, note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DayNote?> getDayNote(DateTime date) async {
    Database db = await database;
    final formattedDate = DayNote.formatDateForDatabase(date);
    List<Map<String, dynamic>> maps = await db.query(dayNotesTable, where: 'date = ?', whereArgs: [formattedDate]);
    return maps.isNotEmpty ? DayNote.fromMap(maps[0]) : null;
  }

  Future<List<DayNote>> getAllDayNotes() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(dayNotesTable);
    return maps.map((map) => DayNote.fromMap(map)).toList();
  }

  // Symptom methods
  // Future<void> insertSymptom(String symptom) async {
  //   Database db = await database;
  //   await db.insert(symptomsTable, {'name': symptom}, conflictAlgorithm: ConflictAlgorithm.ignore);
  // }

  Future<List<String>> getAllSymptoms() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(symptomsTable);
    return maps.map((map) => map['name'] as String).toList();
  }

  // Medication methods
  Future<int> insertMedication(Medication medication) async {
    Database db = await database;
    return await db.insert(medicationsTable, medication.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMedication(Medication medication) async {
    Database db = await database;
    return await db.update(medicationsTable, medication.toMap(), where: 'id = ?', whereArgs: [medication.id]);
  }

  Future<int> deleteMedication(int id) async {
    Database db = await database;
    return await db.delete(medicationsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Medication>> getAllMedications() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(medicationsTable);
    return maps.map((map) => Medication.fromMap(map)).toList();
  }

  // MedicationTakenRecord methods
  Future<int> insertMedicationTakenRecord(MedicationTakenRecord record) async {
    Database db = await database;
    return await db.insert(medicationTakenRecordsTable, record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMedicationTakenRecord(MedicationTakenRecord record) async {
    Database db = await database;
    return await db.update(medicationTakenRecordsTable, record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<MedicationTakenRecord?> getMedicationTakenRecord(int medicationId, DateTime date, TimeOfDay scheduledTime) async {
    Database db = await database;
    final formattedDate = MyDateUtils.toUtcDateString(date);
    List<Map<String, dynamic>> maps = await db.query(
      medicationTakenRecordsTable,
      where: 'medicationId = ? AND date = ? AND scheduledHour = ? AND scheduledMinute = ?',
      whereArgs: [medicationId, formattedDate, scheduledTime.hour, scheduledTime.minute],
      limit: 1,
    );
    return maps.isNotEmpty ? MedicationTakenRecord.fromMap(maps.first) : null;
  }

  Future<List<MedicationTakenRecord>> getMedicationTakenRecordsForDay(DateTime date) async {
    Database db = await database;
    final formattedDate = MyDateUtils.toUtcDateString(date);
    List<Map<String, dynamic>> maps = await db.query(
      medicationTakenRecordsTable,
      where: 'date = ?',
      whereArgs: [formattedDate],
      orderBy: 'scheduledHour ASC, scheduledMinute ASC',
    );
    return maps.map((map) => MedicationTakenRecord.fromMap(map)).toList();
  }

  Future<int> deleteMedicationTakenRecord(int id) async {
    Database db = await database;
    return await db.delete(medicationTakenRecordsTable, where: 'id = ?', whereArgs: [id]);
  }

  // Symptom methods (updated for new model)
  Future<int> insertSymptom(Symptom symptom) async {
    Database db = await database;
    return await db.insert(symptomsTable, symptom.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSymptom(Symptom symptom) async {
    Database db = await database;
    return await db.update(symptomsTable, symptom.toMap(), where: 'id = ?', whereArgs: [symptom.id]);
  }

  Future<int> deleteSymptom(int id) async {
    Database db = await database;
    return await db.delete(symptomsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Symptom>> getAllSymptomsAsObjects() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(symptomsTable, orderBy: 'name ASC');
    return maps.map((map) => Symptom.fromMap(map)).toList();
  }

  Future<void> initializeDefaultSymptoms() async {
    Database db = await database;
    
    // Проверяем, есть ли уже симптомы в БД
    final existingSymptoms = await db.query(symptomsTable);
    if (existingSymptoms.isNotEmpty) {
      return; // Симптомы уже есть, не перезаписываем
    }

    // Загружаем симптомы по умолчанию
    final l10n = await AppLocalizations.delegate.load(const Locale('ru'));
    final defaultSymptoms = SymptomsProvider.getDefaultSymptoms(l10n);
    
    for (final symptomName in defaultSymptoms) {
      await db.insert(symptomsTable, {
        'name': symptomName,
        'isDefault': 1,
      });
    }
  }

  // List methods
  Future<int> insertList(ListModel list) async {
    Database db = await database;
    return await db.insert(listsTable, list.toMap());
  }

  Future<int> updateList(ListModel list) async {
    Database db = await database;
    return await db.update(listsTable, list.toMap(), where: 'id = ?', whereArgs: [list.id]);
  }

  Future<int> deleteList(int id) async {
    Database db = await database;
    return await db.delete(listsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ListModel>> getAllLists() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(listsTable, orderBy: 'updatedDate DESC');
    return maps.map((map) => ListModel.fromMap(map)).toList();
  }

  Future<ListModel?> getListById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(listsTable, where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? ListModel.fromMap(maps[0]) : null;
  }

  // ListItem methods
  Future<int> insertListItem(ListItemModel item) async {
    Database db = await database;
    return await db.insert(listItemsTable, item.toMap());
  }

  Future<int> updateListItem(ListItemModel item) async {
    Database db = await database;
    return await db.update(listItemsTable, item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteListItem(int id) async {
    Database db = await database;
    return await db.delete(listItemsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ListItemModel>> getAllListItems() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(listItemsTable, orderBy: 'createdDate ASC');
    return maps.map((map) => ListItemModel.fromMap(map)).toList();
  }

  Future<List<ListItemModel>> getListItemsByListId(int listId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      listItemsTable,
      where: 'listId = ?',
      whereArgs: [listId],
      orderBy: 'createdDate ASC',
    );
    return maps.map((map) => ListItemModel.fromMap(map)).toList();
  }

  Future<int> toggleListItemStatus(int itemId, bool isCompleted) async {
    Database db = await database;
    return await db.update(
      listItemsTable,
      {
        'isCompleted': isCompleted ? 1 : 0,
        'updatedDate': MyDateUtils.toUtcDateString(DateTime.now()),
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<Map<String, int>> getListProgress(int listId) async {
    Database db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completed
      FROM $listItemsTable 
      WHERE listId = ?
    ''', [listId]);
    
    if (result.isNotEmpty) {
      final row = result.first;
      return {
        'total': row['total'] as int? ?? 0,
        'completed': row['completed'] as int? ?? 0,
      };
    }
    return {'total': 0, 'completed': 0};
  }

  // Note methods
  Future<int> insertNote(NoteModel note) async {
    Database db = await database;
    return await db.insert(notesTable, note.toMap());
  }

  Future<int> updateNote(NoteModel note) async {
    Database db = await database;
    return await db.update(notesTable, note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<int> deleteNote(int id) async {
    Database db = await database;
    return await db.delete(notesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<NoteModel>> getAllNotes() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(notesTable, orderBy: 'updatedDate DESC');
    return maps.map((map) => NoteModel.fromMap(map)).toList();
  }

  Future<NoteModel?> getNoteById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(notesTable, where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? NoteModel.fromMap(maps[0]) : null;
  }

  // Метод для инициализации типов частоты по умолчанию
  static Future<void> _initializeDefaultFrequencyTypes(Database db) async {
    // Тип 1: Каждый день
    await db.insert(frequencyTypesTable, {
      'type': 1,
      'intervalValue': null,
      'selectedDaysOfWeek': null,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Тип 2: Каждый X день
    await db.insert(frequencyTypesTable, {
      'type': 2,
      'intervalValue': 2, // Значение по умолчанию, будет изменено пользователем
      'selectedDaysOfWeek': null,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    
    // Тип 3: По дням недели
    await db.insert(frequencyTypesTable, {
      'type': 3,
      'intervalValue': null,
      'selectedDaysOfWeek': '[1,3,5]', // По умолчанию понедельник, среда, пятница
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    
    // Тип 4: X раз в неделю
    await db.insert(frequencyTypesTable, {
      'type': 4,
      'intervalValue': 3, // Значение по умолчанию, будет изменено пользователем
      'selectedDaysOfWeek': null,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // ===================== DATABASE OPTIMIZATION METHODS =====================
  
  /// Создание индексов для оптимизации производительности
  static Future<void> _createIndexes(Database db) async {
    // Индексы для таблицы day_notes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_day_notes_date ON $dayNotesTable(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_day_notes_symptoms ON $dayNotesTable(symptoms)');
    
    // Индексы для таблицы periods
    await db.execute('CREATE INDEX IF NOT EXISTS idx_periods_start_date ON $periodsTable(startDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_periods_end_date ON $periodsTable(endDate)');
    
    // Индексы для таблицы medications
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medications_start_date ON $medicationsTable(startDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medications_end_date ON $medicationsTable(endDate)');
    
    // Индексы для таблицы medication_taken_records
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medication_records_medication_id ON $medicationTakenRecordsTable(medicationId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medication_records_date ON $medicationTakenRecordsTable(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medication_records_medication_date ON $medicationTakenRecordsTable(medicationId, date)');
    
    // Индексы для таблицы list_items
    await db.execute('CREATE INDEX IF NOT EXISTS idx_list_items_list_id ON $listItemsTable(listId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_list_items_completed ON $listItemsTable(isCompleted)');
    
    // Индексы для таблицы notes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_updated_date ON $notesTable(updatedDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_created_date ON $notesTable(createdDate)');
    
    // Индексы для таблиц привычек
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_execution_frequency_id ON $habitsExecutionTable(frequencyId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_execution_start_date ON $habitsExecutionTable(startDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_execution_end_date ON $habitsExecutionTable(endDate)');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_measurable_frequency_id ON $habitsMeasurableTable(frequencyId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_measurable_start_date ON $habitsMeasurableTable(startDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_measurable_end_date ON $habitsMeasurableTable(endDate)');
    
    // Индексы для записей привычек
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_execution_records_habit_id ON $habitExecutionRecordsTable(habitId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_execution_records_date ON $habitExecutionRecordsTable(executionDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_execution_records_habit_date ON $habitExecutionRecordsTable(habitId, executionDate)');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_measurable_records_habit_id ON $habitMeasurableRecordsTable(habitId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_measurable_records_date ON $habitMeasurableRecordsTable(executionDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_measurable_records_habit_date ON $habitMeasurableRecordsTable(habitId, executionDate)');
  }

  /// Оптимизация базы данных (VACUUM, ANALYZE, REINDEX)
  Future<void> optimizeDatabase() async {
    Database db = await database;
    try {
      await db.execute('VACUUM'); // Освобождает неиспользуемое пространство
      await db.execute('ANALYZE'); // Обновляет статистику для оптимизатора запросов
      await db.execute('REINDEX'); // Перестраивает индексы
      print('Database optimized successfully');
    } catch (e) {
      print('Error optimizing database: $e');
    }
  }

  /// Получение информации о размере базы данных
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    Database db = await database;
    final databasePath = db.path;
    final databaseFile = File(databasePath);
    
    Map<String, dynamic> info = {
      'fileSizeBytes': await databaseFile.length(),
      'fileSizeMB': (await databaseFile.length()) / (1024 * 1024),
      'tables': <String, dynamic>{}
    };

    // Получаем информацию о таблицах
    final tables = await db.rawQuery('''
      SELECT name 
      FROM sqlite_master 
      WHERE type='table' AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''');

    for (final table in tables) {
      final tableName = table['name'] as String;
      final tableInfo = await db.rawQuery('''
        SELECT 
          COUNT(*) as rowCount,
          SUM(pgsize) as totalSize
        FROM dbstat 
        WHERE name = ?
      ''', [tableName]);
      
      final stats = tableInfo.first;
      info['tables'][tableName] = {
        'rowCount': stats['rowCount'] ?? 0,
        'sizeBytes': stats['totalSize'] ?? 0,
        'sizeKB': ((stats['totalSize'] ?? 0) as int) / 1024,
      };
    }

    return info;
  }

  /// Очистка кеша приложения
  Future<void> clearCache() async {
    try {
      Database db = await database;
      
      // Получаем настройки для определения периода хранения данных
      final settings = await getSettings();
      final retentionPeriodMonths = settings.dataRetentionPeriod;
      
      // Если период хранения не задан (null), не удаляем данные
      if (retentionPeriodMonths == null) {
        print('Data retention period not set, skipping cache cleanup');
        return;
      }
      
      // Вычисляем дату cutoff на основе настроек пользователя
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionPeriodMonths * 30));
      final cutoffDateStr = MyDateUtils.toUtcDateString(cutoffDate);
      
      // Очистка старых записей привычек
      await db.delete(habitExecutionRecordsTable, where: 'executionDate < ?', whereArgs: [cutoffDateStr]);
      await db.delete(habitMeasurableRecordsTable, where: 'executionDate < ?', whereArgs: [cutoffDateStr]);
      
      // Очистка старых записей приема лекарств
      await db.delete(medicationTakenRecordsTable, where: 'date < ?', whereArgs: [cutoffDateStr]);
      
      // Очистка старых заметок по дням
      await db.delete(dayNotesTable, where: 'date < ?', whereArgs: [cutoffDateStr]);
      
      print('Cache cleared successfully (retention period: $retentionPeriodMonths months)');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Периодическая очистка кеша (вызывать при запуске приложения)
  Future<void> performPeriodicCleanup() async {
    try {
      Database db = await database;
      
      // Сначала проверяем и исправляем структуру таблицы settings
      await fixSettingsTableStructure();
      
      // Проверяем, когда была последняя очистка (используем настройки для хранения даты последней очистки)
      // final settings = await getSettings();
      final lastCleanup = await _getLastCleanupDate(db);
      
      if (lastCleanup == null || 
          DateTime.now().difference(lastCleanup).inDays > 30) {
        
        await clearCache();
        await optimizeDatabase();
        await _setLastCleanupDate(db, DateTime.now());
        
        print('Periodic cleanup performed');
      }
    } catch (e) {
      print('Error performing periodic cleanup: $e');
    }
  }

  /// Получение даты последней очистки кеша
  static Future<DateTime?> _getLastCleanupDate(Database db) async {
    try {
      // Сначала проверяем, существует ли колонка lastCacheCleanup
      final tableInfo = await db.rawQuery("PRAGMA table_info($settingsTable)");
      final columns = tableInfo.map((row) => row['name'] as String).toList();
      
      if (!columns.contains('lastCacheCleanup')) {
        print('lastCacheCleanup column does not exist, returning null');
        return null;
      }
      
      final result = await db.query(settingsTable, limit: 1);
      if (result.isNotEmpty) {
        final lastCleanup = result.first['lastCacheCleanup'];
        if (lastCleanup != null && lastCleanup is String) {
          return MyDateUtils.fromUtcDateString(lastCleanup);
        }
      }
    } catch (e) {
      print('Error getting last cleanup date: $e');
    }
    return null;
  }

  /// Установка даты последней очистки кеша
  static Future<void> _setLastCleanupDate(Database db, DateTime date) async {
    try {
      // Проверяем, существует ли колонка lastCacheCleanup
      final tableInfo = await db.rawQuery("PRAGMA table_info($settingsTable)");
      final columns = tableInfo.map((row) => row['name'] as String).toList();
      
      if (!columns.contains('lastCacheCleanup')) {
        print('lastCacheCleanup column does not exist, skipping update');
        return;
      }
      
      // Получаем первую (и единственную) запись настроек
      final settingsResult = await db.query(settingsTable, limit: 1);
      if (settingsResult.isNotEmpty) {
        final settingsId = settingsResult.first['id'];
        if (settingsId != null) {
          await db.update(settingsTable, {
            'lastCacheCleanup': MyDateUtils.toUtcDateString(date),
          }, where: 'id = ?', whereArgs: [settingsId]);
          print('Successfully updated lastCacheCleanup date');
        }
      }
    } catch (e) {
      print('Error setting last cleanup date: $e');
    }
  }

  /// Очистка кеша при закрытии приложения
  Future<void> cleanupOnExit() async {
    try {
      await clearCache();
      await optimizeDatabase();
      print('Cleanup on exit completed');
    } catch (e) {
      print('Error during cleanup on exit: $e');
    }
  }

  /// Получение статистики использования приложения
  Future<Map<String, dynamic>> getUsageStatistics() async {
    Database db = await database;
    final stats = <String, dynamic>{};
    
    try {
      // Общее количество записей
      final totalRecords = await db.rawQuery('''
        SELECT 
          (SELECT COUNT(*) FROM $dayNotesTable) as dayNotes,
          (SELECT COUNT(*) FROM $notesTable) as notes,
          (SELECT COUNT(*) FROM $listsTable) as lists,
          (SELECT COUNT(*) FROM $listItemsTable) as listItems,
          (SELECT COUNT(*) FROM $medicationsTable) as medications,
          (SELECT COUNT(*) FROM $medicationTakenRecordsTable) as medicationRecords,
          (SELECT COUNT(*) FROM $habitsExecutionTable) as habitExecutions,
          (SELECT COUNT(*) FROM $habitsMeasurableTable) as habitMeasurables,
          (SELECT COUNT(*) FROM $habitExecutionRecordsTable) as habitExecutionRecords,
          (SELECT COUNT(*) FROM $habitMeasurableRecordsTable) as habitMeasurableRecords
      ''');
      
      if (totalRecords.isNotEmpty) {
        stats.addAll(totalRecords.first);
      }
      
      // Статистика по датам
      final dateStats = await db.rawQuery('''
        SELECT 
          MIN(date) as earliestDate,
          MAX(date) as latestDate,
          COUNT(DISTINCT date) as uniqueDays
        FROM $dayNotesTable
      ''');
      
      if (dateStats.isNotEmpty) {
        stats.addAll(dateStats.first);
      }
      
      // Статистика размеров данных
      final dbInfo = await getDatabaseInfo();
      stats['databaseSizeMB'] = dbInfo['fileSizeMB'];
      
    } catch (e) {
      print('Error getting usage statistics: $e');
    }
    
    return stats;
  }

  /// Закрытие соединения с базой данных
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Принудительная проверка и исправление структуры таблицы settings
  Future<void> fixSettingsTableStructure() async {
    Database db = await database;
    try {
      final tableInfo = await db.rawQuery("PRAGMA table_info($settingsTable)");
      final columns = tableInfo.map((row) => row['name'] as String).toList();
      
      // Проверяем и добавляем колонку lastCacheCleanup
      if (!columns.contains('lastCacheCleanup')) {
        try {
          await db.execute('ALTER TABLE $settingsTable ADD COLUMN lastCacheCleanup TEXT');
          print('Successfully added lastCacheCleanup column to settings table');
        } catch (e) {
          print('Error adding lastCacheCleanup column: $e');
        }
      } else {
        print('lastCacheCleanup column already exists in settings table');
      }
      
      // Проверяем и добавляем колонку dataRetentionPeriod
      if (!columns.contains('dataRetentionPeriod')) {
        try {
          await db.execute('ALTER TABLE $settingsTable ADD COLUMN dataRetentionPeriod INTEGER');
          print('Successfully added dataRetentionPeriod column to settings table');
        } catch (e) {
          print('Error adding dataRetentionPeriod column: $e');
        }
      } else {
        print('dataRetentionPeriod column already exists in settings table');
      }
      
    } catch (e) {
      print('Error fixing settings table structure: $e');
    }
  }
}