import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../ai_service_interface.dart';
import '../ai_service_error_tracker.dart';
import 'network_health_monitor.dart';
import 'network_error_handler.dart';

/// Provider recovery service for automatic fallback and recovery of AI services
/// 
/// Handles automatic switching between Claude AI and fallback providers based on
/// network conditions, error patterns, and service health monitoring
class ProviderRecoveryService {
  static final ProviderRecoveryService _instance = ProviderRecoveryService._internal();
  factory ProviderRecoveryService() => _instance;
  ProviderRecoveryService._internal();
  
  // Dependencies
  final NetworkHealthMonitor _healthMonitor = NetworkHealthMonitor();
  
  // State management
  AIServiceInterface? _primaryProvider;
  AIServiceInterface? _fallbackProvider;
  AIServiceInterface? _currentProvider;
  ProviderState _currentState = ProviderState.unknown;
  
  // Recovery tracking
  int _consecutiveFailures = 0;
  DateTime? _lastFailureTime;
  DateTime? _lastRecoveryAttempt;
  Timer? _recoveryTimer;
  
  // Configuration
  static const int _maxConsecutiveFailures = 3;
  static const Duration _recoveryCheckInterval = Duration(minutes: 2);
  static const Duration _failureResetDuration = Duration(minutes: 10);
  
  // Stream controllers
  final StreamController<ProviderRecoveryEvent> _eventController = 
      StreamController<ProviderRecoveryEvent>.broadcast();
  
  // Getters
  Stream<ProviderRecoveryEvent> get eventStream => _eventController.stream;
  AIServiceInterface? get currentProvider => _currentProvider;
  ProviderState get currentState => _currentState;
  int get consecutiveFailures => _consecutiveFailures;
  DateTime? get lastFailureTime => _lastFailureTime;
  bool get isUsingFallback => _currentState == ProviderState.usingFallback;
  bool get isRecovering => _currentState == ProviderState.recovering;
  
  /// Initialize recovery service with providers
  Future<void> initialize({
    required AIServiceInterface primaryProvider,
    required AIServiceInterface fallbackProvider,
  }) async {
    try {
      debugPrint('🔄 ProviderRecoveryService: Initializing...');
      
      _primaryProvider = primaryProvider;
      _fallbackProvider = fallbackProvider;
      _currentProvider = primaryProvider;
      
      // Initialize network health monitoring
      await _healthMonitor.initialize();
      
      // Listen to network health changes
      _healthMonitor.healthStatusStream.listen(_onNetworkHealthChanged);
      
      // Start with primary provider if healthy
      if (_healthMonitor.isApiHealthy) {
        _updateState(ProviderState.usingPrimary);
      } else {
        _switchToFallback(reason: 'Network unhealthy during initialization');
      }
      
      // Start recovery monitoring
      _startRecoveryMonitoring();
      
      debugPrint('✅ ProviderRecoveryService: Initialized successfully');
      debugPrint('   Primary provider: ${_primaryProvider.runtimeType}');
      debugPrint('   Fallback provider: ${_fallbackProvider.runtimeType}');
      debugPrint('   Current state: $_currentState');
      
    } catch (e) {
      debugPrint('❌ ProviderRecoveryService initialization failed: $e');
      _updateState(ProviderState.error);
      rethrow;
    }
  }
  
  /// Handle provider operation failure
  Future<AIServiceInterface> handleProviderFailure(
    Exception error, {
    required String operation,
    Map<String, dynamic>? context,
  }) async {
    debugPrint('🚨 ProviderRecoveryService: Handling provider failure');
    debugPrint('   Operation: $operation');
    debugPrint('   Error: $error');
    
    _consecutiveFailures++;
    _lastFailureTime = DateTime.now();
    
    // Log the failure
    AIServiceErrorTracker.logError(
      'provider_failure',
      error,
      context: {
        'operation': operation,
        'consecutiveFailures': _consecutiveFailures,
        'currentProvider': _currentProvider?.runtimeType.toString(),
        'currentState': _currentState.name,
        ...?context,
      },
      provider: 'ProviderRecoveryService',
    );
    
    // Determine if we should switch to fallback
    if (_shouldSwitchToFallback(error)) {
      await _switchToFallback(
        reason: 'Provider failure in $operation: ${error.toString()}',
      );
    }
    
    return _currentProvider!;
  }
  
