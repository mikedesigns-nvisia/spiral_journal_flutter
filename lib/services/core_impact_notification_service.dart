import 'dart:async';
import 'package:flutter/services.dart';
import '../models/core.dart';
import '../models/journal_entry.dart';

/// Types of core impact notifications
enum CoreImpactNotificationType {
  levelIncrease,
  levelDecrease,
  milestoneAchieved,
  trendChange,
  significantGrowth,
  multiCoreImpact,
}

/// Data model for core impact notifications
class CoreImpactNotification {
  final String id;
  final CoreImpactNotificationType type;
  final String coreId;
  final String coreName;
  final String title;
  final String message;
  final double impactValue;
  final DateTime timestamp;
  final JournalEntry? relatedEntry;
  final Duration displayDuration;
  final bool requiresUserAction;
  final Map<String, dynamic> metadata;

  CoreImpactNotification({
    required this.id,
    required this.type,
    required this.coreId,
    required this.coreName,
    required this.title,
    required this.message,
    required this.impactValue,
    required this.timestamp,
    this.relatedEntry,
    this.displayDuration = const Duration(seconds: 4),
    this.requiresUserAction = false,
    this.metadata = const {},
  });

  factory CoreImpactNotification.levelIncrease({
    required String coreId,
    required String coreName,
    required double impactValue,
    required JournalEntry relatedEntry,
  }) {
    return CoreImpactNotification(
      id: 'level_increase_${coreId}_${DateTime.now().millisecondsSinceEpoch}',
      type: CoreImpactNotificationType.levelIncrease,
      coreId: coreId,
      coreName: coreName,
      title: '$coreName Growing!',
      message: 'Your journal entry boosted your $coreName by ${(impactValue * 100).toStringAsFixed(0)}%',
      impactValue: impactValue,
      timestamp: DateTime.now(),
      relatedEntry: relatedEntry,
    );
  }

  factory CoreImpactNotification.milestoneAchieved({
    required String coreId,
    required String coreName,
    required CoreMilestone milestone,
    required JournalEntry relatedEntry,
  }) {
    return CoreImpactNotification(
      id: 'milestone_${milestone.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: CoreImpactNotificationType.milestoneAchieved,
      coreId: coreId,
      coreName: coreName,
      title: '🎉 Milestone Achieved!',
      message: 'You\'ve reached "${milestone.title}" in your $coreName journey!',
      impactValue: milestone.threshold,
      timestamp: DateTime.now(),
      relatedEntry: relatedEntry,
      displayDuration: const Duration(seconds: 6),
      requiresUserAction: true,
      metadata: {
        'milestoneId': milestone.id,
        'milestoneTitle': milestone.title,
        'milestoneDescription': milestone.description,
      },
    );
  }

  factory CoreImpactNotification.significantGrowth({
    required String coreId,
    required String coreName,
    required double impactValue,
    required JournalEntry relatedEntry,
  }) {
    return CoreImpactNotification(
      id: 'significant_growth_${coreId}_${DateTime.now().millisecondsSinceEpoch}',
      type: CoreImpactNotificationType.significantGrowth,
      coreId: coreId,
      coreName: coreName,
      title: '✨ Remarkable Growth!',
      message: 'Your $coreName has grown significantly (+${(impactValue * 100).toStringAsFixed(0)}%) from your recent journaling!',
      impactValue: impactValue,
      timestamp: DateTime.now(),
      relatedEntry: relatedEntry,
      displayDuration: const Duration(seconds: 5),
    );
  }

  factory CoreImpactNotification.multiCoreImpact({
    required List<String> coreNames,
    required double totalImpact,
    required JournalEntry relatedEntry,
  }) {
    return CoreImpactNotification(
      id: 'multi_core_${DateTime.now().millisecondsSinceEpoch}',
      type: CoreImpactNotificationType.multiCoreImpact,
      coreId: 'multiple',
      coreName: 'Multiple Cores',
      title: '🌟 Multi-Core Growth!',
      message: 'Your journal entry positively impacted ${coreNames.length} cores: ${coreNames.take(2).join(', ')}${coreNames.length > 2 ? ' and more' : ''}',
      impactValue: totalImpact,
      timestamp: DateTime.now(),
      relatedEntry: relatedEntry,
      displayDuration: const Duration(seconds: 5),
      metadata: {
        'affectedCores': coreNames,
      },
    );
  }
}

