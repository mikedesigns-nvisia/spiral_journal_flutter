import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/slide_design_tokens.dart';

/// Service for managing haptic feedback and micro-interactions in slides
class SlideMicroInteractionsService {
  static final SlideMicroInteractionsService _instance = SlideMicroInteractionsService._internal();
  factory SlideMicroInteractionsService() => _instance;
  SlideMicroInteractionsService._internal();

  bool _isInitialized = false;
  bool _hapticsEnabled = true;
  bool _animationsEnabled = true;

  /// Initialize the micro-interactions service
  Future<void> initialize({
    bool enableHaptics = true,
    bool enableAnimations = true,
  }) async {
    if (_isInitialized) return;
    
    _hapticsEnabled = enableHaptics;
    _animationsEnabled = enableAnimations;
    _isInitialized = true;
  }

  /// Trigger haptic feedback for successful slide transitions
  Future<void> triggerSlideTransitionHaptic() async {
    if (!_isInitialized || !_hapticsEnabled) return;
    
    await HapticFeedback.lightImpact();
  }

  /// Trigger haptic feedback for boundary hits (first/last slide)
  Future<void> triggerBoundaryHaptic() async {
    if (!_isInitialized || !_hapticsEnabled) return;
    
    await HapticFeedback.mediumImpact();
  }

  /// Trigger haptic feedback for errors
  Future<void> triggerErrorHaptic() async {
    if (!_isInitialized || !_hapticsEnabled) return;
    
    await HapticFeedback.heavyImpact();
  }

  /// Trigger haptic feedback for successful actions
  Future<void> triggerSuccessHaptic() async {
    if (!_isInitialized || !_hapticsEnabled) return;
    
    await HapticFeedback.lightImpact();
  }

  /// Trigger haptic feedback for button taps
  Future<void> triggerButtonTapHaptic() async {
    if (!_isInitialized || !_hapticsEnabled) return;
    
    await HapticFeedback.selectionClick();
  }

  /// Create bounce animation for boundary hits
  AnimationController createBounceAnimation({
    required TickerProvider vsync,
    Duration? duration,
  }) {
    if (!_animationsEnabled) {
      return AnimationController(
        duration: Duration.zero,
        vsync: vsync,
      );
    }

    return AnimationController(
      duration: duration ?? SlideDesignTokens.transitionDurationBoundary,
      vsync: vsync,
    );
  }

  /// Create loading state animation
  AnimationController createLoadingAnimation({
    required TickerProvider vsync,
    Duration? duration,
  }) {
    if (!_animationsEnabled) {
      return AnimationController(
        duration: Duration.zero,
        vsync: vsync,
      );
    }

    return AnimationController(
      duration: duration ?? SlideDesignTokens.loadingAnimationDuration,
      vsync: vsync,
    );
  }

  /// Create slide indicator animation
  AnimationController createIndicatorAnimation({
    required TickerProvider vsync,
    Duration? duration,
  }) {
    if (!_animationsEnabled) {
      return AnimationController(
        duration: Duration.zero,
        vsync: vsync,
      );
    }

    return AnimationController(
      duration: duration ?? SlideDesignTokens.indicatorAnimationDuration,
      vsync: vsync,
    );
  }

