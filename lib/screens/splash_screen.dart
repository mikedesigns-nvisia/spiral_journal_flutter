import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/widgets/app_background.dart';

class SplashScreen extends StatefulWidget {
  final Duration displayDuration;
  final VoidCallback? onComplete;
  
  const SplashScreen({
    super.key,
    this.displayDuration = const Duration(seconds: 2),
    this.onComplete,
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
  @override
  Widget build(BuildContext context) {
    // Add debug logging
    debugPrint('SplashScreen: Building splash screen widget');
    
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: GestureDetector(
            onTap: _handleTap,
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
    );
  }
}
