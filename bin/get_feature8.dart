import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await openDatabase('features.db');

  final List<Map> results = await db.query(
    'features',
    where: 'id = ?',
    whereArgs: [8],
  );

  if (results.isNotEmpty) {
    final feature = results.first;
    print('ID: ${feature['id']}');
    print('Category: ${feature['category']}');
    print('Name: ${feature['name']}');
    print('Description: ${feature['description']}');
    print('Steps: ${feature['steps']}');
    print('Passing: ${feature['passes']}');
    print('In Progress: ${feature['in_progress']}');
    print('Priority: ${feature['priority']}');
  } else {
    print('Feature #8 not found');
  }

  await db.close();
}
