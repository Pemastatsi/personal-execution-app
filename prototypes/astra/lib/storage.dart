import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Only this boundary knows about SQLite. No credentials or network are used.
abstract class CheckpointStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> value);
}

class MemoryStore implements CheckpointStore {
  String? _value;
  @override
  Future<Map<String, dynamic>?> read() async =>
      _value == null ? null : jsonDecode(_value!) as Map<String, dynamic>;
  @override
  Future<void> write(Map<String, dynamic> value) async {
    _value = jsonEncode(value);
  }
}

class SqliteStore implements CheckpointStore {
  final Database database;
  SqliteStore(this.database);
  static Future<SqliteStore> open() async {
    final db = await openDatabase(
      path.join(await getDatabasesPath(), 'astra_concept.db'),
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE checkpoint (id INTEGER PRIMARY KEY, value TEXT NOT NULL)',
      ),
    );
    return SqliteStore(db);
  }

  @override
  Future<Map<String, dynamic>?> read() async {
    final rows = await database.query(
      'checkpoint',
      where: 'id = ?',
      whereArgs: [1],
    );
    return rows.isEmpty
        ? null
        : jsonDecode(rows.first['value'] as String) as Map<String, dynamic>;
  }

  @override
  Future<void> write(Map<String, dynamic> value) async {
    await database.insert('checkpoint', {
      'id': 1,
      'value': jsonEncode(value),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
