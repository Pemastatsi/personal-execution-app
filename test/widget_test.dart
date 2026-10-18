import 'package:flutter/material.dart';
import 'package:personal_execution_app/storage/execution_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_execution_app/main.dart';

void main() {
  testWidgets('shows the sample dashboard and opens Focus Mode', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PersonalExecutionApp());
    expect(find.text('One thing at a time.'), findsOneWidget);
    expect(find.text('Build a trading indicator'), findsOneWidget);

    await tester.tap(find.textContaining('Start focus'));
    await tester.pumpAndSettle();
    expect(find.text('FOCUS SESSION'), findsOneWidget);
    expect(find.text('Open the editor and locate the error list.'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('Mark step done'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Mark step done'));
    await tester.pumpAndSettle();
    expect(find.text('Step recorded'), findsOneWidget);
  });

  testWidgets('switches mock projects and toggles theme', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PersonalExecutionApp());
    await tester.tap(find.byTooltip('Toggle color theme'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark);

    await tester.tap(find.text('Projects').last);
    await tester.pumpAndSettle();
    expect(find.text('Switch without losing context.'), findsOneWidget);

    await tester.tap(find.text('Send an application form'));
    await tester.pumpAndSettle();
    expect(find.text('Find the required ID document.'), findsOneWidget);
  });
  testWidgets('restores selected task, note, step and theme from checkpoint', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final checkpoint = ExecutionCheckpoint(
      selectedTaskId: 'application', darkMode: true,
    );
    checkpoint.forTask('application')
      ..actionIndex = 1
      ..note = 'Passport is in the documents folder';
    await tester.pumpWidget(PersonalExecutionApp(initialCheckpoint: checkpoint));
    expect(Theme.of(tester.element(find.byType(Scaffold))).brightness, Brightness.dark);
    expect(find.text('Send an application form'), findsOneWidget);
    await tester.tap(find.textContaining('Start focus'));
    await tester.pumpAndSettle();
    expect(find.text('Review the form for missing required fields.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Passport is in the documents folder');
  });

  testWidgets('milestone verification requires separate explicit confirmation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final checkpoint = ExecutionCheckpoint();
    await tester.pumpWidget(PersonalExecutionApp(initialCheckpoint: checkpoint));
    await tester.tap(find.textContaining('Start focus'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Mark step done'));
    await tester.tap(find.textContaining('Mark step done'));
    await tester.pumpAndSettle();
    expect(checkpoint.forTask('indicator').verifiedMilestones, 0);
    await tester.ensureVisible(find.text('Verify milestone outcome'));
    await tester.tap(find.text('Verify milestone outcome'));
    await tester.pumpAndSettle();
    expect(find.text('Verify this outcome?'), findsOneWidget);
    await tester.tap(find.text('I verified it'));
    await tester.pumpAndSettle();
    expect(checkpoint.forTask('indicator').verifiedMilestones, 1);
  });

}