  /// Create smooth bounce animation at slide boundaries
  Animation<double> createBounceAnimationTween(AnimationController controller) {
    if (!_animationsEnabled) {
      return AlwaysStoppedAnimation(0.0);
    }

    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: SlideDesignTokens.transitionCurveBounce,
    ));
  }

  /// Create loading pulse animation
  Animation<double> createLoadingPulseAnimation(AnimationController controller) {
    if (!_animationsEnabled) {
      return AlwaysStoppedAnimation(1.0);
    }

    return Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: SlideDesignTokens.loadingAnimationCurve,
    ));
  }

  /// Create slide indicator scale animation
  Animation<double> createIndicatorScaleAnimation(AnimationController controller) {
    if (!_animationsEnabled) {
      return AlwaysStoppedAnimation(1.0);
    }

    return Tween<double>(
      begin: 1.0,
      end: SlideDesignTokens.indicatorActiveScale,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: SlideDesignTokens.indicatorAnimationCurve,
    ));
  }

  /// Create slide indicator opacity animation
  Animation<double> createIndicatorOpacityAnimation(AnimationController controller) {
    if (!_animationsEnabled) {
      return AlwaysStoppedAnimation(1.0);
    }

    return Tween<double>(
      begin: SlideDesignTokens.indicatorInactiveOpacity,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: SlideDesignTokens.indicatorAnimationCurve,
    ));
  }

  /// Create slide transition animation with custom curve
  Animation<Offset> createSlideTransitionAnimation({
    required AnimationController controller,
    required SlideTransitionDirection direction,
    SlideTransitionType type = SlideTransitionType.next,
  }) {
    if (!_animationsEnabled) {
      return AlwaysStoppedAnimation(Offset.zero);
    }

    final curve = SlideDesignTokens.getTransitionCurve(type);
    
    Offset beginOffset;
    switch (direction) {
      case SlideTransitionDirection.leftToRight:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideTransitionDirection.rightToLeft:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideTransitionDirection.topToBottom:
        beginOffset = const Offset(0.0, -1.0);
        break;
      case SlideTransitionDirection.bottomToTop:
        beginOffset = const Offset(0.0, 1.0);
        break;
    }

    return Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Create fade transition animation
  Animation<double> createFadeTransitionAnimation({
    required AnimationController controller,
    SlideTransitionType type = SlideTransitionType.next,
  }) {
    if (!_animationsEnabled) {
      return AlwaysStoppedAnimation(1.0);
    }

    final curve = SlideDesignTokens.getTransitionCurve(type);

    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Create scale transition animation for micro-interactions
  Animation<double> createScaleTransitionAnimation({
    required AnimationController controller,
    double beginScale = 0.8,
    double endScale = 1.0,
    Curve? curve,
  }) {
    if (!_animationsEnabled) {
      return AlwaysStoppedAnimation(endScale);
    }

    return Tween<double>(
      begin: beginScale,
      end: endScale,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve ?? Curves.elasticOut,
    ));
  }

  /// Create rotation animation for loading states
  Animation<double> createRotationAnimation(AnimationController controller) {
    if (!_animationsEnabled) {
      return AlwaysStoppedAnimation(0.0);
    }

    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(controller);
  }

  /// Create staggered animation for multiple elements
  List<Animation<double>> createStaggeredAnimations({
    required AnimationController controller,
    required int itemCount,
    Duration? staggerDelay,
  }) {
    if (!_animationsEnabled || itemCount == 0) {
      return List.generate(itemCount, (_) => AlwaysStoppedAnimation(1.0));
    }

    final delay = staggerDelay ?? const Duration(milliseconds: 50);
    final delayFraction = delay.inMilliseconds / controller.duration!.inMilliseconds;
    
    return List.generate(itemCount, (index) {
      final start = (index * delayFraction).clamp(0.0, 1.0);
      final end = ((index * delayFraction) + (1.0 - start)).clamp(start, 1.0);
      
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
    });
  }

  /// Animate slide boundary bounce effect
  Future<void> animateBoundaryBounce({
    required AnimationController controller,
    required VoidCallback onComplete,
  }) async {
    if (!_animationsEnabled) {
      onComplete();
      return;
    }

    await triggerBoundaryHaptic();
    
    await controller.forward();
    await controller.reverse();
    
    onComplete();
  }

  /// Animate loading state with pulse effect
  void animateLoadingPulse(AnimationController controller) {
    if (!_animationsEnabled) return;
    
    controller.repeat(reverse: true);
  }

  /// Stop loading animation
  void stopLoadingAnimation(AnimationController controller) {
    controller.stop();
    controller.reset();
  }

  /// Animate slide indicator activation
  Future<void> animateIndicatorActivation({
    required AnimationController controller,
    required VoidCallback onComplete,
  }) async {
    if (!_animationsEnabled) {
      onComplete();
      return;
    }

    await triggerButtonTapHaptic();
    await controller.forward();
    onComplete();
  }

  /// Animate slide indicator deactivation
  Future<void> animateIndicatorDeactivation({
    required AnimationController controller,
    required VoidCallback onComplete,
  }) async {
    if (!_animationsEnabled) {
      onComplete();
      return;
    }

    await controller.reverse();
    onComplete();
  }

  /// Create combined haptic and visual feedback for actions
  Future<void> triggerActionFeedback({
    required SlideActionType actionType,
    AnimationController? animationController,
    VoidCallback? onComplete,
  }) async {
    if (!_isInitialized) return;

    // Trigger appropriate haptic feedback
    switch (actionType) {
      case SlideActionType.navigation:
        await triggerSlideTransitionHaptic();
        break;
      case SlideActionType.boundary:
        await triggerBoundaryHaptic();
        break;
      case SlideActionType.error:
        await triggerErrorHaptic();
        break;
      case SlideActionType.success:
        await triggerSuccessHaptic();
        break;
      case SlideActionType.buttonTap:
        await triggerButtonTapHaptic();
        break;
    }

    // Trigger visual animation if provided
    if (animationController != null && _animationsEnabled) {
      switch (actionType) {
        case SlideActionType.boundary:
          await animateBoundaryBounce(
            controller: animationController,
            onComplete: onComplete ?? () {},
          );
          break;
        case SlideActionType.buttonTap:
          await animateIndicatorActivation(
            controller: animationController,
            onComplete: onComplete ?? () {},
          );
          break;
        default:
          await animationController.forward();
          onComplete?.call();
          break;
      }
    } else {
      onComplete?.call();
    }
  }

  /// Enable or disable haptic feedback
  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  /// Enable or disable animations
  void setAnimationsEnabled(bool enabled) {
    _animationsEnabled = enabled;
  }

  /// Check if haptics are enabled
  bool get hapticsEnabled => _hapticsEnabled;

  /// Check if animations are enabled
  bool get animationsEnabled => _animationsEnabled;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose of resources
  void dispose() {
    _isInitialized = false;
  }
}

/// Enumeration of slide transition directions
enum SlideTransitionDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

/// Enumeration of slide action types for feedback
enum SlideActionType {
  navigation,
  boundary,
  error,
  success,
  buttonTap,
}

/// Widget that provides micro-interaction capabilities
class MicroInteractionWrapper extends StatefulWidget {
  final Widget child;
  final SlideActionType? actionType;
  final VoidCallback? onTap;
  final bool enableHaptics;
  final bool enableAnimations;
  final Duration? animationDuration;
  final Curve? animationCurve;

  const MicroInteractionWrapper({
    super.key,
    required this.child,
    this.actionType,
    this.onTap,
    this.enableHaptics = true,
    this.enableAnimations = true,
    this.animationDuration,
    this.animationCurve,
  });

  @override
  State<MicroInteractionWrapper> createState() => _MicroInteractionWrapperState();
}

class _MicroInteractionWrapperState extends State<MicroInteractionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final SlideMicroInteractionsService _microInteractionsService = SlideMicroInteractionsService();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = _microInteractionsService.createScaleTransitionAnimation(
      controller: _animationController,
      curve: widget.animationCurve,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.actionType != null) {
      await _microInteractionsService.triggerActionFeedback(
        actionType: widget.actionType!,
        animationController: widget.enableAnimations ? _animationController : null,
        onComplete: widget.onTap,
      );
    } else {
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      return widget.child;
    }

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
