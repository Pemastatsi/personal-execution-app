import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_execution_app/main.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'allows browser sign-in but gates sending until a verified session',
    (tester) async {
      await tester.pumpWidget(const PersonalExecutionApp());
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Continue with ChatGPT'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.scrollUntilVisible(
        find.text('Send'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Send'))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const Key('local-draft')),
        'Private local draft',
      );
      await tester.ensureVisible(find.text('Clear conversation'));
      await tester.tap(find.text('Clear conversation'));
      await tester.pump();
      expect(find.text('Private local draft'), findsNothing);
    },
  );
  testWidgets('narrow screen and large text remain scrollable', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const PersonalExecutionApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Clear conversation'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
