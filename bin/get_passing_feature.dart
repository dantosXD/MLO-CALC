import 'dart:io';
import 'dart:math';
import 'package:sqflite_common/sql.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await openDatabase('features.db');

  // Get all passing features
  final result = await db.query('features',
      where: 'passes = ?',
      whereArgs: [1],
      columns: ['id', 'priority', 'category', 'name', 'description', 'steps'],
      orderBy: 'id');

  if (result.isEmpty) {
    print('No passing features found');
    await db.close();
    exit(0);
  }

  // Get a random feature
  final random = Random();
  final feature = result[random.nextInt(result.length)];

  print('=== FEATURE FOR REGRESSION TESTING ===');
  print('');
  print('Feature #${feature['id']}: ${feature['name']}');
  print('Category: ${feature['category']}');
  print('Priority: ${feature['priority']}');
  print('');
  print('Description:');
  print('${feature['description']}');
  print('');
  print('Verification Steps:');
  print('${feature['steps']}');
  print('');
  print('=====================================');

  await db.close();
}
