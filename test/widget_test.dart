import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_execution_app/main.dart';

void main() {
  testWidgets('private-client blocker prevents sign-in and sending', (tester) async {
    await tester.pumpWidget(const PersonalExecutionApp());
    expect(find.text('Connection awaiting eligibility confirmation'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continue with ChatGPT'),
      ).onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(find.byKey(const Key('local-draft')), 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('local-draft')), 'A local draft');
    await tester.scrollUntilVisible(find.text('Send'), 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send')).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Attach screenshot'),
      ).onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(find.textContaining('No models have been requested.'), -200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('No models have been requested.'), findsOneWidget);
  });

  testWidgets('local draft can be cleared without a connection', (tester) async {
    await tester.pumpWidget(const PersonalExecutionApp());
    await tester.scrollUntilVisible(find.byKey(const Key('local-draft')), 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('local-draft')), 'A local draft');
    await tester.scrollUntilVisible(find.text('Clear draft'), 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear draft'));
    await tester.pump();
    expect(find.text('A local draft'), findsNothing);
  });

  testWidgets('fallback copies only the official address, never the draft', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, null,
      );
    });
    await tester.pumpWidget(const PersonalExecutionApp());
    await tester.scrollUntilVisible(find.byKey(const Key('local-draft')), 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('local-draft')), 'Private draft');
    await tester.scrollUntilVisible(find.text('Copy official ChatGPT address'), 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text('Copy official ChatGPT address')), alignment: 0.5,
    );
    await tester.pumpAndSettle();
    expect(find.text('Copy official ChatGPT address').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Copy official ChatGPT address'));
    await tester.pumpAndSettle();
    final clipboardCall = calls.singleWhere((call) => call.method == 'Clipboard.setData');
    expect(clipboardCall.arguments, {'text': 'https://chatgpt.com/'});
    expect(find.text('ChatGPT address copied.'), findsOneWidget);
  });

  testWidgets('clipboard failure offers a manual fallback', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'unavailable');
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, null,
      );
    });
    await tester.pumpWidget(const PersonalExecutionApp());
    await tester.scrollUntilVisible(find.text('Copy official ChatGPT address'), 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text('Copy official ChatGPT address')), alignment: 0.5,
    );
    await tester.pumpAndSettle();
    expect(find.text('Copy official ChatGPT address').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Copy official ChatGPT address'));
    await tester.pumpAndSettle();
    expect(find.text('Open https://chatgpt.com/ in your browser.'), findsOneWidget);
  });

  testWidgets('narrow screen with large text stays scrollable', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const PersonalExecutionApp());
    await tester.scrollUntilVisible(find.text('Copy official ChatGPT address'), 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Copy official ChatGPT address').hitTestable(), findsOneWidget);
  });
}
