import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_execution_app/storage/execution_state.dart';
import 'package:personal_execution_app/storage/task_store.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;

  setUpAll(() {
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('personal-execution-');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'stores tasks locally and keeps them after reopening the database',
    () async {
      final databasePath = '${directory.path}/tasks.sqlite';
      final store = await TaskStore.open(databasePath: databasePath);

      final taskId = await store.addTask('  Plan one next step  ');
      final tasks = await store.getTasks();
      expect(tasks, hasLength(1));
      expect(tasks.single['id'], taskId);
      expect(tasks.single['title'], 'Plan one next step');
      await store.close();

      final reopenedStore = await TaskStore.open(databasePath: databasePath);
      expect(
        (await reopenedStore.getTasks()).single['title'],
        'Plan one next step',
      );
      await reopenedStore.close();
    },
  );

  test('persists exact task recovery state across a database restart', () async {
    final databasePath = '${directory.path}/recovery.sqlite';
    final store = await TaskStore.open(databasePath: databasePath);
    final state = ExecutionCheckpoint(selectedTaskId: 'application', darkMode: true);
    final task = state.forTask('indicator');
    task.actionIndex = 1;
    task.note = 'Compiler error on line 42';
    task.blocker = 'Need to understand the error';
    task.verifiedMilestones = 2;
    task.awaitingVerification = true;
    task.detailLevel = 2;
    task.lastTouched = DateTime.utc(2026, 10, 18, 12);
    await store.saveExecutionCheckpoint(state);
    await store.close();

    final reopened = await TaskStore.open(databasePath: databasePath);
    final recovered = await reopened.loadExecutionCheckpoint();
    expect(recovered, isNotNull);
    expect(recovered!.selectedTaskId, 'application');
    expect(recovered.darkMode, isTrue);
    expect(recovered.forTask('indicator').actionIndex, 1);
    expect(recovered.forTask('indicator').note, 'Compiler error on line 42');
    expect(recovered.forTask('indicator').blocker, 'Need to understand the error');
    expect(recovered.forTask('indicator').verifiedMilestones, 2);
    expect(recovered.forTask('indicator').awaitingVerification, isTrue);
    expect(recovered.forTask('indicator').detailLevel, 2);
    expect(recovered.forTask('indicator').lastTouched, DateTime.utc(2026, 10, 18, 12));
    await reopened.close();
  });

  test('overwrites only the latest atomic checkpoint', () async {
    final store = await TaskStore.open(databasePath: '${directory.path}/upsert.sqlite');
    expect(await store.loadExecutionCheckpoint(), isNull);
    final state = ExecutionCheckpoint();
    state.forTask('indicator').note = 'first';
    await store.saveExecutionCheckpoint(state);
    state.forTask('indicator').note = 'second';
    await store.saveExecutionCheckpoint(state);
    expect((await store.loadExecutionCheckpoint())!.forTask('indicator').note, 'second');
    await store.close();
  });

  test('rejects an empty task title', () async {
    final store = await TaskStore.open(
      databasePath: '${directory.path}/tasks.sqlite',
    );

    expect(() => store.addTask('  '), throwsArgumentError);
    await store.close();
  });
}
