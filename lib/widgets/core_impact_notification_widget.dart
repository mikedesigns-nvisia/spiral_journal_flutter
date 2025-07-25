import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/core_impact_notification_service.dart';
import '../services/accessibility_service.dart';
import '../design_system/design_tokens.dart';
import '../models/core.dart';

/// Widget that displays core impact notifications with animations
class CoreImpactNotificationWidget extends StatefulWidget {
  final CoreImpactNotification notification;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;
  final bool showAnimation;

  const CoreImpactNotificationWidget({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onTap,
    this.showAnimation = true,
  });

  @override
  State<CoreImpactNotificationWidget> createState() => _CoreImpactNotificationWidgetState();
}

class _CoreImpactNotificationWidgetState extends State<CoreImpactNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _celebrationController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _celebrationAnimation;
  
  late AccessibilityService _accessibilityService;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _accessibilityService = AccessibilityService();
    _focusNode = _accessibilityService.createAccessibleFocusNode(
      debugLabel: 'Core impact notification',
    );
    _initializeAnimations();
    if (widget.showAnimation) {
      _startAnimations();
    }
  }

  void _initializeAnimations() {
    // Respect accessibility settings for animation durations
    _slideController = AnimationController(
      duration: _accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 600),
      ),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: _accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 1000),
      ),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: _accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 2000),
      ),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: _accessibilityService.getAnimationCurve(Curves.elasticOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: _accessibilityService.getAnimationCurve(Curves.elasticOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: _accessibilityService.reducedMotionMode ? 1.02 : 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: _accessibilityService.getAnimationCurve(Curves.easeInOut),
    ));

    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: _accessibilityService.getAnimationCurve(Curves.easeOutBack),
    ));
  }

  void _startAnimations() {
    _slideController.forward();
    
    // Start pulse animation for certain notification types (respecting accessibility)
    if (_shouldPulse() && !_accessibilityService.reducedMotionMode) {
      _pulseController.repeat(reverse: true);
    }
    
    // Start celebration animation for milestones (respecting accessibility)
    if (widget.notification.type == CoreImpactNotificationType.milestoneAchieved &&
        !_accessibilityService.reducedMotionMode) {
      _celebrationController.forward();
    }
    
    // Announce notification to screen reader
    final semanticLabel = _accessibilityService.getCoreNotificationSemanticLabel(
      widget.notification.title,
      widget.notification.message,
      widget.notification.type.toString(),
      widget.notification.impactValue,
    );
    _accessibilityService.announceToScreenReader(
      semanticLabel,
      assertiveness: widget.notification.type == CoreImpactNotificationType.milestoneAchieved
          ? Assertiveness.assertive
          : Assertiveness.polite,
    );
  }

  bool _shouldPulse() {
    return widget.notification.type == CoreImpactNotificationType.significantGrowth ||
           widget.notification.type == CoreImpactNotificationType.milestoneAchieved;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _celebrationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Handle keyboard navigation
  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (widget.onTap != null) {
          // Provide haptic feedback (respecting accessibility settings)
          if (!_accessibilityService.reducedMotionMode) {
            HapticFeedback.lightImpact();
          }
          widget.onTap!();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (widget.onDismiss != null) {
          widget.onDismiss!();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Create comprehensive semantic label
    final semanticLabel = _accessibilityService.getCoreNotificationSemanticLabel(
      widget.notification.title,
      widget.notification.message,
      widget.notification.type.toString(),
      widget.notification.impactValue,
    );

    return Semantics(
      liveRegion: true,
      button: widget.onTap != null,
      focusable: true,
      focused: _focusNode.hasFocus,
      label: semanticLabel,
      onTap: widget.onTap,
      onDismiss: widget.onDismiss,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) => _handleKeyEvent(event),
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final scale = _accessibilityService.reducedMotionMode 
                    ? 1.0 
                    : _pulseAnimation.value;
                return Transform.scale(
                  scale: scale,
                  child: _buildNotificationCard(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          // Provide haptic feedback (respecting accessibility settings)
          if (!_accessibilityService.reducedMotionMode) {
            HapticFeedback.lightImpact();
          }
          widget.onTap!();
        }
      },
      child: Container(
        constraints: BoxConstraints(
          minHeight: _accessibilityService.getMinimumTouchTargetSize(),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing3,
          vertical: _accessibilityService.getAccessibleSpacing(),
        ),
        padding: EdgeInsets.all(
          _accessibilityService.getAccessibleSpacing(),
        ),
        decoration: BoxDecoration(
          color: _accessibilityService.highContrastMode 
              ? (_accessibilityService.getAccessibleColors(context).surface)
              : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.borderRadius3),
          border: Border.all(
            color: _getNotificationColor().withOpacity(
              _accessibilityService.highContrastMode ? 0.8 : 0.3,
            ),
            width: _accessibilityService.highContrastMode ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getNotificationColor().withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            _buildMainContent(),
            
            // Celebration overlay for milestones
            if (widget.notification.type == CoreImpactNotificationType.milestoneAchieved)
              _buildCelebrationOverlay(),
            
            // Dismiss button
            if (widget.onDismiss != null)
              _buildDismissButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Row(
      children: [
        // Icon
        _buildNotificationIcon(),
        
        const SizedBox(width: DesignTokens.spacing3),
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                widget.notification.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _getNotificationColor(),
                ),
              ),
              
              const SizedBox(height: DesignTokens.spacing1),
              
              // Message
              Text(
                widget.notification.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.textSecondaryColor,
                ),
              ),
              
              // Additional info for milestones
              if (widget.notification.type == CoreImpactNotificationType.milestoneAchieved)
                _buildMilestoneInfo(),
              
              // Impact indicator
              if (widget.notification.impactValue.abs() > 0.05)
                _buildImpactIndicator(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getNotificationColor().withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: _getNotificationColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        _getNotificationIcon(),
        color: _getNotificationColor(),
        size: 24,
      ),
    );
  }

  Widget _buildMilestoneInfo() {
    final milestoneDescription = widget.notification.metadata['milestoneDescription'] as String?;
    
    if (milestoneDescription == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.spacing2),
      padding: const EdgeInsets.all(DesignTokens.spacing2),
      decoration: BoxDecoration(
        color: DesignTokens.successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
        border: Border.all(
          color: DesignTokens.successColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        milestoneDescription,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DesignTokens.successColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildImpactIndicator() {
    final impact = widget.notification.impactValue;
    final isPositive = impact > 0;
    
    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.spacing2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: isPositive ? DesignTokens.successColor : DesignTokens.warningColor,
          ),
          
          const SizedBox(width: DesignTokens.spacing1),
          
          Text(
            '${isPositive ? '+' : ''}${(impact * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isPositive ? DesignTokens.successColor : DesignTokens.warningColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: CelebrationPainter(
              progress: _celebrationAnimation.value,
              color: DesignTokens.successColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDismissButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: DesignTokens.textSecondaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close,
            size: 16,
            color: DesignTokens.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor() {
    switch (widget.notification.type) {
      case CoreImpactNotificationType.milestoneAchieved:
        return DesignTokens.successColor;
      case CoreImpactNotificationType.significantGrowth:
        return DesignTokens.primaryColor;
      case CoreImpactNotificationType.levelIncrease:
        return DesignTokens.successColor;
      case CoreImpactNotificationType.levelDecrease:
        return DesignTokens.warningColor;
      case CoreImpactNotificationType.trendChange:
        return DesignTokens.primaryColor;
      case CoreImpactNotificationType.multiCoreImpact:
        return Colors.purple;
    }
  }

  IconData _getNotificationIcon() {
    switch (widget.notification.type) {
      case CoreImpactNotificationType.milestoneAchieved:
        return Icons.emoji_events;
      case CoreImpactNotificationType.significantGrowth:
        return Icons.trending_up;
      case CoreImpactNotificationType.levelIncrease:
        return Icons.arrow_upward;
      case CoreImpactNotificationType.levelDecrease:
        return Icons.arrow_downward;
      case CoreImpactNotificationType.trendChange:
        return Icons.show_chart;
      case CoreImpactNotificationType.multiCoreImpact:
        return Icons.scatter_plot;
    }
  }
}

/// Overlay widget that manages multiple notifications
class CoreImpactNotificationOverlay extends StatefulWidget {
  final Stream<CoreImpactNotification> notificationStream;
  final Function(String coreId)? onNotificationTap;
  final int maxVisibleNotifications;

  const CoreImpactNotificationOverlay({
    super.key,
    required this.notificationStream,
    this.onNotificationTap,
    this.maxVisibleNotifications = 3,
  });

  @override
  State<CoreImpactNotificationOverlay> createState() => _CoreImpactNotificationOverlayState();
}

class _CoreImpactNotificationOverlayState extends State<CoreImpactNotificationOverlay> {
  final List<CoreImpactNotification> _visibleNotifications = [];
  late StreamSubscription _streamSubscription;

  @override
  void initState() {
    super.initState();
    _streamSubscription = widget.notificationStream.listen(_handleNewNotification);
  }

  void _handleNewNotification(CoreImpactNotification notification) {
    setState(() {
      _visibleNotifications.add(notification);
      
      // Limit visible notifications
      if (_visibleNotifications.length > widget.maxVisibleNotifications) {
        _visibleNotifications.removeAt(0);
      }
    });

    // Auto-dismiss after duration (if not requiring user action)
    if (!notification.requiresUserAction) {
      Timer(notification.displayDuration, () {
        _dismissNotification(notification.id);
      });
    }
  }

  void _dismissNotification(String notificationId) {
    setState(() {
      _visibleNotifications.removeWhere((n) => n.id == notificationId);
    });
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_visibleNotifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 0,
      right: 0,
      child: Column(
        children: _visibleNotifications.map((notification) {
          return CoreImpactNotificationWidget(
            key: ValueKey(notification.id),
            notification: notification,
            onDismiss: () => _dismissNotification(notification.id),
            onTap: () {
              widget.onNotificationTap?.call(notification.coreId);
              if (!notification.requiresUserAction) {
                _dismissNotification(notification.id);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Custom painter for celebration effects
class CelebrationPainter extends CustomPainter {
  final double progress;
  final Color color;

  CelebrationPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color.withOpacity(0.3 * (1 - progress))
      ..style = PaintingStyle.fill;

    // Draw celebration particles
    final random = math.Random(42); // Fixed seed for consistent animation
    
    for (int i = 0; i < 20; i++) {
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      final radius = (2 + random.nextDouble() * 4) * progress;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw celebration rays
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = color.withOpacity(0.5 * (1 - progress));

    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2 / 8) + (progress * math.pi * 2);
      final startRadius = 20 * progress;
      final endRadius = 40 * progress;
      
      final start = center + Offset(
        math.cos(angle) * startRadius,
        math.sin(angle) * startRadius,
      );
      
      final end = center + Offset(
        math.cos(angle) * endRadius,
        math.sin(angle) * endRadius,
      );
      
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(CelebrationPainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}

import 'dart:async';
import 'dart:math' as math;