// ignore_for_file: avoid_print

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactory.openDatabase('features.db');

  final List<Map> features = await db.query(
    'features',
    where: 'id = ?',
    whereArgs: [12],
  );

  if (features.isNotEmpty) {
    final feature = features.first;
    print('ID: ${feature['id']}');
    print('Category: ${feature['category']}');
    print('Name: ${feature['name']}');
    print('Description: ${feature['description']}');
    print('Steps: ${feature['steps']}');
    print('Passes: ${feature['passes'] == 1}');
    print('In Progress: ${feature['in_progress'] == 1}');
    print('Dependencies: ${feature['dependencies']}');
    print('Priority: ${feature['priority']}');
  } else {
    print('Feature #12 not found');
  }

  await db.close();
}
