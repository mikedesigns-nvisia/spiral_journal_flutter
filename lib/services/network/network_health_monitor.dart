import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Network health monitoring service for iOS Anthropic API connectivity
/// 
/// Provides real-time network status monitoring, DNS health checks,
/// and Anthropic API-specific connectivity testing
class NetworkHealthMonitor {
  static final NetworkHealthMonitor _instance = NetworkHealthMonitor._internal();
  factory NetworkHealthMonitor() => _instance;
  NetworkHealthMonitor._internal();
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _healthCheckTimer;
  Timer? _dnsCheckTimer;
  
  // Stream controllers
  final StreamController<NetworkHealthStatus> _healthStatusController = 
      StreamController<NetworkHealthStatus>.broadcast();
  final StreamController<ConnectivityResult> _connectivityController = 
      StreamController<ConnectivityResult>.broadcast();
  
  // Current status
  NetworkHealthStatus _currentStatus = NetworkHealthStatus.unknown;
  ConnectivityResult _currentConnectivity = ConnectivityResult.none;
  DateTime? _lastSuccessfulApiCall;
  DateTime? _lastDnsCheck;
  
  // Health check configuration
  static const Duration _healthCheckInterval = Duration(minutes: 2);
  static const Duration _dnsCheckInterval = Duration(minutes: 1);
  static const Duration _apiTimeout = Duration(seconds: 10);
  
  // Health check URLs
  static const String _anthropicApiHealthUrl = 'https://api.anthropic.com/v1/complete';
  static const String _dnsTestHost = 'api.anthropic.com';
  
  // Getters
  Stream<NetworkHealthStatus> get healthStatusStream => _healthStatusController.stream;
  Stream<ConnectivityResult> get connectivityStream => _connectivityController.stream;
  NetworkHealthStatus get currentHealthStatus => _currentStatus;
  ConnectivityResult get currentConnectivity => _currentConnectivity;
  DateTime? get lastSuccessfulApiCall => _lastSuccessfulApiCall;
  DateTime? get lastDnsCheck => _lastDnsCheck;
  
  /// Initialize network monitoring
  Future<void> initialize() async {
    try {
      debugPrint('🌐 NetworkHealthMonitor: Initializing...');
      
      // Get initial connectivity status
      final connectivityResults = await _connectivity.checkConnectivity();
      _currentConnectivity = connectivityResults.isNotEmpty 
          ? connectivityResults.first 
          : ConnectivityResult.none;
      
      // Start connectivity monitoring
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          debugPrint('❌ NetworkHealthMonitor connectivity error: $error');
        },
      );
      
      // Perform initial health check
      await _performHealthCheck();
      
      // Start periodic monitoring
      _startPeriodicMonitoring();
      
