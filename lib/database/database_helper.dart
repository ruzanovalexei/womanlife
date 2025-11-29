import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart'; // Для Locale
import 'package:period_tracker/l10n/app_localizations.dart';
import '../models/settings.dart';
import '../models/day_note.dart';
import '../models/period_record.dart';
import '../models/medication.dart'; // Импортируем Medication
import '../utils/symptoms_provider.dart'; //для getDefaultSymptoms

class DatabaseHelper {
  static const _databaseName = "PeriodTracker.db";
  static const _databaseVersion = 12; // Добавляем таблицу лекарств

  static const settingsTable = 'settings';
  static const dayNotesTable = 'day_notes';
  static const periodsTable = 'periods';
  static const symptomsTable = 'symptoms';
  static const medicationsTable = 'medications';

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
        firstDayOfWeek TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $dayNotesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        symptoms TEXT NOT NULL,
        sexualActsCount INTEGER DEFAULT 0
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
        name TEXT NOT NULL UNIQUE
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

    // Insert default settings
    await db.insert(settingsTable, {
      'cycleLength': 28,
      'periodLength': 5,
      'ovulationDay': 14,
      'planningMonths': 3,
      'locale': 'en',
      'firstDayOfWeek': 'monday',
    });

    // Load default symptoms and insert
    // Используем английскую локаль для начальной загрузки симптомов
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final List<String> defaultSymptoms = SymptomsProvider.getDefaultSymptoms(l10n);
    for (final symptom in defaultSymptoms) {
      await db.insert(symptomsTable, {'name': symptom});
    }
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
            final l10n = await AppLocalizations.delegate.load(const Locale('en'));
            final List<String> defaultSymptoms = SymptomsProvider.getDefaultSymptoms(l10n);
            final List<Map<String, dynamic>> existingSymptoms = await db.query(symptomsTable);
            if (existingSymptoms.isEmpty) {
              for (final symptom in defaultSymptoms) {
                await db.insert(symptomsTable, {'name': symptom}, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
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
  Future<void> insertSymptom(String symptom) async {
    Database db = await database;
    await db.insert(symptomsTable, {'name': symptom}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

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
}