  /// Check if error warrants switching to fallback
  bool _shouldSwitchToFallback(Exception error) {
    // Always switch on network errors if not already using fallback
    if (error is NetworkException && _currentState != ProviderState.usingFallback) {
      debugPrint('🔄 Switching to fallback due to network error: ${error.type.name}');
      return true;
    }
    
    // Switch after consecutive failures
    if (_consecutiveFailures >= _maxConsecutiveFailures && _currentState != ProviderState.usingFallback) {
      debugPrint('🔄 Switching to fallback due to consecutive failures: $_consecutiveFailures');
      return true;
    }
    
    // Switch if primary provider is not available
    if (_currentState == ProviderState.usingPrimary && !_healthMonitor.isApiHealthy) {
      debugPrint('🔄 Switching to fallback due to API health check failure');
      return true;
    }
    
    return false;
  }
  
  /// Switch to fallback provider
  Future<void> _switchToFallback({required String reason}) async {
    if (_currentState == ProviderState.usingFallback) {
      debugPrint('⚠️  Already using fallback provider');
      return;
    }
    
    debugPrint('🔄 ProviderRecoveryService: Switching to fallback provider');
    debugPrint('   Reason: $reason');
    
    _currentProvider = _fallbackProvider;
    _updateState(ProviderState.usingFallback);
    
    // Emit event
    _emitEvent(ProviderRecoveryEvent(
      type: RecoveryEventType.switchedToFallback,
      timestamp: DateTime.now(),
      reason: reason,
      consecutiveFailures: _consecutiveFailures,
    ));
    
    // Schedule recovery attempt
    _scheduleRecoveryAttempt();
  }
  
  /// Attempt to recover to primary provider
  Future<void> attemptRecovery() async {
    if (_currentState != ProviderState.usingFallback) {
      debugPrint('⚠️  Not using fallback, recovery not needed');
      return;
    }
    
    debugPrint('🔄 ProviderRecoveryService: Attempting recovery to primary provider...');
    _updateState(ProviderState.recovering);
    _lastRecoveryAttempt = DateTime.now();
    
    try {
      // Check network health first
      await _healthMonitor.forceHealthCheck();
      
      if (!_healthMonitor.isApiHealthy) {
        debugPrint('❌ Recovery failed: Network still unhealthy');
        _updateState(ProviderState.usingFallback);
        return;
      }
      
      // Test primary provider connection
      if (_primaryProvider != null) {
        await _primaryProvider!.testConnection();
        
        // Recovery successful
        debugPrint('✅ Recovery successful: Primary provider is healthy');
        _currentProvider = _primaryProvider;
        _consecutiveFailures = 0;
        _lastFailureTime = null;
        _updateState(ProviderState.usingPrimary);
        
        // Emit success event
        _emitEvent(ProviderRecoveryEvent(
          type: RecoveryEventType.recoveredToPrimary,
          timestamp: DateTime.now(),
          reason: 'Primary provider health restored',
          consecutiveFailures: 0,
        ));
      }
      
    } catch (e) {
      debugPrint('❌ Recovery attempt failed: $e');
      _updateState(ProviderState.usingFallback);
      
      // Emit failure event
      _emitEvent(ProviderRecoveryEvent(
        type: RecoveryEventType.recoveryFailed,
        timestamp: DateTime.now(),
        reason: 'Recovery test failed: ${e.toString()}',
        consecutiveFailures: _consecutiveFailures,
      ));
      
      // Log the failed recovery attempt
      AIServiceErrorTracker.logError(
        'recovery_attempt_failed',
        e,
        context: {
          'consecutiveFailures': _consecutiveFailures,
          'networkHealthy': _healthMonitor.isApiHealthy,
          'lastFailureTime': _lastFailureTime?.toIso8601String(),
        },
        provider: 'ProviderRecoveryService',
      );
    }
  }
  
