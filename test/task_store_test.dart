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


  test('real projects and tasks persist after restart and support edits', () async {
    final file = '${directory.path}/real.sqlite';
    final db = await TaskStore.open(databasePath: file);
    final project = await db.createProject('Family admin');
    final task = await db.createWorkItem(
      title: 'Prepare application', nextAction: 'Find passport',
      projectId: project.id);
    expect((await db.listWorkItems()).single.title, 'Prepare application');
    await db.updateWorkItem(task, title: 'Prepare application',
      nextAction: 'Open form', description: 'Read instructions',
      projectId: project.id);
    final milestone = await db.addMilestone(task.id, 'Document ready', 'Check expiry');
    await db.verifyMilestone(milestone.id, 'Passport checked, valid');
    await db.close();

    final reopened = await TaskStore.open(databasePath: file);
    expect((await reopened.listProjects()).single.name, 'Family admin');
    expect((await reopened.listWorkItems()).single.nextAction, 'Open form');
    final outcomes = await reopened.listMilestones(task.id);
    expect(outcomes.single.verified, isTrue);
    expect(outcomes.single.evidence, 'Passport checked, valid');
    await reopened.setWorkItemCompleted(task.id, true);
    expect(await reopened.listWorkItems(), isEmpty);
    expect((await reopened.listWorkItems(includeCompleted: true)).single.completed, isTrue);
    await reopened.setWorkItemCompleted(task.id, false);
    expect((await reopened.listWorkItems()).single.id, task.id);
    await reopened.close();
  });

  test('real tasks validate empty titles and evidence', () async {
    final db = await TaskStore.open(databasePath: '${directory.path}/validation.sqlite');
    expect(() => db.createWorkItem(title: '  '), throwsArgumentError);
    expect(() => db.createProject('  '), throwsArgumentError);
    final task = await db.createWorkItem(title: 'Test');
    final stage = await db.addMilestone(task.id, 'Check outcome', '');
    expect(() => db.verifyMilestone(stage.id, ' '), throwsArgumentError);
    expect((await db.listMilestones(task.id)).single.verified, isFalse);
    await db.close();
  });

  test('rejects an empty task title', () async {
    final store = await TaskStore.open(
      databasePath: '${directory.path}/tasks.sqlite',
    );

    expect(() => store.addTask('  '), throwsArgumentError);
    await store.close();
  });
}
