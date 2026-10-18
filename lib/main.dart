import 'package:flutter/material.dart';

import 'storage/execution_state.dart';
import 'storage/task_store.dart';
import 'ui/focusflow_palette.dart';
import 'ui/focusflow_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await TaskStore.open();
  final checkpoint = await store.loadExecutionCheckpoint() ?? ExecutionCheckpoint();
  runApp(PersonalExecutionApp(store: store, initialCheckpoint: checkpoint));
}

class PersonalExecutionApp extends StatefulWidget {
  const PersonalExecutionApp({super.key, this.store, this.initialCheckpoint});

  /// Optional for widget tests; without a store, state stays in memory.
  final TaskStore? store;
  final ExecutionCheckpoint? initialCheckpoint;

  @override
  State<PersonalExecutionApp> createState() => _PersonalExecutionAppState();
}

class _PersonalExecutionAppState extends State<PersonalExecutionApp> {
  late final ExecutionCheckpoint _checkpoint;
  Future<void> _saveQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _checkpoint = widget.initialCheckpoint ?? ExecutionCheckpoint();
  }

  void _save() {
    final snapshot = _checkpoint.encode();
    final store = widget.store;
    if (store == null) return;
    // Serialize writes so a slow earlier request cannot overwrite newer work.
    _saveQueue = _saveQueue.then((_) =>
      store.saveExecutionCheckpoint(ExecutionCheckpoint.decode(snapshot)));
  }

  void _toggleTheme() {
    setState(() => _checkpoint.darkMode = !_checkpoint.darkMode);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusFlow',
      debugShowCheckedModeBanner: false,
      theme: FocusPalette.theme(Brightness.light),
      darkTheme: FocusPalette.theme(Brightness.dark),
      themeMode: _checkpoint.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: FocusFlowShell(
        checkpoint: _checkpoint,
        onCheckpointChanged: _save,
        onToggleTheme: _toggleTheme,
        darkMode: _checkpoint.darkMode,
      ),
    );
  }
}
