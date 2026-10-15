import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design.dart';
import 'model.dart';
import 'screens.dart';
import 'storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? await SqliteStore.open()
        : MemoryStore();
    final model = ExecutionModel(store);
    await model.restore();
    runApp(AstraApp(model: model));
  } catch (_) {
    runApp(
      MaterialApp(
        theme: astraTheme(false),
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Your saved place couldn’t be opened.',
                    style: TextStyle(fontSize: 26),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your saved data has not been replaced. Try opening it again.',
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton('Try again', onPressed: main),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AstraApp extends StatelessWidget {
  final ExecutionModel model;
  const AstraApp({super.key, required this.model});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => MaterialApp(
      title: 'Astra',
      debugShowCheckedModeBanner: false,
      theme: astraTheme(false),
      darkTheme: astraTheme(true),
      themeMode: model.dark ? ThemeMode.dark : ThemeMode.light,
      home: AstraShell(model: model),
    ),
  );
}

class AstraShell extends StatefulWidget {
  final ExecutionModel model;
  const AstraShell({super.key, required this.model});
  @override
  State<AstraShell> createState() => _AstraShellState();
}

class _AstraShellState extends State<AstraShell> {
  AppPage? _lastPage;
  ExecutionModel get model => widget.model;
  @override
  Widget build(BuildContext context) {
    if (_lastPage != null && _lastPage != model.page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { ScaffoldMessenger.of(context).clearSnackBars(); }
      });
    }
    _lastPage = model.page;
    final c = AstraColors.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: model.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: model.page == AppPage.home,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            model.go(
              model.page == AppPage.coach ? AppPage.focus : AppPage.home,
            );
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    if (model.saveFailed)
                      MaterialBanner(
                        content: const Text(
                          'Your latest changes could not be saved. Keep the app open and retry.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: model.changed,
                            child: const Text('Retry save'),
                          ),
                        ],
                      ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: KeyedSubtree(
                          key: ValueKey(model.page),
                          child: switch (model.page) {
                            AppPage.home => HomeScreen(model: model),
                            AppPage.focus => FocusScreen(model: model),
                            AppPage.coach => CoachScreen(model: model),
                            AppPage.roadmap => RoadmapScreen(model: model),
                            AppPage.recovery => RecoveryScreen(model: model),
                          },
                        ),
                      ),
                    ),
                    if (model.page == AppPage.home)
                      Container(
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: c.line)),
                        ),
                        child: Row(
                          children: [
                            _nav(
                              context,
                              Icons.home_outlined,
                              'Today',
                              true,
                              () => model.go(AppPage.home),
                            ),
                            _nav(
                              context,
                              Icons.center_focus_strong_outlined,
                              'Focus',
                              false,
                              () => model.active == null
                                  ? model.go(AppPage.recovery)
                                  : model.resume(model.active!),
                            ),
                            _nav(
                              context,
                              Icons.route_outlined,
                              'Roadmap',
                              false,
                              () => model.openRoadmap(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(
    BuildContext context,
    IconData icon,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final c = AstraColors.of(context);
    return Expanded(
      child: Semantics(
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 23, color: selected ? c.accent : c.muted),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? c.accent : c.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
