import 'package:flutter/material.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/screens/main_screen.dart';

void main() {
  runApp(const SpiralJournalApp());
}

class SpiralJournalApp extends StatelessWidget {
  const SpiralJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spiral Journal',
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
