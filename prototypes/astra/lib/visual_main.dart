import 'package:flutter/material.dart';
import 'exploration/concepts.dart';
import 'main.dart';
import 'model.dart';
import 'storage.dart';

/// Separate review entry point; the original application remains the default.
void main() => runApp(const VisualReview());

class VisualReview extends StatelessWidget {
  const VisualReview({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Astra · Visual exploration',
    debugShowCheckedModeBanner: false,
    theme: visualTheme(VisualDirection.precision, false),
    home: const _ReviewMenu(),
  );
}

class _ReviewMenu extends StatefulWidget {
  const _ReviewMenu();
  @override
  State<_ReviewMenu> createState() => _ReviewMenuState();
}

class _ReviewMenuState extends State<_ReviewMenu> {
  bool dark = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Astra / Design study')),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Three ways\nto find your focus.', style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 34, height: 1.1, letterSpacing: -1)),
      const SizedBox(height: 16),
      const Text('The same task, progress and controls. Choose a direction to explore; use Android Back from Today to return here.'),
      const SizedBox(height: 20),
      SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Start in dark theme'), value: dark, onChanged: (v) => setState(() => dark = v)),
      const SizedBox(height: 16),
      for (final direction in VisualDirection.values) ...[
        Text(['A — Precision Modern', 'B — Atmospheric Modern', 'C — Refined Minimalism'][direction.index], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(['Clear geometry. Decisive contrast. A compact ledger of real progress.', 'Soft illumination. Layered surfaces. A visible path forward.', 'Editorial rhythm. Warm material. A quietly confident next action.'][direction.index]),
        const SizedBox(height: 12),
        Row(children: [for (final page in [AppPage.focus, AppPage.roadmap]) Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: OutlinedButton(onPressed: () {
          final model = ExecutionModel(MemoryStore())..dark = dark..page = page;
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AstraApp(model: model, direction: direction))).then((_) => model.dispose());
        }, child: Text(page == AppPage.focus ? 'Focus' : 'Roadmap'))))]),
        const SizedBox(height: 28),
      ],
    ]),
  );
}