      debugPrint('✅ NetworkHealthMonitor: Initialized successfully');
      debugPrint('   Initial connectivity: $_currentConnectivity');
      debugPrint('   Initial health status: $_currentStatus');
      
    } catch (e) {
      debugPrint('❌ NetworkHealthMonitor initialization failed: $e');
      _updateHealthStatus(NetworkHealthStatus.error);
    }
  }
  
  /// Start periodic health monitoring
  void _startPeriodicMonitoring() {
    // API health checks
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performHealthCheck();
    });
    
    // DNS resolution checks
    _dnsCheckTimer = Timer.periodic(_dnsCheckInterval, (_) {
      _performDnsCheck();
    });
  }
  
  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final newConnectivity = results.isNotEmpty ? results.first : ConnectivityResult.none;
    final previousConnectivity = _currentConnectivity;
    _currentConnectivity = newConnectivity;
    
    debugPrint('🔄 NetworkHealthMonitor: Connectivity changed from $previousConnectivity to $newConnectivity');
    
    // Emit connectivity change
    _connectivityController.add(newConnectivity);
    
    // Update health status based on connectivity
    if (newConnectivity == ConnectivityResult.none) {
      _updateHealthStatus(NetworkHealthStatus.offline);
    } else {
      // Perform immediate health check when connectivity is restored
      _performHealthCheck();
    }
  }
  
  /// Perform comprehensive health check
  Future<void> _performHealthCheck() async {
    try {
      if (_currentConnectivity == ConnectivityResult.none) {
        _updateHealthStatus(NetworkHealthStatus.offline);
        return;
      }
      
      debugPrint('🔍 NetworkHealthMonitor: Performing health check...');
      
      // Test basic internet connectivity first
      final internetAvailable = await _testInternetConnectivity();
      if (!internetAvailable) {
        _updateHealthStatus(NetworkHealthStatus.noInternet);
        return;
      }
      
      // Test Anthropic API connectivity
      final apiHealthy = await _testAnthropicApiHealth();
      if (apiHealthy) {
        _lastSuccessfulApiCall = DateTime.now();
        _updateHealthStatus(_currentConnectivity == ConnectivityResult.wifi 
            ? NetworkHealthStatus.healthyWifi 
            : NetworkHealthStatus.healthyCellular);
      } else {
        _updateHealthStatus(NetworkHealthStatus.apiUnreachable);
      }
      
    } catch (e) {
      debugPrint('❌ NetworkHealthMonitor health check failed: $e');
      _updateHealthStatus(NetworkHealthStatus.error);
    }
  }
  
  /// Test basic internet connectivity
  Future<bool> _testInternetConnectivity() async {
    try {
      // Use a lightweight endpoint for connectivity test
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'User-Agent': 'SpiralJournal/1.0'},
      ).timeout(Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️  NetworkHealthMonitor: Internet connectivity test failed: $e');
      return false;
    }
  }
  
  /// Test Anthropic API health
  Future<bool> _testAnthropicApiHealth() async {
    try {
      // Use a minimal request to test API connectivity
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
          'x-api-key': 'test-key', // Will fail auth but tests connectivity
        },
        body: jsonEncode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 1,
          'messages': [{'role': 'user', 'content': 'test'}],
        }),
      ).timeout(_apiTimeout);
      
      // 401 means the API is reachable but auth failed (expected)
      // 200 would mean success (unexpected with test key)
      // Other codes might indicate API issues
      final isHealthy = response.statusCode == 401 || response.statusCode == 200;
      
      debugPrint('🏥 NetworkHealthMonitor: API health check - Status: ${response.statusCode}, Healthy: $isHealthy');
      return isHealthy;
      
    } on SocketException catch (e) {
      debugPrint('🔴 NetworkHealthMonitor: API socket error: $e (errno: ${e.osError?.errorCode})');
      
      // Specifically check for DNS resolution failure
      if (e.osError?.errorCode == 8) {
        debugPrint('🔴 DNS resolution failure detected for api.anthropic.com');
      }
      return false;
    } on TimeoutException catch (e) {
      debugPrint('⏰ NetworkHealthMonitor: API timeout: $e');
      return false;
    } catch (e) {
      debugPrint('❌ NetworkHealthMonitor: API health check error: $e');
      return false;
    }
  }
  
  /// Perform DNS resolution check
  Future<void> _performDnsCheck() async {
    try {
      debugPrint('🔍 NetworkHealthMonitor: Checking DNS resolution for $_dnsTestHost...');
      
      final addresses = await InternetAddress.lookup(_dnsTestHost)
          .timeout(Duration(seconds: 5));
      
      if (addresses.isNotEmpty) {
        _lastDnsCheck = DateTime.now();
        debugPrint('✅ DNS resolution successful: ${addresses.first.address}');
      } else {
        debugPrint('⚠️  DNS resolution returned no addresses');
      }
      
    } on SocketException catch (e) {
      debugPrint('🔴 DNS resolution failed: $e (errno: ${e.osError?.errorCode})');
      _lastDnsCheck = null;
      
      if (e.osError?.errorCode == 8) {
        debugPrint('🔴 Specific DNS failure (errno 8) detected');
        // Could trigger specific recovery actions here
      }
    } catch (e) {
      debugPrint('❌ DNS check error: $e');
      _lastDnsCheck = null;
    }
  }
  
  /// Update health status and notify listeners
  void _updateHealthStatus(NetworkHealthStatus newStatus) {
    if (_currentStatus != newStatus) {
      final previousStatus = _currentStatus;
      _currentStatus = newStatus;
      
      debugPrint('📊 NetworkHealthMonitor: Status changed from $previousStatus to $newStatus');
      
      // Emit status change
      _healthStatusController.add(newStatus);
    }
  }
  
  /// Force immediate health check
  Future<void> forceHealthCheck() async {
    debugPrint('🔄 NetworkHealthMonitor: Forcing immediate health check...');
    await _performHealthCheck();
  }
  
  /// Check if currently on WiFi
  bool get isOnWifi => _currentConnectivity == ConnectivityResult.wifi;
  
  /// Check if currently on cellular
  bool get isOnCellular => _currentConnectivity == ConnectivityResult.mobile;
  
  /// Check if currently offline
  bool get isOffline => _currentConnectivity == ConnectivityResult.none;
  
  /// Check if API is healthy
  bool get isApiHealthy => _currentStatus == NetworkHealthStatus.healthyWifi || 
                          _currentStatus == NetworkHealthStatus.healthyCellular;
  
  /// Get detailed network information
  NetworkHealthInfo getDetailedInfo() {
    return NetworkHealthInfo(
      healthStatus: _currentStatus,
      connectivity: _currentConnectivity,
      lastSuccessfulApiCall: _lastSuccessfulApiCall,
      lastDnsCheck: _lastDnsCheck,
      isMonitoring: _healthCheckTimer?.isActive ?? false,
    );
  }
  
  /// Get network quality assessment
  NetworkQuality getNetworkQuality() {
    if (_currentStatus == NetworkHealthStatus.offline) {
      return NetworkQuality.offline;
    }
    
    if (_currentStatus == NetworkHealthStatus.healthyWifi) {
      return NetworkQuality.excellent;
    }
    
    if (_currentStatus == NetworkHealthStatus.healthyCellular) {
      return NetworkQuality.good;
    }
    
    if (_currentStatus == NetworkHealthStatus.noInternet) {
      return NetworkQuality.poor;
    }
    
    return NetworkQuality.unknown;
  }
  
  /// Dispose of resources
  void dispose() {
    debugPrint('🗑️  NetworkHealthMonitor: Disposing...');
    
    _connectivitySubscription?.cancel();
    _healthCheckTimer?.cancel();
    _dnsCheckTimer?.cancel();
    
    _healthStatusController.close();
    _connectivityController.close();
  }
}

