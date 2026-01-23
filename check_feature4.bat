@echo off
echo Checking Feature #4...
echo.

REM Try to use dart to query the database
dart --version 2>nul
if errorlevel 1 (
    echo Dart not found in PATH
    echo Trying flutter...
    flutter --version 2>nul
    if errorlevel 1 (
        echo Flutter not found either
        echo Please install Dart or Flutter to query the database
        pause
        exit /b 1
    )
)

echo Creating Dart script to query feature #4...
(
echo import 'dart:io';
echo import 'package:sqflite_common_ffi/sqflite_ffi.dart';
echo import 'package:path/path.dart';
echo
echo void main() async {
echo   sqfliteFfiInit();
echo   final database = openDatabase('^%cd^%/features.db');
echo   final db = await database;
echo
echo   final List^<Map^> maps = await db.query(
echo     'features',
echo     where: 'id = ?',
echo     whereArgs: [4],
echo   );
echo
echo   if (maps.isNotEmpty) {
echo     final feature = maps.first;
echo     print('ID: ${feature['id']}');
echo     print('Category: ${feature['category']}');
echo     print('Name: ${feature['name']}');
echo     print('Description: ${feature['description']}');
echo     print('Steps: ${feature['steps']}');
echo     print('Passes: ${feature['passes']}');
echo     print('In Progress: ${feature['in_progress']}');
echo   } else {
echo     print('Feature #4 not found');
echo   }
echo
echo   await db.close();
echo }
) > temp_check_feature4.dart

echo Running Dart script...
dart run temp_check_feature4.dart
del temp_check_feature4.dart
pause
