import 'dart:io';

import 'execution_state.dart';
import 'work_models.dart';

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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE TABLE execution_state (id INTEGER PRIMARY KEY CHECK (id = 1), payload TEXT NOT NULL)');
        await _createWorkspaceTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('CREATE TABLE execution_state (id INTEGER PRIMARY KEY CHECK (id = 1), payload TEXT NOT NULL)');
        }
        if (oldVersion < 3) await _createWorkspaceTables(db);
      },
    );
    return TaskStore._(database);
  }

  static Future<void> _createWorkspaceTables(sqflite.Database db) async {
    await db.execute('CREATE TABLE work_projects (id TEXT PRIMARY KEY, name TEXT NOT NULL, created_at TEXT NOT NULL)');
    await db.execute("CREATE TABLE work_items (id TEXT PRIMARY KEY, project_id TEXT REFERENCES work_projects(id) ON DELETE SET NULL, title TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', next_action TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'active', created_at TEXT NOT NULL, updated_at TEXT NOT NULL)");
    await db.execute('CREATE TABLE work_milestones (id TEXT PRIMARY KEY, task_id TEXT NOT NULL REFERENCES work_items(id) ON DELETE CASCADE, title TEXT NOT NULL, criteria TEXT NOT NULL, evidence TEXT NOT NULL DEFAULT \'\', position INTEGER NOT NULL, verified_at TEXT)');
  }

  Future<WorkProject> createProject(String name) async {
    final title = name.trim();
    if (title.isEmpty) throw ArgumentError('Project name cannot be empty');
    final now = DateTime.now().toUtc();
    final id = newLocalId();
    await _database.insert('work_projects', {'id': id, 'name': title, 'created_at': now.toIso8601String()});
    return WorkProject(id: id, name: title, createdAt: now);
  }

  Future<List<WorkProject>> listProjects() async =>
      (await _database.query('work_projects', orderBy: 'created_at ASC'))
          .map(WorkProject.fromRow).toList();

  Future<WorkItem> createWorkItem({
    required String title,
    String description = '',
    String nextAction = '',
    String? projectId,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) throw ArgumentError('Task title cannot be empty');
    final now = DateTime.now().toUtc();
    final id = newLocalId();
    await _database.insert('work_items', {
      'id': id, 'project_id': projectId, 'title': trimmed,
      'description': description.trim(), 'next_action': nextAction.trim(),
      'status': 'active', 'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    return WorkItem(id: id, projectId: projectId, title: trimmed,
      description: description.trim(), nextAction: nextAction.trim(),
      status: 'active', createdAt: now, updatedAt: now);
  }

  Future<List<WorkItem>> listWorkItems({bool includeCompleted = false}) async =>
      (await _database.query('work_items',
        where: includeCompleted ? null : "status = 'active'",
        orderBy: 'updated_at DESC')).map(WorkItem.fromRow).toList();

  Future<void> updateWorkItem(WorkItem item, {
    required String title, required String nextAction,
    required String description, String? projectId,
  }) async {
    if (title.trim().isEmpty) throw ArgumentError('Task title cannot be empty');
    await _database.update('work_items', {
      'title': title.trim(), 'next_action': nextAction.trim(),
      'description': description.trim(), 'project_id': projectId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> setWorkItemCompleted(String id, bool completed) async {
    await _database.update('work_items', {
      'status': completed ? 'completed' : 'active',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<WorkMilestone> addMilestone(String taskId, String title, String criteria) async {
    if (title.trim().isEmpty) throw ArgumentError('Milestone title cannot be empty');
    final count = sqflite.Sqflite.firstIntValue(await _database.rawQuery(
      'SELECT COUNT(*) FROM work_milestones WHERE task_id = ?', [taskId])) ?? 0;
    final id = newLocalId();
    await _database.insert('work_milestones', {'id': id, 'task_id': taskId,
      'title': title.trim(), 'criteria': criteria.trim(), 'evidence': '',
      'position': count, 'verified_at': null});
    return WorkMilestone(id: id, taskId: taskId, title: title.trim(),
      criteria: criteria.trim(), evidence: '', position: count);
  }

  Future<List<WorkMilestone>> listMilestones(String taskId) async =>
      (await _database.query('work_milestones', where: 'task_id = ?',
      whereArgs: [taskId], orderBy: 'position ASC'))
          .map(WorkMilestone.fromRow).toList();

  Future<void> verifyMilestone(String id, String evidence) async {
    if (evidence.trim().isEmpty) throw ArgumentError('Evidence is required');
    await _database.update('work_milestones', {
      'evidence': evidence.trim(),
      'verified_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = ? AND verified_at IS NULL', whereArgs: [id]);
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