  /// Handle network health changes
  void _onNetworkHealthChanged(NetworkHealthStatus status) {
    debugPrint('📊 ProviderRecoveryService: Network health changed to $status');
    
    switch (status) {
      case NetworkHealthStatus.healthyWifi:
      case NetworkHealthStatus.healthyCellular:
        // Network is healthy, attempt recovery if using fallback
        if (_currentState == ProviderState.usingFallback) {
          _scheduleRecoveryAttempt(immediate: true);
        }
        break;
        
      case NetworkHealthStatus.offline:
      case NetworkHealthStatus.noInternet:
      case NetworkHealthStatus.apiUnreachable:
        // Network issues, switch to fallback if not already
        if (_currentState == ProviderState.usingPrimary) {
          _switchToFallback(reason: 'Network health degraded: $status');
        }
        break;
        
      case NetworkHealthStatus.unknown:
      case NetworkHealthStatus.error:
        // Unknown state, be cautious
        break;
    }
  }
  
  /// Schedule recovery attempt
  void _scheduleRecoveryAttempt({bool immediate = false}) {
    // Cancel existing recovery timer
    _recoveryTimer?.cancel();
    
    final delay = immediate ? Duration.zero : _calculateRecoveryDelay();
    
    debugPrint('⏰ Scheduling recovery attempt in ${delay.inSeconds}s');
    
    _recoveryTimer = Timer(delay, () {
      attemptRecovery();
    });
  }
  
  /// Calculate recovery delay with exponential backoff
  Duration _calculateRecoveryDelay() {
    final baseDelay = _recoveryCheckInterval.inSeconds;
    final exponentialFactor = min(pow(2, _consecutiveFailures - 1), 8).toInt();
    final delaySeconds = baseDelay * exponentialFactor;
    
    // Add jitter to prevent thundering herd
    final jitter = Random().nextInt(30); // 0-30 seconds
    
    return Duration(seconds: delaySeconds + jitter);
  }
  
  /// Start recovery monitoring
  void _startRecoveryMonitoring() {
    // Reset consecutive failures after some time without issues
    Timer.periodic(Duration(minutes: 5), (_) {
      if (_lastFailureTime != null) {
        final timeSinceFailure = DateTime.now().difference(_lastFailureTime!);
        if (timeSinceFailure > _failureResetDuration) {
          debugPrint('🔄 Resetting consecutive failures count (no issues for ${timeSinceFailure.inMinutes}m)');
          _consecutiveFailures = 0;
          _lastFailureTime = null;
        }
      }
    });
  }
  
  /// Update current state
  void _updateState(ProviderState newState) {
    if (_currentState != newState) {
      final oldState = _currentState;
      _currentState = newState;
      
      debugPrint('📊 ProviderRecoveryService: State changed from $oldState to $newState');
      
      _emitEvent(ProviderRecoveryEvent(
        type: RecoveryEventType.stateChanged,
        timestamp: DateTime.now(),
        reason: 'State transition from $oldState to $newState',
        consecutiveFailures: _consecutiveFailures,
      ));
    }
  }
  
  /// Emit recovery event
  void _emitEvent(ProviderRecoveryEvent event) {
    _eventController.add(event);
    
    // Log significant events
    if (event.type != RecoveryEventType.stateChanged) {
      debugPrint('📢 ProviderRecoveryService Event: ${event.type.name} - ${event.reason}');
    }
  }
  
  /// Get recovery statistics
  ProviderRecoveryStats getStats() {
    return ProviderRecoveryStats(
      currentState: _currentState,
      consecutiveFailures: _consecutiveFailures,
      lastFailureTime: _lastFailureTime,
      lastRecoveryAttempt: _lastRecoveryAttempt,
      isRecoveryScheduled: _recoveryTimer?.isActive ?? false,
      networkHealthy: _healthMonitor.isApiHealthy,
      primaryProviderType: _primaryProvider?.runtimeType.toString(),
      fallbackProviderType: _fallbackProvider?.runtimeType.toString(),
      currentProviderType: _currentProvider?.runtimeType.toString(),
    );
  }
  