/// Network health status enumeration
enum NetworkHealthStatus {
  unknown,
  offline,
  noInternet,
  healthyWifi,
  healthyCellular,
  apiUnreachable,
  error,
}

/// Network quality assessment
enum NetworkQuality {
  offline,
  poor,
  good,
  excellent,
  unknown,
}

/// Detailed network health information
class NetworkHealthInfo {
  final NetworkHealthStatus healthStatus;
  final ConnectivityResult connectivity;
  final DateTime? lastSuccessfulApiCall;
  final DateTime? lastDnsCheck;
  final bool isMonitoring;
  
  NetworkHealthInfo({
    required this.healthStatus,
    required this.connectivity,
    this.lastSuccessfulApiCall,
    this.lastDnsCheck,
    required this.isMonitoring,
  });
  
  /// Get time since last successful API call
  Duration? get timeSinceLastApiCall {
    if (lastSuccessfulApiCall == null) return null;
    return DateTime.now().difference(lastSuccessfulApiCall!);
  }
  
  /// Get time since last DNS check
  Duration? get timeSinceLastDnsCheck {
    if (lastDnsCheck == null) return null;
    return DateTime.now().difference(lastDnsCheck!);
  }
  
  /// Convert to JSON for logging
  Map<String, dynamic> toJson() {
    return {
      'healthStatus': healthStatus.name,
      'connectivity': connectivity.name,
      'lastSuccessfulApiCall': lastSuccessfulApiCall?.toIso8601String(),
      'lastDnsCheck': lastDnsCheck?.toIso8601String(),
      'isMonitoring': isMonitoring,
      'timeSinceLastApiCall': timeSinceLastApiCall?.inSeconds,
      'timeSinceLastDnsCheck': timeSinceLastDnsCheck?.inSeconds,
    };
  }
  
  @override
  String toString() {
    return 'NetworkHealthInfo(status: $healthStatus, connectivity: $connectivity, monitoring: $isMonitoring)';
  }
}