import 'dart:io';
import 'dart:ui' as ui;
import 'package:astra/exploration/concepts.dart';
import 'package:astra/main.dart';
import 'package:astra/model.dart';
import 'package:astra/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fonts.dart';

void main() {
  Future<void> setup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadTestFonts();
  }

  for (final direction in VisualDirection.values) {
    for (final dark in [false, true]) {
      testWidgets(
        '${direction.name} $dark: flows, semantics and scalable content',
        (tester) async {
          await setup(tester);
          final model = ExecutionModel(MemoryStore())
            ..page = AppPage.focus
            ..dark = dark;
          await tester.pumpWidget(AstraApp(model: model, direction: direction));
          await tester.pumpAndSettle();
          expect(
            find.text('Open the editor and locate the error list.'),
            findsOneWidget,
          );
          final semantics = tester.ensureSemantics();
          try {
            expect(tester.takeException(), isNull);
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
          } finally {
            semantics.dispose();
          }
          await tester.ensureVisible(
            find.byKey(const Key('instruction-detail')),
          );
          await tester.tap(find.byKey(const Key('instruction-detail')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Micro'));
          await tester.pumpAndSettle();
          expect(model.selected.detail, Detail.micro);
          await tester.tap(find.byKey(const Key('complete-action')));
          await tester.pumpAndSettle();
          expect(model.selected.actionIndex, 1);
          expect(model.selected.verified, 2);
          await tester.tap(find.text('Undo'));
          await tester.pumpAndSettle();
          expect(model.selected.actionIndex, 0);
          await tester.ensureVisible(find.byKey(const Key('concept-tab-2')));
          await tester.tap(find.byKey(const Key('concept-tab-2')));
          await tester.pumpAndSettle();
          expect(model.page, AppPage.roadmap);
          await tester.tap(find.text('Define the signal rules'));
          await tester.pumpAndSettle();
          expect(
            find.text('Entry and exit rules saved in the project notes.'),
            findsOneWidget,
          );
          Navigator.of(tester.element(find.text('VERIFIED OUTCOME'))).pop();
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('concept-tab-1')));
          await tester.pumpAndSettle();
          expect(
            find.text('What done looks like'.toUpperCase()),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const Key('back-to-action')));
          await tester.pumpAndSettle();
          for (var i = 0; i < 4; i++) {
            await tester.tap(find.byKey(const Key('complete-action')));
            await tester.pumpAndSettle();
          }
          expect(model.selected.verified, 2);
          expect(model.selected.awaitingVerification, isTrue);
          await tester.tap(find.byKey(const Key('verify-outcome')));
          await tester.pumpAndSettle();
          expect(model.selected.verified, 3);
          await tester.tap(find.byKey(const Key('concept-theme')));
          await tester.pumpAndSettle();
          expect(model.dark, !dark);
          await tester.tap(find.byKey(const Key('ask-ai')));
          await tester.pumpAndSettle();
          expect(model.page, AppPage.coach);
          model.go(AppPage.focus);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('switch-task')));
          await tester.pumpAndSettle();
          expect(model.page, AppPage.recovery);
          final original = model.selected;
          model.resume(model.tasks[1]);
          model.resume(original);
          expect(model.selected.verified, 3);
          for (final page in [AppPage.focus, AppPage.roadmap]) {
            model.go(page);
            await tester.pumpWidget(
              MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: AstraApp(model: model, direction: direction),
              ),
            );
            // MaterialApp obtains platform scaling, so set it at the dispatcher too.
            tester.platformDispatcher.textScaleFactorTestValue = 2;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(
                Key(
                  page == AppPage.focus ? 'complete-action' : 'back-to-action',
                ),
              ),
              findsOneWidget,
            );
          }
        },
      );
    }
  }

  testWidgets('all initial concepts remain usable at 200 percent text', (
    tester,
  ) async {
    await setup(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final direction in VisualDirection.values) {
      for (final dark in [false, true]) {
        for (final page in [AppPage.focus, AppPage.roadmap]) {
          final model = ExecutionModel(MemoryStore())
            ..page = page
            ..dark = dark;
          await tester.pumpWidget(
            AstraApp(
              key: ValueKey('$direction-$dark-$page'),
              model: model,
              direction: direction,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final button = find.byKey(
            Key(page == AppPage.focus ? 'complete-action' : 'back-to-action'),
          );
          expect(button.hitTestable(), findsOneWidget);
        }
      }
    }
  });

  testWidgets('export twelve comparable Flutter screens', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_EXPLORATION')) {
      return;
    }
    await setup(tester);
    final originalShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      for (final direction in VisualDirection.values) {
        for (final dark in [false, true]) {
          for (final page in [AppPage.focus, AppPage.roadmap]) {
            final model = ExecutionModel(MemoryStore())
              ..dark = dark
              ..page = page;
            final key = GlobalKey();
            await tester.pumpWidget(
              RepaintBoundary(
                key: key,
                child: AstraApp(model: model, direction: direction),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.runAsync(() async {
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 2);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(
                'visual-exploration/screenshots',
              ).create(recursive: true);
              await File(
                'visual-exploration/screenshots/${direction.name}-${page.name}-${dark ? 'dark' : 'light'}.png',
              ).writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
      }
    } finally {
      debugDisableShadows = originalShadows;
    }
  });
}
