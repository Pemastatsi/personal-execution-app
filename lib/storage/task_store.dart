import 'dart:io';

import 'execution_state.dart';

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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE TABLE execution_state (id INTEGER PRIMARY KEY CHECK (id = 1), payload TEXT NOT NULL)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('CREATE TABLE execution_state (id INTEGER PRIMARY KEY CHECK (id = 1), payload TEXT NOT NULL)');
        }
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

  /// Returns null until the user first saves a checkpoint.
  Future<ExecutionCheckpoint?> loadExecutionCheckpoint() async {
    final rows = await _database.query('execution_state',
        columns: ['payload'], where: 'id = ?', whereArgs: [1], limit: 1);
    if (rows.isEmpty) return null;
    return ExecutionCheckpoint.decode(rows.single['payload']! as String);
  }

  /// One atomic, last-complete snapshot; individual task changes are retained.
  Future<void> saveExecutionCheckpoint(ExecutionCheckpoint checkpoint) async {
    await _database.insert('execution_state', {
      'id': 1,
      'payload': checkpoint.encode(),
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  Future<void> close() => _database.close();
}
