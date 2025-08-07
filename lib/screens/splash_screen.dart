import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/widgets/app_background.dart';
import 'package:spiral_journal/services/navigation_flow_controller.dart';
import 'package:spiral_journal/design_system/heading_system.dart';
import 'package:spiral_journal/services/app_info_service.dart';

class SplashScreen extends StatefulWidget {
  final Duration displayDuration;
  final VoidCallback? onComplete;
  final bool showFreshInstallIndicator;
  
  const SplashScreen({
    super.key,
    this.displayDuration = const Duration(seconds: 2),
    this.onComplete,
    this.showFreshInstallIndicator = false,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AppInfoService _appInfoService = AppInfoService();
  Timer? _timer;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen: Initializing with duration: ${widget.displayDuration.inSeconds}s');
    _initializeAppInfo();
    _startTimer();
  }
  
  Future<void> _initializeAppInfo() async {
    try {
      await _appInfoService.initialize();
    } catch (e) {
      debugPrint('SplashScreen: Failed to initialize app info: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('SplashScreen: Disposing');
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    debugPrint('SplashScreen: Starting timer');
    _timer = Timer(widget.displayDuration, () {
      debugPrint('SplashScreen: Timer completed');
      if (mounted) {
        _handleComplete();
      }
    });
  }

  void _handleComplete() {
    debugPrint('SplashScreen: _handleComplete called - hasCompleted: $_hasCompleted, mounted: $mounted');
    if (!_hasCompleted && mounted) {
      _hasCompleted = true;
      debugPrint('SplashScreen: Calling onComplete callback');
      
      // Update navigation flow controller state
      final flowController = NavigationFlowController.instance;
      if (flowController.isFlowActive) {
        flowController.updateStateFromRoute('/');
      }
      
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        debugPrint('SplashScreen: Warning - onComplete callback is null');
      }
    }
  }

  void _handleTap() {
    debugPrint('SplashScreen: Tap detected');
    if (!_hasCompleted) {
      _handleComplete();
    }
  }

  void _handleLongPress() {
    debugPrint('SplashScreen: Long press detected - opening debug options');
    if (mounted) {
      _showDebugOptions();
    }
  }

  void _showDebugOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Options'),
        content: const Text('Choose a debug action:'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetOnboarding();
            },
            child: const Text('Reset Onboarding'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleComplete();
            },
            child: const Text('Skip Splash'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetOnboarding() async {
    try {
      // Import the onboarding controller to reset
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');
      await prefs.remove('quick_setup_config');
      await prefs.setBool('splashScreenEnabled', false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Onboarding reset! Restart the app to see onboarding.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error resetting onboarding: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    // Add debug logging
    debugPrint('SplashScreen: Building splash screen widget');
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final flowController = NavigationFlowController.instance;
          final canPop = await flowController.handleBackButton('/');
          if (canPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: GestureDetector(
              onTap: _handleTap,
              onLongPress: _handleLongPress,
              child: Column(
                children: [
                  // Top spacer
                  const Expanded(flex: 2, child: SizedBox()),
                  
                  // Main content - centered
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Main app title
                        HeadingSystem.pageHeading(context, _appInfoService.appName),
                        
                        const SizedBox(height: 16),
                        
                        // Optional tagline
                        Center(
                          child: Text(
                            'Personal growth through journaling',
                            style: HeadingSystem.getBodyLarge(context).copyWith(
                              color: AppTheme.getTextSecondary(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom spacer and attribution
                  const Expanded(flex: 2, child: SizedBox()),
                  
                  // Attribution at bottom
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48.0),
                    child: HeadingSystem.caption(context, 'Made by Mike'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