  /// Force immediate recovery attempt
  Future<void> forceRecovery() async {
    debugPrint('🔄 ProviderRecoveryService: Forcing immediate recovery attempt...');
    await attemptRecovery();
  }
  
  /// Reset recovery state
  void resetRecoveryState() {
    debugPrint('🔄 ProviderRecoveryService: Resetting recovery state...');
    
    _consecutiveFailures = 0;
    _lastFailureTime = null;
    _lastRecoveryAttempt = null;
    _recoveryTimer?.cancel();
    
    if (_primaryProvider != null) {
      _currentProvider = _primaryProvider;
      _updateState(ProviderState.usingPrimary);
    }
  }
  
  /// Dispose of resources
  void dispose() {
    debugPrint('🗑️  ProviderRecoveryService: Disposing...');
    
    _recoveryTimer?.cancel();
    _eventController.close();
    _healthMonitor.dispose();
  }
}

/// Provider state enumeration
enum ProviderState {
  unknown,
  usingPrimary,
  usingFallback,
  recovering,
  error,
}

/// Recovery event types
enum RecoveryEventType {
  stateChanged,
  switchedToFallback,
  recoveredToPrimary,
  recoveryFailed,
  networkHealthChanged,
}

/// Provider recovery event
class ProviderRecoveryEvent {
  final RecoveryEventType type;
  final DateTime timestamp;
  final String reason;
  final int consecutiveFailures;
  
  ProviderRecoveryEvent({
    required this.type,
    required this.timestamp,
    required this.reason,
    required this.consecutiveFailures,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'reason': reason,
      'consecutiveFailures': consecutiveFailures,
    };
  }
  
  @override
  String toString() {
    return 'ProviderRecoveryEvent(${type.name}: $reason)';
  }
}

/// Provider recovery statistics
class ProviderRecoveryStats {
  final ProviderState currentState;
  final int consecutiveFailures;
  final DateTime? lastFailureTime;
  final DateTime? lastRecoveryAttempt;
  final bool isRecoveryScheduled;
  final bool networkHealthy;
  final String? primaryProviderType;
  final String? fallbackProviderType;
  final String? currentProviderType;
  
  ProviderRecoveryStats({
    required this.currentState,
    required this.consecutiveFailures,
    this.lastFailureTime,
    this.lastRecoveryAttempt,
    required this.isRecoveryScheduled,
    required this.networkHealthy,
    this.primaryProviderType,
    this.fallbackProviderType,
    this.currentProviderType,
  });
  
  /// Time since last failure
  Duration? get timeSinceLastFailure {
    if (lastFailureTime == null) return null;
    return DateTime.now().difference(lastFailureTime!);
  }
  
  /// Time since last recovery attempt
  Duration? get timeSinceLastRecovery {
    if (lastRecoveryAttempt == null) return null;
    return DateTime.now().difference(lastRecoveryAttempt!);
  }
  
  /// Check if recovery is needed
  bool get needsRecovery {
    return currentState == ProviderState.usingFallback && networkHealthy;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'currentState': currentState.name,
      'consecutiveFailures': consecutiveFailures,
      'lastFailureTime': lastFailureTime?.toIso8601String(),
      'lastRecoveryAttempt': lastRecoveryAttempt?.toIso8601String(),
      'isRecoveryScheduled': isRecoveryScheduled,
      'networkHealthy': networkHealthy,
      'primaryProviderType': primaryProviderType,
      'fallbackProviderType': fallbackProviderType,
      'currentProviderType': currentProviderType,
      'timeSinceLastFailure': timeSinceLastFailure?.inSeconds,
      'timeSinceLastRecovery': timeSinceLastRecovery?.inSeconds,
      'needsRecovery': needsRecovery,
    };
  }
  
  @override
  String toString() {
    return 'ProviderRecoveryStats(state: $currentState, failures: $consecutiveFailures, healthy: $networkHealthy)';
  }
}