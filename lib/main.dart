import 'package:flutter/material.dart';

import 'stage2/stage2_page.dart';

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
      home: const Stage2Page(),
    );
  }
}
