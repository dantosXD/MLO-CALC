// ignore_for_file: avoid_print

import 'dart:io';

void main() async {
  final dbFile = File('features.db');
  if (!await dbFile.exists()) {
    print('{"error": "features.db not found"}');
    return;
  }

  // Read and output feature #13 using sqlite3
  final result = Process.runSync('sqlite3', ['features.db', 'SELECT json_object("id", id, "category", category, "name", name, "description", description, "steps", steps, "passes", passes, "in_progress", in_progress, "dependencies", dependencies, "priority", priority) FROM features WHERE id = 13;']);

  if (result.exitCode == 0) {
    print(result.stdout);
  } else {
    print('{"error": "Failed to query feature #13"}');
  }
}
