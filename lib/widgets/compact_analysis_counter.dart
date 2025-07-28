import 'package:flutter/material.dart';
import 'dart:async';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';

class CompactAnalysisCounter extends StatefulWidget {
  const CompactAnalysisCounter({super.key});

  @override
  State<CompactAnalysisCounter> createState() => _CompactAnalysisCounterState();
}

class _CompactAnalysisCounterState extends State<CompactAnalysisCounter> {
  Timer? _timer;
  Duration _timeUntilAnalysis = Duration.zero;
  bool _isAnalysisTime = false;

  @override
  void initState() {
    super.initState();
    _updateTimes();
    
    // Start timer to update every 5 minutes (less frequent for subtle UX)
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateTimes();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimes() {
    final now = DateTime.now();
    
    // Calculate 2 AM today or tomorrow (analysis time)
    DateTime analysisTime;
    if (now.hour < 2) {
      // If it's before 2 AM today, analysis is today at 2 AM
      analysisTime = DateTime(now.year, now.month, now.day, 2);
    } else {
      // If it's after 2 AM today, analysis is tomorrow at 2 AM
      analysisTime = DateTime(now.year, now.month, now.day + 1, 2);
    }

    setState(() {
      _timeUntilAnalysis = analysisTime.difference(now);
      _isAnalysisTime = now.hour >= 2 && now.hour < 3; // Between 2-3 AM
    });
  }

  String _getTimeText() {
    if (_isAnalysisTime) {
      return 'Analyzing...';
    } else if (_timeUntilAnalysis.inHours < 1) {
      return '${_timeUntilAnalysis.inMinutes}m';
    } else {
      return '${_timeUntilAnalysis.inHours}h';
    }
  }

  Color _getColor(BuildContext context) {
    if (_isAnalysisTime) {
      return DesignTokens.successColor;
    } else {
      return DesignTokens.getTextTertiary(context);
    }
  }

  String _getTooltipText() {
    if (_isAnalysisTime) {
      return 'Your journal entries are being analyzed by AI right now';
    } else if (_timeUntilAnalysis.inHours < 1) {
      return 'Entry will be processed in ${_timeUntilAnalysis.inMinutes} minutes';
    } else {
      return 'Entry will be processed in ${_timeUntilAnalysis.inHours} hours';
    }
  }

  void _showTooltip(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 80, // Position below the counter
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: EdgeInsets.all(DesignTokens.spaceM),
            decoration: BoxDecoration(
              color: DesignTokens.getBackgroundSecondary(context),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: _getColor(context).withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ResponsiveText(
              _getTooltipText(),
              baseFontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextPrimary(context),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Auto-dismiss after 3 seconds
    Timer(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTooltip(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceM,
          vertical: DesignTokens.spaceS,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: _getColor(context).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isAnalysisTime 
                  ? Icons.psychology_rounded
                  : Icons.schedule_rounded,
              color: _getColor(context),
              size: DesignTokens.iconSizeS,
            ),
            SizedBox(width: DesignTokens.spaceXS),
            ResponsiveText(
              _getTimeText(),
              baseFontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: _getColor(context),
            ),
          ],
        ),
      ),
    );
  }
}
