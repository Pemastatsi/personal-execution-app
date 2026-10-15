import 'dart:io';
import 'dart:ui' as ui;
import 'package:astra/main.dart';
import 'package:astra/model.dart';
import 'package:astra/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fonts.dart';

void main() {
  const export = bool.fromEnvironment('EXPORT_SCREENSHOTS');
  testWidgets('export real Flutter renders in both themes', (tester) async {
    if (!export) {
      return;
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadTestFonts();
    for (final dark in [false, true]) {
      for (final page in AppPage.values) {
        final model = ExecutionModel(MemoryStore())
          ..dark = dark
          ..page = page;
        if (page == AppPage.coach) {
          model.openCoach();
          model.send('Here’s the error I’m seeing.', screenshot: true);
        }
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: AstraApp(model: model),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('screenshots').create(recursive: true);
          await File(
            'screenshots/${page.name}-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
  });
}
