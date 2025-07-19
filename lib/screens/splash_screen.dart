import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/widgets/app_background.dart';
import 'package:spiral_journal/services/navigation_flow_controller.dart';
import 'package:spiral_journal/services/fresh_install_manager.dart';

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
  Timer? _timer;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen: Initializing with duration: ${widget.displayDuration.inSeconds}s');
    if (FreshInstallManager.isFreshInstallMode && FreshInstallManager.config.enableLogging) {
      debugPrint('SplashScreen: Fresh install mode active - showing indicator: ${widget.showFreshInstallIndicator}');
    }
    _startTimer();
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
              child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Main app title
                  Text(
                    'Spiral Journal',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getPrimaryColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Optional tagline
                  Text(
                    'AI-powered personal growth through journaling',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.getTextSecondary(context),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  // Fresh install mode indicator
                  if (widget.showFreshInstallIndicator && FreshInstallManager.isFreshInstallMode) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 14,
                            color: AppTheme.getPrimaryColor(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Fresh Install Mode',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.getPrimaryColor(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Attribution section
                  Column(
                    children: [
                      // Powered by Anthropic
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Powered by ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.getTextTertiary(context),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Anthropic',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.getPrimaryColor(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Made by Mike
                      Text(
                        'Made by Mike',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.getTextTertiary(context),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
