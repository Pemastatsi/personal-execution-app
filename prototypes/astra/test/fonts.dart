import 'package:flutter/services.dart';

bool _loaded = false;
Future<void> loadTestFonts() async {
  if (_loaded) {
    return;
  }
  for (final name in ['Manrope', 'Newsreader', 'JetBrainsMono']) {
    final loader = FontLoader(name)
      ..addFont(rootBundle.load('assets/fonts/$name.ttf'));
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  _loaded = true;
}
