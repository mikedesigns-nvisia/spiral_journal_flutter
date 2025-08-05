import 'package:flutter/foundation.dart';
import '../ai_service_manager.dart';
import 'network_health_monitor.dart';
import 'provider_recovery_service.dart';
import 'network_error_handler.dart';
import '../providers/claude_ai_provider.dart';
import '../providers/fallback_provider.dart';
import '../ai_service_interface.dart';
import '../../utils/ios_network_logger.dart';

/// Integration example showing how to use the new iOS network services
/// 
/// This demonstrates proper initialization and usage of all network components
/// for robust iOS Anthropic API connectivity
class NetworkIntegrationExample {
  
  /// Example of how to initialize the enhanced networking system in your app
  static Future<void> initializeNetworkServices() async {
    try {
      debugPrint('🚀 Initializing enhanced iOS networking services...');
      
      // 1. Initialize network health monitoring
      final healthMonitor = NetworkHealthMonitor();
      await healthMonitor.initialize();
      
      // 2. Create AI service providers
      final primaryConfig = AIServiceConfig(
        provider: AIProvider.enabled,
        apiKey: 'your-claude-api-key', // From environment
      );
      
      final fallbackConfig = AIServiceConfig(
        provider: AIProvider.disabled,
        apiKey: '',
      );
      
      final primaryProvider = ClaudeAIProvider(primaryConfig);
      final fallbackProvider = FallbackProvider(fallbackConfig);
      
      // 3. Initialize provider recovery service
      final recoveryService = ProviderRecoveryService();
      await recoveryService.initialize(
        primaryProvider: primaryProvider,
        fallbackProvider: fallbackProvider,
      );
      
      // 4. Listen to recovery events for debugging
      recoveryService.eventStream.listen((event) {
        IOSNetworkLogger.logConnectivityChange(
          previousState: 'unknown',
          currentState: event.type.name,
          networkInfo: {
            'reason': event.reason,
            'consecutiveFailures': event.consecutiveFailures,
            'timestamp': event.timestamp.toIso8601String(),
          },
        );
      });
      
      // 5. Listen to health status changes
      healthMonitor.healthStatusStream.listen((status) {
        debugPrint('📊 Network health changed to: $status');
        
        // Log the health change
        IOSNetworkLogger.logConnectivityChange(
          previousState: 'unknown',
          currentState: status.name,
          networkInfo: healthMonitor.getDetailedInfo().toJson(),
        );
      });
      
      debugPrint('✅ Enhanced iOS networking services initialized successfully');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize networking services: $e');
      IOSNetworkLogger.logNetworkError(
        operation: 'network_service_initialization',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Example of how to make a robust AI API call with the new error handling
  static Future<Map<String, dynamic>> exampleAIAnalysisCall() async {
    try {
      // This example shows how the AIServiceManager will automatically use
      // the new network error handling and provider recovery
      
      final aiManager = AIServiceManager();
      final mockEntry = JournalEntry(
        id: 'example-id',
        content: 'Today I felt grateful for all the positive changes happening in my life.',
        date: DateTime.now(),
        moods: ['grateful', 'optimistic'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user-id',
      );
      
      // The AIServiceManager will automatically:
      // 1. Use NetworkErrorHandler for robust network requests
      // 2. Handle DNS failures with exponential backoff
      // 3. Switch to fallback provider if needed
      // 4. Log all network operations with IOSNetworkLogger
      final result = await aiManager.analyzeJournalEntry(mockEntry);
      
      debugPrint('✅ AI analysis completed successfully');
      return result;
      
    } on NetworkException catch (e) {
      // Network-specific error handling
      debugPrint('🔴 Network error during AI analysis: ${e.type.name}');
      
      // Get user-friendly error message
      final userMessage = NetworkErrorHandler.getUserFriendlyMessage(e);
      debugPrint('📱 User message: $userMessage');
      
      // Log the error
      IOSNetworkLogger.logNetworkError(
        operation: 'ai_analysis',
        error: e,
        context: {
          'errorType': e.type.name,
          'errno': e.errno,
          'isRetryable': e.isRetryable,
          'userMessage': e.userMessage,
        },
      );
      
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected error during AI analysis: $e');
      rethrow;
    }
  }
  
  /// Example of how to handle specific DNS resolution errors
  static Future<void> exampleDNSErrorHandling() async {
    try {
      // Simulate a DNS resolution test
      await NetworkErrorHandler.handleNetworkRequest<List<InternetAddress>>(
        () async {
          final addresses = await InternetAddress.lookup('api.anthropic.com');
          
          IOSNetworkLogger.logDNSResolution(
            hostname: 'api.anthropic.com',
            addresses: addresses,
            resolutionTime: Duration(milliseconds: 150),
          );
          
          return addresses;
        },
        operation: 'dns_resolution_test',
      );
      
    } on NetworkException catch (e) {
      if (e.type == NetworkErrorType.dnsFailure && e.errno == 8) {
        debugPrint('🔴 iOS DNS errno 8 detected - implementing recovery strategy');
        
        // Log detailed DNS failure information
        IOSNetworkLogger.logDNSResolution(
          hostname: 'api.anthropic.com',
          error: e,
        );
        
        // Implement specific recovery strategies for DNS issues
        await _implementDNSRecoveryStrategy();
      }
    }
  }
  
  /// Example DNS recovery strategy implementation
  static Future<void> _implementDNSRecoveryStrategy() async {
    debugPrint('🔧 Implementing DNS recovery strategy...');
    
    // Strategy 1: Wait and retry with exponential backoff
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await Future.delayed(Duration(seconds: attempt * 2));
        
        final addresses = await InternetAddress.lookup('api.anthropic.com');
        debugPrint('✅ DNS recovery successful on attempt $attempt');
        
        IOSNetworkLogger.logDNSResolution(
          hostname: 'api.anthropic.com',
          addresses: addresses,
          resolutionTime: Duration(seconds: attempt * 2),
        );
        
        return;
      } catch (e) {
        debugPrint('❌ DNS recovery attempt $attempt failed: $e');
        
        if (attempt == 3) {
          // All attempts failed, log final failure
          IOSNetworkLogger.logNetworkError(
            operation: 'dns_recovery',
            error: e,
            context: {
              'totalAttempts': 3,
              'strategy': 'exponential_backoff',
            },
          );
        }
      }
    }
  }
  
  /// Example of monitoring network quality and adjusting behavior
  static void exampleNetworkQualityMonitoring() {
    final healthMonitor = NetworkHealthMonitor();
    
    healthMonitor.healthStatusStream.listen((status) {
      final quality = _assessNetworkQuality(status);
      
      debugPrint('📊 Network quality: $quality');
      
      // Adjust app behavior based on network quality
      switch (quality) {
        case NetworkQuality.excellent:
          // Enable all features, use high-quality settings
          _enableFullFeatures();
          break;
          
        case NetworkQuality.good:
          // Enable most features, use standard settings
          _enableStandardFeatures();
          break;
          
        case NetworkQuality.poor:
          // Enable basic features only, use low-bandwidth settings
          _enableBasicFeatures();
          break;
          
        case NetworkQuality.offline:
          // Switch to offline mode
          _enableOfflineMode();
          break;
          
        default:
          // Unknown quality, use conservative settings
          _enableStandardFeatures();
          break;
      }
    });
  }
  
  static NetworkQuality _assessNetworkQuality(NetworkHealthStatus status) {
    switch (status) {
      case NetworkHealthStatus.healthyWifi:
        return NetworkQuality.excellent;
      case NetworkHealthStatus.healthyCellular:
        return NetworkQuality.good;
      case NetworkHealthStatus.apiUnreachable:
        return NetworkQuality.poor;
      case NetworkHealthStatus.offline:
        return NetworkQuality.offline;
      default:
        return NetworkQuality.unknown;
    }
  }
  
  static void _enableFullFeatures() {
    debugPrint('🚀 Enabling full features - excellent network quality');
    // Enable all AI features, high-quality responses, etc.
  }
  
  static void _enableStandardFeatures() {
    debugPrint('⚖️ Enabling standard features - good network quality');
    // Enable most features with standard quality
  }
  
  static void _enableBasicFeatures() {
    debugPrint('🔋 Enabling basic features - poor network quality');
    // Enable only essential features, optimize for low bandwidth
  }
  
  static void _enableOfflineMode() {
    debugPrint('📴 Switching to offline mode - no network connectivity');
    // Switch to offline-only features, queue operations for later
  }
  
  /// Example of logging a complete network session
  static Future<void> exampleNetworkSessionLogging() async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();
    int totalRequests = 0;
    int successfulRequests = 0;
    int failedRequests = 0;
    final errors = <String>[];
    
    try {
      // Simulate multiple network operations
      for (int i = 0; i < 5; i++) {
        totalRequests++;
        
        try {
          // Simulate network request
          await NetworkErrorHandler.handleNetworkRequest<bool>(
            () async {
              // Simulate random success/failure
              if (DateTime.now().millisecond % 3 == 0) {
                throw SocketException('Simulated network error');
              }
              return true;
            },
            operation: 'test_request_$i',
          );
          
          successfulRequests++;
        } catch (e) {
          failedRequests++;
          errors.add(e.toString());
        }
      }
      
    } finally {
      // Log session summary
      IOSNetworkLogger.logNetworkSession(
        sessionId: sessionId,
        startTime: startTime,
        endTime: DateTime.now(),
        totalRequests: totalRequests,
        successfulRequests: successfulRequests,
        failedRequests: failedRequests,
        errors: errors,
      );
    }
  }
}

/// Mock classes for the example (these would be your actual implementations)
class JournalEntry {
  final String id;
  final String content;
  final DateTime date;
  final List<String> moods;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  
  JournalEntry({
    required this.id,
    required this.content,
    required this.date,
    required this.moods,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });
}