import 'package:astra/main.dart';
import 'package:astra/model.dart';
import 'package:astra/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ExecutionModel> launch(WidgetTester tester) async {
  tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
  addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  final model=ExecutionModel(MemoryStore());
  await tester.pumpWidget(AstraApp(model:model));await tester.pumpAndSettle();return model;
}

void main(){
  testWidgets('resume, complete, request help, attach screenshot, and return to exact action',(tester) async {
    final model=await launch(tester);
    await tester.tap(find.byKey(const Key('resume-focus')));await tester.pumpAndSettle();
    expect(find.text('Open the editor and locate the error list.'),findsOneWidget);
    await tester.tap(find.byKey(const Key('complete-action')));await tester.pumpAndSettle();
    expect(find.text('Open the first error in the list.'),findsOneWidget);
    await tester.tap(find.byKey(const Key('stuck')));await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('attach-screenshot')));await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('use-screenshot')));await tester.pumpAndSettle();
    expect(model.selected.chat.last.text,contains('line 42'));
    await tester.tap(find.text('Back to focus'));await tester.pumpAndSettle();
    expect(find.text('Open the first error in the list.'),findsOneWidget);
    expect(model.selected.verified,2);expect(tester.takeException(),isNull);
  });
  testWidgets('instant task switch preserves the original position',(tester) async {
    final model=await launch(tester);
    model.resume(model.selected);model.completeAction();await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch-task')));await tester.pumpAndSettle();
    final application=find.text('Send an application form');
    await tester.ensureVisible(application);await tester.tap(application);await tester.pumpAndSettle();
    expect(find.text('Find the required ID document.'),findsOneWidget);
    await tester.tap(find.byKey(const Key('switch-task')));await tester.pumpAndSettle();
    final indicator=find.text('Build a trading indicator');
    await tester.ensureVisible(indicator);await tester.tap(indicator);await tester.pumpAndSettle();
    expect(find.text('Open the first error in the list.'),findsOneWidget);
  });
  testWidgets('theme, quick capture, and roadmap are interactive',(tester) async {
    final model=await launch(tester);
    await tester.tap(find.byKey(const Key('theme-toggle')));await tester.pumpAndSettle();expect(model.dark,isTrue);
    final capture=find.byKey(const Key('capture-task'));await tester.ensureVisible(capture);await tester.tap(capture);await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('capture-input')),'Book an eye test');
    await tester.tap(find.text('Save for later'));await tester.pumpAndSettle();
    expect(model.tasks.last.title,'Book an eye test');expect(model.activeId,'indicator');
    await tester.tap(find.text('Roadmap'));await tester.pumpAndSettle();
    expect(find.text('Real progress.'),findsOneWidget);
    await tester.tap(find.text('Milestone'));await tester.pumpAndSettle();
    expect(find.text('WHAT DONE LOOKS LIKE'),findsOneWidget);
    await tester.tap(find.text('Focus'));await tester.pumpAndSettle();expect(model.page,AppPage.focus);
  });
  testWidgets('user confirms objective milestone separately from actions',(tester) async {
    final model=await launch(tester);model.resume(model.selected);
    for(var i=0;i<4;i++){await tester.pumpAndSettle();await tester.tap(find.byKey(const Key('complete-action')));}
    await tester.pumpAndSettle();expect(model.selected.verified,2);
    expect(find.text('The compiler reports 0 errors.'),findsOneWidget);
    await tester.tap(find.byKey(const Key('verify-outcome')));await tester.pumpAndSettle();
    expect(model.selected.verified,3);expect(find.text('Attach the indicator to a demo chart.'),findsOneWidget);
  });
  for(final scale in [1.0,1.5,2.0]) {
    for(final dark in [false,true]) {
      testWidgets('all screens fit at text scale $scale, dark $dark',(tester) async {
        final model=await launch(tester);model.dark=dark;
        for(final page in AppPage.values) {
          model.page=page;
          if(page==AppPage.coach){model.openCoach();}
          await tester.pumpWidget(MediaQuery(data:MediaQueryData(textScaler:TextScaler.linear(scale)),
            child:AstraApp(model:model)));
          // MaterialApp uses the view's accessibility text scale.
          tester.platformDispatcher.textScaleFactorTestValue=scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          model.notifyListeners();await tester.pumpAndSettle();
          expect(tester.takeException(),isNull,reason:'$page, scale $scale, dark $dark');
        }
      });
    }
  }
}
