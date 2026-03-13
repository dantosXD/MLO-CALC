// ignore_for_file: avoid_print

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactory.openDatabase('features.db');

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