/// Service for managing core impact notifications
class CoreImpactNotificationService {
  static final CoreImpactNotificationService _instance = CoreImpactNotificationService._internal();
  factory CoreImpactNotificationService() => _instance;
  CoreImpactNotificationService._internal();

  final StreamController<CoreImpactNotification> _notificationController = 
      StreamController<CoreImpactNotification>.broadcast();
  
  final List<CoreImpactNotification> _activeNotifications = [];
  final List<CoreImpactNotification> _notificationHistory = [];
  
  Timer? _cleanupTimer;

  /// Stream of core impact notifications
  Stream<CoreImpactNotification> get notificationStream => _notificationController.stream;

  /// List of currently active notifications
  List<CoreImpactNotification> get activeNotifications => List.unmodifiable(_activeNotifications);

  /// List of notification history
  List<CoreImpactNotification> get notificationHistory => List.unmodifiable(_notificationHistory);

  /// Initialize the service
  void initialize() {
    _startCleanupTimer();
  }

  /// Show a core impact notification
  Future<void> showNotification(CoreImpactNotification notification) async {
    // Add to active notifications
    _activeNotifications.add(notification);
    _notificationHistory.add(notification);
    
    // Trigger haptic feedback based on notification type
    await _triggerHapticFeedback(notification.type);
    
    // Broadcast the notification
    _notificationController.add(notification);
    
    // Auto-remove after display duration (if not requiring user action)
    if (!notification.requiresUserAction) {
      Timer(notification.displayDuration, () {
        dismissNotification(notification.id);
      });
    }
    
    // Limit active notifications to prevent overflow
    if (_activeNotifications.length > 5) {
      _activeNotifications.removeAt(0);
    }
    
    // Limit history to prevent memory issues
    if (_notificationHistory.length > 100) {
      _notificationHistory.removeRange(0, 20);
    }
  }

  /// Process core update events and generate appropriate notifications
  Future<void> processCore

(CoreUpdateEvent event, EmotionalCore core, JournalEntry? relatedEntry) async {
    if (relatedEntry == null) return;

    switch (event.type) {
      case CoreUpdateEventType.levelChanged:
        await _handleLevelChange(event, core, relatedEntry);
        break;
      case CoreUpdateEventType.milestoneAchieved:
        await _handleMilestoneAchieved(event, core, relatedEntry);
        break;
      case CoreUpdateEventType.trendChanged:
        await _handleTrendChange(event, core, relatedEntry);
        break;
      case CoreUpdateEventType.batchUpdate:
        await _handleBatchUpdate(event, relatedEntry);
        break;
      default:
        break;
    }
  }

  /// Process multiple core impacts from a single journal entry
  Future<void> processMultiCoreImpact({
    required List<EmotionalCore> affectedCores,
    required Map<String, double> coreImpacts,
    required JournalEntry relatedEntry,
  }) async {
    final significantImpacts = coreImpacts.entries
        .where((entry) => entry.value.abs() > 0.1)
        .toList();

    if (significantImpacts.isEmpty) return;

    // Show individual notifications for very significant impacts
    for (final impact in significantImpacts) {
      if (impact.value.abs() > 0.3) {
        final core = affectedCores.firstWhere((c) => c.id == impact.key);
        
        if (impact.value > 0.5) {
          await showNotification(CoreImpactNotification.significantGrowth(
            coreId: core.id,
            coreName: core.name,
            impactValue: impact.value,
            relatedEntry: relatedEntry,
          ));
        } else {
          await showNotification(CoreImpactNotification.levelIncrease(
            coreId: core.id,
            coreName: core.name,
            impactValue: impact.value,
            relatedEntry: relatedEntry,
          ));
        }
      }
    }

    // Show multi-core notification if multiple cores were affected
    if (significantImpacts.length > 1) {
      final coreNames = significantImpacts
          .map((impact) => affectedCores.firstWhere((c) => c.id == impact.key).name)
          .toList();
      
      final totalImpact = significantImpacts.fold(0.0, (sum, impact) => sum + impact.value.abs());

      await showNotification(CoreImpactNotification.multiCoreImpact(
        coreNames: coreNames,
        totalImpact: totalImpact,
        relatedEntry: relatedEntry,
      ));
    }
  }

  /// Dismiss a notification by ID
  void dismissNotification(String notificationId) {
    _activeNotifications.removeWhere((notification) => notification.id == notificationId);
  }

  /// Dismiss all active notifications
  void dismissAllNotifications() {
    _activeNotifications.clear();
  }

