import 'package:flutter/material.dart';

class AnimationConstants {
  static const Duration fastDuration = Duration(milliseconds: 150);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration extraSlowDuration = Duration(milliseconds: 800);
  
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve sharpCurve = Curves.easeInOutQuart;
  
  static const double buttonScalePressed = 0.95;
  static const double buttonScaleNormal = 1.0;
  static const double cardElevationNormal = 2.0;
  static const double cardElevationPressed = 8.0;
  static const double cardElevationHovered = 4.0;
  
  static const double shimmerBaseOpacity = 0.3;
  static const double shimmerHighlightOpacity = 0.6;
  
  static const int particleCount = 30;
  static const double particleMaxSize = 8.0;
  static const double particleMinSize = 2.0;
}

class AnimationUtils {
  static Animation<double> createScaleAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = AnimationConstants.defaultCurve,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }
  
  static Animation<double> createFadeAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = AnimationConstants.defaultCurve,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }
  
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
    Curve curve = AnimationConstants.defaultCurve,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }
  
  static Animation<Color?> createColorAnimation(
    AnimationController controller, {
    required Color begin,
    required Color end,
    Curve curve = AnimationConstants.defaultCurve,
  }) {
    return ColorTween(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }
}