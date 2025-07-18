import '../models/journal_entry.dart';
import '../models/core.dart';

// Error handling classes
enum AIErrorType {
  network,
  authentication,
  rateLimit,
  serverError,
  clientError,
  timeout,
  parsing,
  unknown,
}

class AIServiceException implements Exception {
  final String message;
  final AIErrorType type;
  final bool isRetryable;
  final dynamic originalError;

  AIServiceException(
    this.message, {
    required this.type,
    required this.isRetryable,
    this.originalError,
  });

  @override
  String toString() {
    return 'AIServiceException: $message (Type: $type, Retryable: $isRetryable)';
  }

  /// Get user-friendly error message
  String get userMessage {
    switch (type) {
      case AIErrorType.network:
        return 'Unable to connect to AI service. Please check your internet connection.';
      case AIErrorType.authentication:
        return 'AI service authentication failed. Please check your API key.';
      case AIErrorType.rateLimit:
        return 'Too many requests. Please wait a moment and try again.';
      case AIErrorType.serverError:
        return 'AI service is temporarily unavailable. Please try again later.';
      case AIErrorType.clientError:
        return 'Request error. Please try again.';
      case AIErrorType.timeout:
        return 'Request timed out. Please try again.';
      case AIErrorType.parsing:
        return 'Unable to process AI response. Using fallback analysis.';
      case AIErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

enum AIProvider {
  enabled,
  disabled,
}

extension AIProviderExtension on AIProvider {
  String get displayName {
    switch (this) {
      case AIProvider.enabled:
        return 'AI Analysis Enabled';
      case AIProvider.disabled:
        return 'Basic Analysis Only';
    }
  }

  String get description {
    switch (this) {
      case AIProvider.enabled:
        return 'Advanced emotional intelligence analysis';
      case AIProvider.disabled:
        return 'Simple mood-based analysis without AI';
    }
  }
}

abstract class AIServiceInterface {
  AIProvider get provider;
  bool get isConfigured;
  bool get isEnabled;

  Future<void> setApiKey(String apiKey);
  Future<void> testConnection();
  
  Future<Map<String, dynamic>> analyzeJournalEntry(JournalEntry entry);
  Future<String> generateMonthlyInsight(List<JournalEntry> entries);
  Future<Map<String, double>> calculateCoreUpdates(
    JournalEntry entry,
    List<EmotionalCore> currentCores,
  );
}

class AIServiceConfig {
  final AIProvider provider;
  final String apiKey;
  final String? baseUrl;
  final Map<String, dynamic> additionalSettings;

  AIServiceConfig({
    required this.provider,
    required this.apiKey,
    this.baseUrl,
    this.additionalSettings = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'additionalSettings': additionalSettings,
    };
  }

  factory AIServiceConfig.fromJson(Map<String, dynamic> json) {
    return AIServiceConfig(
      provider: AIProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AIProvider.disabled,
      ),
      apiKey: json['apiKey'] ?? '',
      baseUrl: json['baseUrl'],
      additionalSettings: Map<String, dynamic>.from(json['additionalSettings'] ?? {}),
    );
  }
}