  /// Get notifications for a specific core
  List<CoreImpactNotification> getNotificationsForCore(String coreId) {
    return _notificationHistory
        .where((notification) => notification.coreId == coreId)
        .toList();
  }

  /// Get recent notifications (last 24 hours)
  List<CoreImpactNotification> getRecentNotifications() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _notificationHistory
        .where((notification) => notification.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Clear notification history
  void clearHistory() {
    _notificationHistory.clear();
  }

  // Private helper methods

  Future<void> _handleLevelChange(CoreUpdateEvent event, EmotionalCore core, JournalEntry relatedEntry) async {
    final previousLevel = event.data['previousLevel'] as double? ?? 0.0;
    final newLevel = event.data['newLevel'] as double? ?? 0.0;
    final change = newLevel - previousLevel;

    if (change.abs() > 0.05) { // Only notify for meaningful changes
      if (change > 0) {
        await showNotification(CoreImpactNotification.levelIncrease(
          coreId: core.id,
          coreName: core.name,
          impactValue: change,
          relatedEntry: relatedEntry,
        ));
      }
    }
  }

  Future<void> _handleMilestoneAchieved(CoreUpdateEvent event, EmotionalCore core, JournalEntry relatedEntry) async {
    final milestoneId = event.data['milestoneId'] as String?;
    if (milestoneId == null) return;

    final milestone = core.milestones.firstWhere(
      (m) => m.id == milestoneId,
      orElse: () => CoreMilestone(
        id: milestoneId,
        title: 'Achievement Unlocked',
        description: 'You\'ve reached a new milestone!',
        threshold: 0.0,
        isAchieved: true,
      ),
    );

    await showNotification(CoreImpactNotification.milestoneAchieved(
      coreId: core.id,
      coreName: core.name,
      milestone: milestone,
      relatedEntry: relatedEntry,
    ));
  }

  Future<void> _handleTrendChange(CoreUpdateEvent event, EmotionalCore core, JournalEntry relatedEntry) async {
    final newTrend = event.data['newTrend'] as String?;
    final previousTrend = event.data['previousTrend'] as String?;

    if (newTrend == 'rising' && previousTrend != 'rising') {
      await showNotification(CoreImpactNotification(
        id: 'trend_change_${core.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: CoreImpactNotificationType.trendChange,
        coreId: core.id,
        coreName: core.name,
        title: '📈 Positive Trend!',
        message: 'Your ${core.name} is now on a rising trend!',
        impactValue: 0.0,
        timestamp: DateTime.now(),
        relatedEntry: relatedEntry,
      ));
    }
  }

  Future<void> _handleBatchUpdate(CoreUpdateEvent event, JournalEntry relatedEntry) async {
    final updatedCoreIds = event.data['updatedCoreIds'] as List<dynamic>? ?? [];
    final updateCount = event.data['updateCount'] as int? ?? 0;

    if (updateCount > 2) {
      await showNotification(CoreImpactNotification(
        id: 'batch_update_${DateTime.now().millisecondsSinceEpoch}',
        type: CoreImpactNotificationType.multiCoreImpact,
        coreId: 'multiple',
        coreName: 'Multiple Cores',
        title: '🌟 Comprehensive Growth!',
        message: 'Your journal entry influenced $updateCount different areas of growth!',
        impactValue: 0.0,
        timestamp: DateTime.now(),
        relatedEntry: relatedEntry,
        displayDuration: const Duration(seconds: 5),
      ));
    }
  }

  Future<void> _triggerHapticFeedback(CoreImpactNotificationType type) async {
    switch (type) {
      case CoreImpactNotificationType.milestoneAchieved:
        await HapticFeedback.heavyImpact();
        // Double tap for celebration
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
        break;
      case CoreImpactNotificationType.significantGrowth:
        await HapticFeedback.mediumImpact();
        break;
      case CoreImpactNotificationType.levelIncrease:
        await HapticFeedback.lightImpact();
        break;
      case CoreImpactNotificationType.multiCoreImpact:
        await HapticFeedback.mediumImpact();
        break;
      default:
        await HapticFeedback.selectionClick();
        break;
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredNotifications();
    });
  }

  void _cleanupExpiredNotifications() {
    final now = DateTime.now();
    _activeNotifications.removeWhere((notification) {
      final isExpired = now.difference(notification.timestamp) > notification.displayDuration;
      return isExpired && !notification.requiresUserAction;
    });
  }

  /// Dispose of the service
  void dispose() {
    _notificationController.close();
    _cleanupTimer?.cancel();
  }
}