import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Service for optimizing chart rendering during slide transitions
class ChartOptimizationService {
  static final Map<String, Widget> _chartCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 2);
  static bool _isTransitioning = false;
  static int _frameCount = 0;
  static double _averageFrameTime = 16.67; // Target 60fps

  /// Initialize the optimization service
  static void initialize() {
    SchedulerBinding.instance.addPersistentFrameCallback(_frameCallback);
  }

  /// Frame callback to monitor performance
  static void _frameCallback(Duration timestamp) {
    _frameCount++;
    
    // Calculate average frame time every 60 frames
    if (_frameCount % 60 == 0) {
      final currentTime = timestamp.inMicroseconds / 1000.0;
      _averageFrameTime = currentTime / 60.0;
      
      // Reset for next measurement
      _frameCount = 0;
    }
  }

  /// Set transition state to optimize rendering
  static void setTransitionState(bool isTransitioning) {
    _isTransitioning = isTransitioning;
    
    if (isTransitioning) {
      // Reduce chart complexity during transitions
      _optimizeForTransition();
    } else {
      // Restore full quality after transition
      _restoreFullQuality();
    }
  }

  /// Optimize charts for smooth transitions
  static void _optimizeForTransition() {
    // Implementation would reduce chart animation complexity
    // This is a placeholder for chart-specific optimizations
  }

  /// Restore full chart quality after transitions
  static void _restoreFullQuality() {
    // Implementation would restore full chart animations
    // This is a placeholder for chart-specific optimizations
  }

  /// Get optimized chart widget
  static Widget getOptimizedChart({
    required String chartId,
    required Widget Function() chartBuilder,
    bool enableCaching = true,
  }) {
    // Use cached version during transitions for better performance
    if (_isTransitioning && enableCaching) {
      final cachedChart = _getCachedChart(chartId);
      if (cachedChart != null) {
        return cachedChart;
      }
    }

    // Build new chart
    final chart = chartBuilder();
    
    // Cache the chart if performance is good
    if (enableCaching && _averageFrameTime < 20.0) {
      _cacheChart(chartId, chart);
    }
    
    return chart;
  }

  /// Cache a chart widget
  static void _cacheChart(String chartId, Widget chart) {
    _chartCache[chartId] = chart;
    _cacheTimestamps[chartId] = DateTime.now();
    
    // Clean old cache entries
    _cleanExpiredCache();
  }

  /// Get cached chart if available and not expired
  static Widget? _getCachedChart(String chartId) {
    if (!_chartCache.containsKey(chartId)) return null;
    
    final timestamp = _cacheTimestamps[chartId];
    if (timestamp == null) return null;
    
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      _chartCache.remove(chartId);
      _cacheTimestamps.remove(chartId);
      return null;
    }
    
    return _chartCache[chartId];
  }

  /// Clean expired cache entries
  static void _cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheExpiry) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _chartCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clear all cached charts
  static void clearCache() {
    _chartCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get performance metrics
  static Map<String, dynamic> getPerformanceMetrics() {
    return {
      'averageFrameTime': _averageFrameTime,
      'targetFrameTime': 16.67,
      'isPerformanceGood': _averageFrameTime < 20.0,
      'cachedCharts': _chartCache.length,
      'isTransitioning': _isTransitioning,
    };
  }

  /// Check if performance is good enough for full quality rendering
  static bool get isPerformanceGood => _averageFrameTime < 20.0;

  /// Check if currently transitioning
  static bool get isTransitioning => _isTransitioning;

  /// Dispose of resources
  static void dispose() {
    clearCache();
  }
}

/// Widget wrapper for optimized chart rendering
class OptimizedChartWidget extends StatefulWidget {
  final String chartId;
  final Widget Function() chartBuilder;
  final bool enableCaching;
  final bool reduceQualityDuringTransition;

  const OptimizedChartWidget({
    super.key,
    required this.chartId,
    required this.chartBuilder,
    this.enableCaching = true,
    this.reduceQualityDuringTransition = true,
  });

  @override
  State<OptimizedChartWidget> createState() => _OptimizedChartWidgetState();
}

class _OptimizedChartWidgetState extends State<OptimizedChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Widget? _cachedChart;
  bool _isBuilding = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Use optimized chart rendering
        return ChartOptimizationService.getOptimizedChart(
          chartId: widget.chartId,
          chartBuilder: widget.chartBuilder,
          enableCaching: widget.enableCaching,
        );
      },
    );
  }
}

/// Mixin for widgets that contain charts to optimize during transitions
mixin ChartOptimizationMixin<T extends StatefulWidget> on State<T> {
  bool _isOptimized = false;

  /// Call when starting a transition that might affect chart performance
  void optimizeChartsForTransition() {
    if (!_isOptimized) {
      _isOptimized = true;
      ChartOptimizationService.setTransitionState(true);
    }
  }

  /// Call when transition is complete to restore full chart quality
  void restoreChartQuality() {
    if (_isOptimized) {
      _isOptimized = false;
      ChartOptimizationService.setTransitionState(false);
    }
  }

  @override
  void dispose() {
    if (_isOptimized) {
      ChartOptimizationService.setTransitionState(false);
    }
    super.dispose();
  }
}