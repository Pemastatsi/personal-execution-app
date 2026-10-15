import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A small local SQLite boundary for task data.
///
/// Data remains on the device. Windows uses the SQLite FFI factory; Android
/// uses the native sqflite implementation.
class TaskStore {
  TaskStore._(this._database);

  final sqflite.Database _database;

  static Future<TaskStore> open({String? databasePath}) async {
    if (Platform.isWindows) {
      sqfliteFfiInit();
      sqflite.databaseFactory = databaseFactoryFfi;
    }

    final filePath =
        databasePath ??
        path.join(
          await sqflite.getDatabasesPath(),
          'personal_execution_app.db',
        );
    final database = await sqflite.openDatabase(
      filePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return TaskStore._(database);
  }

  Future<int> addTask(String title) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Task title cannot be empty.');
    }

    return _database.insert('tasks', {
      'title': normalizedTitle,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getTasks() {
    return _database.query('tasks', orderBy: 'id ASC');
  }

  Future<void> close() => _database.close();
}
