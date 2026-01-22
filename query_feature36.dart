import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactoryFfi.openDatabase('features.db');
  final List<Map> results = await db.query(
    'features',
    where: 'id = ?',
    whereArgs: [36],
  );

  if (results.isNotEmpty) {
    final feature = results.first;
    print('ID: ${feature['id']}');
    print('Priority: ${feature['priority']}');
    print('Category: ${feature['category']}');
    print('Name: ${feature['name']}');
    print('Description: ${feature['description']}');
    print('Steps: ${feature['steps']}');
    print('Passes: ${feature['passes']}');
    print('In Progress: ${feature['in_progress']}');
    print('Dependencies: ${feature['dependencies']}');
  } else {
    print('Feature #36 not found');
  }

  await db.close();
}
