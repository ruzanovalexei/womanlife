import 'package:sqflite/sqflite.dart';

import '../utils/period_calculator.dart';

class Migration1To2 {
  static Future execute(Database db) async {
    await db.execute('''
      ALTER TABLE settings ADD COLUMN lastPeriod TEXT
    ''');

    // Set default value for existing records
    await db.update(
      'settings',
      {'lastPeriod': PeriodCalculator.getToday().toIso8601String()},
    );
  }
}