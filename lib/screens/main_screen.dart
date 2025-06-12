import 'package:flutter/material.dart';
import 'package:spiral_journal/screens/journal_screen.dart';
import 'package:spiral_journal/screens/journal_history_screen.dart';
import 'package:spiral_journal/screens/emotional_mirror_screen.dart';
import 'package:spiral_journal/screens/core_library_screen.dart';
import 'package:spiral_journal/screens/settings_screen.dart';
import 'package:spiral_journal/theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const JournalScreen(),
    const JournalHistoryScreen(),
    const EmotionalMirrorScreen(),
    const CoreLibraryScreen(),
    const SettingsScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.edit_note_rounded),
      label: 'Journal',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.history_rounded),
      label: 'History',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.psychology_rounded),
      label: 'Mirror',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.auto_awesome_rounded),
      label: 'Insights',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          border: Border(
            top: BorderSide(
              color: AppTheme.backgroundTertiary,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: _navItems,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.backgroundPrimary,
          selectedItemColor: AppTheme.primaryOrange,
          unselectedItemColor: AppTheme.textTertiary,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'NotoSansJP',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'NotoSansJP',
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          elevation: 0,
        ),
      ),
      extendBody: true,
    );
  }
}
