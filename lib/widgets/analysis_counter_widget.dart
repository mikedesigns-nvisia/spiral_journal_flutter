import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';

class AnalysisCounterWidget extends StatefulWidget {
  const AnalysisCounterWidget({super.key});

  @override
  State<AnalysisCounterWidget> createState() => _AnalysisCounterWidgetState();
}

class _AnalysisCounterWidgetState extends State<AnalysisCounterWidget>
    with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  Duration _timeUntilMidnight = Duration.zero;
  Duration _timeUntilAnalysis = Duration.zero;
  double _dayProgress = 0.0;
  bool _isNearCutoff = false;
  bool _isAnalysisTime = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _progressController.forward();

    // Calculate initial times
    _updateTimes();
    
    // Start timer to update every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTimes();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _updateTimes() {
    final now = DateTime.now();
    
    // Calculate midnight today (journal cutoff)
    final midnight = DateTime(now.year, now.month, now.day + 1);
    
    // Calculate 2 AM today or tomorrow (analysis time)
    DateTime analysisTime;
    if (now.hour < 2) {
      // If it's before 2 AM today, analysis is today at 2 AM
      analysisTime = DateTime(now.year, now.month, now.day, 2);
    } else {
      // If it's after 2 AM today, analysis is tomorrow at 2 AM
      analysisTime = DateTime(now.year, now.month, now.day + 1, 2);
    }

    // Calculate progress through the day (0.0 to 1.0)
    final startOfDay = DateTime(now.year, now.month, now.day);
    final minutesSinceStart = now.difference(startOfDay).inMinutes;
    final dayProgress = (minutesSinceStart / (24 * 60)).clamp(0.0, 1.0);

    setState(() {
      _timeUntilMidnight = midnight.difference(now);
      _timeUntilAnalysis = analysisTime.difference(now);
      _dayProgress = dayProgress;
      _isNearCutoff = _timeUntilMidnight.inHours < 3; // Last 3 hours
      _isAnalysisTime = now.hour >= 2 && now.hour < 3; // Between 2-3 AM
    });
  }

  Color _getProgressColor(BuildContext context) {
    if (_isAnalysisTime) {
      return DesignTokens.successColor;
    } else if (_isNearCutoff) {
      return DesignTokens.errorColor;
    } else if (_dayProgress > 0.7) {
      return DesignTokens.warningColor;
    } else {
      return DesignTokens.getPrimaryColor(context);
    }
  }

  String _getMainMessage() {
    if (_isAnalysisTime) {
      return 'AI Analysis in Progress';
    } else if (_timeUntilMidnight.inHours < 1) {
      return 'Journal closes soon!';
    } else if (_timeUntilMidnight.inHours < 3) {
      return 'Last chance to write';
    } else if (_dayProgress < 0.3) {
      return 'Fresh start today';
    } else {
      return 'Keep writing';
    }
  }

  String _getSubMessage() {
    if (_isAnalysisTime) {
      return 'Your insights are being generated...';
    } else if (_timeUntilMidnight.inMinutes < 60) {
      final minutes = _timeUntilMidnight.inMinutes;
      return 'Closes in ${minutes}m';
    } else {
      final hours = _timeUntilMidnight.inHours;
      final minutes = _timeUntilMidnight.inMinutes % 60;
      return 'Analysis in ${_timeUntilAnalysis.inHours}h ${_timeUntilAnalysis.inMinutes % 60}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _progressAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: DesignTokens.getBackgroundSecondary(context),
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            border: Border.all(
              color: _getProgressColor(context).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _getProgressColor(context).withValues(alpha: 0.1),
                blurRadius: DesignTokens.elevationM,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(DesignTokens.spaceL),
          child: Row(
            children: [
              // Circular Progress Ring
              Transform.scale(
                scale: _isNearCutoff || _isAnalysisTime 
                    ? _pulseAnimation.value 
                    : 1.0,
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      // Background circle
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DesignTokens.getBackgroundTertiary(context),
                        ),
                      ),
                      // Progress circle
                      CustomPaint(
                        size: const Size(60, 60),
                        painter: CircularProgressPainter(
                          progress: _dayProgress * _progressAnimation.value,
                          color: _getProgressColor(context),
                          strokeWidth: 4,
                        ),
                      ),
                      // Center icon
                      Center(
                        child: Icon(
                          _isAnalysisTime 
                              ? Icons.psychology_rounded
                              : _isNearCutoff
                                  ? Icons.schedule_rounded
                                  : Icons.auto_awesome_rounded,
                          color: _getProgressColor(context),
                          size: DesignTokens.iconSizeL,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(width: DesignTokens.spaceL),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      _getMainMessage(),
                      baseFontSize: DesignTokens.fontSizeL,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: DesignTokens.getTextPrimary(context),
                    ),
                    SizedBox(height: DesignTokens.spaceXS),
                    ResponsiveText(
                      _getSubMessage(),
                      baseFontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightRegular,
                      color: DesignTokens.getTextSecondary(context),
                    ),
                  ],
                ),
              ),
              
              // Status indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getProgressColor(context),
                  boxShadow: [
                    BoxShadow(
                      color: _getProgressColor(context).withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress, // Progress amount
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
