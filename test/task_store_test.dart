import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

  test('rejects an empty task title', () async {
    final store = await TaskStore.open(
      databasePath: '${directory.path}/tasks.sqlite',
    );

    expect(() => store.addTask('  '), throwsArgumentError);
    await store.close();
  });
}
