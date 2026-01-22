import 'dart:io';
import 'package:sqflite_common/sql.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await openDatabase('features.db');

  final result = await db.query('features',
      where: 'id = ?',
      whereArgs: [23],
      columns: ['id', 'priority', 'category', 'name', 'description', 'steps', 'passes', 'in_progress', 'dependencies']);

  if (result.isNotEmpty) {
    print('Feature #23:');
    print('ID: ${result[0]['id']}');
    print('Priority: ${result[0]['priority']}');
    print('Category: ${result[0]['category']}');
    print('Name: ${result[0]['name']}');
    print('Description: ${result[0]['description']}');
    print('Steps: ${result[0]['steps']}');
    print('Passes: ${result[0]['passes']}');
    print('In Progress: ${result[0]['in_progress']}');
    print('Dependencies: ${result[0]['dependencies']}');
  } else {
    print('Feature #23 not found');
  }

  await db.close();
}
