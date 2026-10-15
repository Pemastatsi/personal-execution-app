import 'package:flutter/material.dart';

void main() {
  runApp(const PersonalExecutionApp());
}

class PersonalExecutionApp extends StatelessWidget {
  const PersonalExecutionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Execution',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4757A5)),
        useMaterial3: true,
      ),
      home: const DevelopmentStarterPage(),
    );
  }
}

class DevelopmentStarterPage extends StatelessWidget {
  const DevelopmentStarterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.checklist_rounded, size: 40),
                SizedBox(height: 20),
                Text(
                  'A calmer way to get things done',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text('Development starter — your tasks stay on this device.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
