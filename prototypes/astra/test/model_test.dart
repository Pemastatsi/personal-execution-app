import 'package:astra/model.dart';
import 'package:astra/storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'switching and process restart retain exact action, detail, blocker, and conversation',
    () async {
      final store = MemoryStore(), model = ExecutionModel(MemoryStore());
      final persistent = ExecutionModel(store);
      persistent.resume(persistent.selected);
      persistent.completeAction();
      persistent.setDetail(Detail.micro);
      persistent.openCoach(stuck: true);
      persistent.send('I cannot find the Toolbox');
      final expected = persistent.selected.nextAction;
      persistent.resume(persistent.tasks[1]);
      await persistent.flush();
      final restored = ExecutionModel(store);
      await restored.restore();
      expect(restored.activeId, 'application');
      restored.resume(restored.tasks[0]);
      expect(restored.selected.nextAction, expected);
      expect(restored.selected.detail, Detail.micro);
      expect(restored.selected.blocker, isNotEmpty);
      expect(restored.selected.chat.length, 3);
      expect(model.selected.verified, 2);
    },
  );
  test('micro actions and AI responses never verify an outcome', () {
    final model = ExecutionModel(MemoryStore());
    model.openCoach();
    model.send('Here is my screen', screenshot: true);
    for (var i = 0; i < 4; i++) {
      model.completeAction();
    }
    expect(model.selected.verified, 2);
    expect(model.selected.awaitingVerification, isTrue);
    model.completeAction();
    expect(model.selected.verified, 2);
    model.verifyOutcome();
    expect(model.selected.verified, 3);
    expect(model.selected.actionIndex, 0);
    expect(
      model.selected.action.title,
      'Attach the indicator to a demo chart.',
    );
    model.verifyOutcome();
    expect(model.selected.verified, 3);
  });
  test('capture is explicit and never replaces active focus', () {
    final model = ExecutionModel(MemoryStore());
    model.addTask('Book an eye test');
    expect(model.activeId, 'indicator');
    expect(model.tasks.length, 4);
    model.addTask('   ');
    expect(model.tasks.length, 4);
  });
  test('two-week checkpoint is retained until the user resumes', () {
    final model = ExecutionModel(MemoryStore());
    model.resume(model.tasks[1]);
    model.preview(model.tasks[0]);
    model.preview(model.selected);
    expect(DateTime.now().difference(model.selected.lastTouched).inDays, 14);
    model.resume(model.selected);
    expect(DateTime.now().difference(model.selected.lastTouched).inDays, 0);
  });
  test('completed tasks leave the next task selection available', () {
    final model = ExecutionModel(MemoryStore());
    model.resume(model.tasks[2]);
    model.completeAction();
    model.completeAction();
    model.verifyOutcome();
    expect(model.activeId, isNull);
    expect(model.available.length, 2);
  });
}
