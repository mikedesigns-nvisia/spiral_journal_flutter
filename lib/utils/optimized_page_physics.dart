import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Optimized page physics for smooth 60fps slide transitions
class OptimizedPagePhysics extends PageScrollPhysics {
  const OptimizedPagePhysics({super.parent});

  @override
  OptimizedPagePhysics applyTo(ScrollPhysics? ancestor) {
    return OptimizedPagePhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 0.5,        // Reduced mass for snappier response
    stiffness: 200.0, // Increased stiffness for faster settling
    damping: 0.8,     // Optimized damping for smooth motion
  );

  @override
  double get minFlingVelocity => 200.0; // Lower threshold for easier swiping

  @override
  double get maxFlingVelocity => 2500.0; // Reasonable upper limit

  @override
  Tolerance get tolerance => const Tolerance(
    velocity: 1.0,     // Tighter velocity tolerance
    distance: 0.5,     // Tighter distance tolerance
  );

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Use custom simulation for better performance
    if (velocity.abs() < tolerance.velocity) {
      return null;
    }

    if (velocity > 0.0 && position.pixels >= position.maxScrollExtent) {
      return null;
    }

    if (velocity < 0.0 && position.pixels <= position.minScrollExtent) {
      return null;
    }

    // Create optimized spring simulation
    final simulation = SpringSimulation(
      spring,
      position.pixels,
      _getTargetPixels(position, velocity),
      velocity,
      tolerance: tolerance,
    );

    return simulation;
  }

  /// Calculate target pixels for smooth page snapping
  double _getTargetPixels(ScrollMetrics position, double velocity) {
    final page = _getPage(position);
    
    if (velocity < -tolerance.velocity) {
      return _getPixels(position, page.floor());
    }
    
    if (velocity > tolerance.velocity) {
      return _getPixels(position, page.ceil());
    }
    
    return _getPixels(position, page.round());
  }

  /// Get current page as a double
  double _getPage(ScrollMetrics position) {
    return position.pixels / position.viewportDimension;
  }

  /// Get pixels for a specific page
  double _getPixels(ScrollMetrics position, int page) {
    return page * position.viewportDimension;
  }
}

/// High-performance scroll physics for rapid slide switching
class RapidSlidePhysics extends ScrollPhysics {
  const RapidSlidePhysics({super.parent});

  @override
  RapidSlidePhysics applyTo(ScrollPhysics? ancestor) {
    return RapidSlidePhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 100.0; // Very low threshold for rapid switching

  @override
  double get maxFlingVelocity => 5000.0; // High upper limit for fast gestures

  @override
  double get dragStartDistanceMotionThreshold => 3.0; // Reduced drag threshold

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 0.3,        // Very light for instant response
    stiffness: 300.0, // High stiffness for quick settling
    damping: 0.9,     // High damping to prevent overshoot
  );

  @override
  Tolerance get tolerance => const Tolerance(
    velocity: 0.5,    // Very tight velocity tolerance
    distance: 0.25,   // Very tight distance tolerance
  );

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    // Always accept user input for responsive feel
    return true;
  }

  @override
  double carriedMomentum(double existingVelocity) {
    // Reduce carried momentum to prevent over-scrolling
    return existingVelocity * 0.7;
  }
}

/// Bouncing physics for slide boundaries with haptic feedback
class BoundaryBouncePhysics extends BouncingScrollPhysics {
  final VoidCallback? onBoundaryHit;

  const BoundaryBouncePhysics({
    super.parent,
    this.onBoundaryHit,
  });

  @override
  BoundaryBouncePhysics applyTo(ScrollPhysics? ancestor) {
    return BoundaryBouncePhysics(
      parent: buildParent(ancestor),
      onBoundaryHit: onBoundaryHit,
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final result = super.applyBoundaryConditions(position, value);
    
    // Trigger callback when hitting boundaries
    if (result != 0.0) {
      onBoundaryHit?.call();
    }
    
    return result;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final simulation = super.createBallisticSimulation(position, velocity);
    
    // Add boundary detection
    if (simulation != null) {
      return _BoundaryAwareSimulation(
        simulation,
        position,
        onBoundaryHit,
      );
    }
    
    return simulation;
  }
}

/// Simulation wrapper that detects boundary hits
class _BoundaryAwareSimulation extends Simulation {
  final Simulation _simulation;
  final ScrollMetrics _position;
  final VoidCallback? _onBoundaryHit;
  bool _boundaryHitTriggered = false;

  _BoundaryAwareSimulation(
    this._simulation,
    this._position,
    this._onBoundaryHit,
  );

  @override
  double x(double time) {
    final result = _simulation.x(time);
    
    // Check for boundary hits
    if (!_boundaryHitTriggered) {
      if (result <= _position.minScrollExtent || 
          result >= _position.maxScrollExtent) {
        _boundaryHitTriggered = true;
        _onBoundaryHit?.call();
      }
    }
    
    return result;
  }

  @override
  double dx(double time) => _simulation.dx(time);

  @override
  bool isDone(double time) => _simulation.isDone(time);

  @override
  Tolerance get tolerance => _simulation.tolerance;
}