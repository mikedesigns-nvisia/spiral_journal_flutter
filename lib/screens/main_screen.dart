import 'package:flutter/material.dart';
import 'package:spiral_journal/screens/journal_screen.dart';
import 'package:spiral_journal/screens/journal_history_screen.dart';
import 'package:spiral_journal/screens/emotional_mirror_screen.dart';
import 'package:spiral_journal/screens/core_library_screen.dart';
import 'package:spiral_journal/screens/settings_screen.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';
import 'package:spiral_journal/utils/iphone_detector.dart';
import 'package:spiral_journal/services/navigation_service.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/services/navigation_flow_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set up the navigation service callback
    NavigationService.instance.setTabChangeCallback(_switchToTab);
    
    // Update navigation flow controller state when main screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flowController = NavigationFlowController.instance;
      if (flowController.isFlowActive) {
        flowController.updateStateFromRoute('/main');
      }
    });
  }

  void _switchToTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  List<Widget> get _screens => [
    const JournalScreen(),
    const JournalHistoryScreen(),
    const EmotionalMirrorScreen(),
    const CoreLibraryScreen(),
    const SettingsScreen(),
  ];


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.getPrimaryGradient(context),
      ),
      child: AdaptiveScaffold(
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero, // Let individual screens handle their own padding
        body: _screens[_currentIndex],
        bottomNavigationBar: AdaptiveBottomNavigation(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: _getAdaptiveNavItems(context),
          backgroundColor: Colors.transparent,
          selectedItemColor: DesignTokens.getPrimaryColor(context),
          unselectedItemColor: DesignTokens.getTextTertiary(context),
        ),
      ),
    );
  }

  /// Get navigation items with adaptive icon sizes
  List<BottomNavigationBarItem> _getAdaptiveNavItems(BuildContext context) {
    final iconSize = iPhoneDetector.getAdaptiveIconSize(
      context,
      base: DesignTokens.iconSizeL,
    );

    return [
      BottomNavigationBarItem(
        icon: Icon(Icons.edit_note_rounded, size: iconSize),
        label: 'Journal',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history_rounded, size: iconSize),
        label: 'History',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.psychology_rounded, size: iconSize),
        label: 'Mirror',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.auto_awesome_rounded, size: iconSize),
        label: 'Insights',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_rounded, size: iconSize),
        label: 'Settings',
      ),
    ];
  }
}
