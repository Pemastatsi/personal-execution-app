import 'package:flutter/material.dart';

import 'ui/focusflow_palette.dart';
import 'ui/focusflow_shell.dart';

void main() => runApp(const PersonalExecutionApp());

/// UI demonstration. Real task persistence remains behind TaskStore and is
/// intentionally not connected to the mock data shown by this preview.
class PersonalExecutionApp extends StatefulWidget {
  const PersonalExecutionApp({super.key});

  @override
  State<PersonalExecutionApp> createState() => _PersonalExecutionAppState();
}

class _PersonalExecutionAppState extends State<PersonalExecutionApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusFlow',
      debugShowCheckedModeBanner: false,
      theme: FocusPalette.theme(Brightness.light),
      darkTheme: FocusPalette.theme(Brightness.dark),
      themeMode: _themeMode,
      home: FocusFlowShell(
        onToggleTheme: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.dark
                ? ThemeMode.light
                : ThemeMode.dark;
          });
        },
        darkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
