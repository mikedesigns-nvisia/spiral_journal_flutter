import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class GyroscopeLightingService extends ChangeNotifier {
  // Remove singleton pattern to avoid disposal conflicts
  GyroscopeLightingService();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // Light source position (normalized -1 to 1)
  double _lightX = 0.0;
  double _lightY = -0.3; // Default light from top
  
  // Smooth interpolation values
  double _targetLightX = 0.0;
  double _targetLightY = -0.3;
  
  // Sensitivity settings - Made much more subtle
  static const double _sensitivity = 0.15; // Reduced from 0.5 to 0.15 for much more subtle reactions
  static const double _dampening = 0.03; // Reduced from 0.1 to 0.03 for slower, smoother movement
  static const double _maxTilt = 30.0; // Reduced from 45.0 to 30.0 for less dramatic range
  
  // Current device orientation
  double _deviceTiltX = 0.0;
  double _deviceTiltY = 0.0;
  
  bool _isEnabled = true;
  bool _isDisposed = false;
  Timer? _interpolationTimer;

  // Getters
  double get lightX => _lightX;
  double get lightY => _lightY;
  Alignment get lightPosition => Alignment(_lightX, _lightY);
  bool get isEnabled => _isEnabled;

  void initialize() {
    if (!_isEnabled || _isDisposed) return;
    
    // Listen to accelerometer for device tilt
    _accelerometerSubscription = accelerometerEventStream().listen(
      _handleAccelerometerEvent,
      onError: (error) {
        debugPrint('GyroscopeLightingService: Accelerometer error: $error');
      },
    );
    
    // Start smooth interpolation timer
    _interpolationTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60fps
      (_) {
        if (!_isDisposed && _isEnabled) {
          _updateLightPosition();
        }
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _interpolationTimer?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _interpolationTimer = null;
    super.dispose();
  }


  void setEnabled(bool enabled) {
    if (_isDisposed || _isEnabled == enabled) return;
    
    _isEnabled = enabled;
    
    if (enabled) {
      initialize();
    } else {
      _accelerometerSubscription?.cancel();
      _gyroscopeSubscription?.cancel();
      _interpolationTimer?.cancel();
      
      // Reset to default position
      _targetLightX = 0.0;
      _targetLightY = -0.3;
    }
    
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    if (!_isEnabled || _isDisposed) return;

    try {
      // Calculate device tilt from accelerometer data
      // event.x: left/right tilt, event.y: forward/backward tilt
      // Convert to degrees and normalize
      
      final double tiltX = math.atan2(event.x, event.z) * (180 / math.pi);
      final double tiltY = math.atan2(event.y, event.z) * (180 / math.pi);
      
      // Apply sensitivity and clamp to max tilt
      _deviceTiltX = (tiltX * _sensitivity).clamp(-_maxTilt, _maxTilt);
      _deviceTiltY = (tiltY * _sensitivity).clamp(-_maxTilt, _maxTilt);
      
      // Calculate target light position based on device tilt
      // Invert the light direction (tilt left = light from right)
      _targetLightX = -(_deviceTiltX / _maxTilt).clamp(-1.0, 1.0);
      _targetLightY = -0.3 + (_deviceTiltY / _maxTilt * 0.7).clamp(-0.7, 0.7);
    } catch (e) {
      // Silently handle any errors to prevent crashes
      debugPrint('GyroscopeLightingService: Error handling accelerometer event: $e');
    }
  }

  void _updateLightPosition() {
    if (!_isEnabled || _isDisposed) return;

    try {
      // Smooth interpolation towards target position
      final double deltaX = _targetLightX - _lightX;
      final double deltaY = _targetLightY - _lightY;
      
      _lightX += deltaX * _dampening;
      _lightY += deltaY * _dampening;
      
      // Only notify if change is significant enough and not disposed
      if ((deltaX.abs() > 0.001 || deltaY.abs() > 0.001) && !_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      // Silently handle any errors to prevent crashes
      debugPrint('GyroscopeLightingService: Error updating light position: $e');
    }
  }

  // Get highlight position for a specific orb based on current light direction
  Alignment getHighlightPosition({double offsetX = 0.0, double offsetY = 0.0}) {
    if (!_isEnabled || _isDisposed) {
      return const Alignment(0.1, -0.3); // Default highlight position
    }
    
    return Alignment(
      (_lightX + offsetX).clamp(-1.0, 1.0),
      (_lightY + offsetY).clamp(-1.0, 1.0),
    );
  }

  // Get shadow offset based on light direction
  Offset getShadowOffset({double intensity = 1.0}) {
    if (!_isEnabled || _isDisposed) {
      return const Offset(0, 4); // Default shadow
    }
    
    // Shadow is opposite to light direction - Made more subtle
    return Offset(
      -_lightX * 1.5 * intensity, // Reduced from 3 to 1.5 for subtler shadow movement
      -_lightY * 1.5 * intensity + 4, // Reduced from 3 to 1.5, keep some downward shadow
    );
  }

  // Get light intensity based on tilt angle
  double getLightIntensity() {
    if (!_isEnabled || _isDisposed) return 1.0;
    
    // More tilt = more subtle lighting changes
    final double tiltMagnitude = math.sqrt(
      _deviceTiltX * _deviceTiltX + _deviceTiltY * _deviceTiltY
    );
    
    return (1.0 + (tiltMagnitude / _maxTilt) * 0.15).clamp(0.85, 1.15); // Much subtler range: 0.15 instead of 0.5, range 0.85-1.15 instead of 0.5-1.5
  }

  // Reset to neutral position
  void reset() {
    _targetLightX = 0.0;
    _targetLightY = -0.3;
    _deviceTiltX = 0.0;
    _deviceTiltY = 0.0;
  }

  // Get rim light color intensity based on angle
  double getRimLightIntensity(double angle) {
    if (!_isEnabled || _isDisposed) return 0.15;
    
    // Calculate how much the rim should be lit based on light angle - Made more subtle
    final double lightAngle = math.atan2(_lightY, _lightX);
    final double angleDiff = (angle - lightAngle).abs();
    
    // Rim is brightest when perpendicular to light direction - Much subtler effect
    return (0.1 + math.sin(angleDiff) * 0.1).clamp(0.05, 0.2); // Reduced from 0.3 to 0.1, max from 0.4 to 0.2
  }
}