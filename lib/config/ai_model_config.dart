/// AI Model Configuration
/// 
/// Centralized configuration for AI models used in the app.
/// Makes it easy to switch between different models and providers.
library;

class AIModelConfig {
  final String id;
  final String name;
  final String modelId;
  final int maxTokens;
  final double temperature;
  final double inputCostPerMillion;
  final double outputCostPerMillion;
  final bool supportsExtendedThinking;
  final bool isDefault;
  final bool isEnabled;
  final String description;

  const AIModelConfig({
    required this.id,
    required this.name,
    required this.modelId,
    required this.maxTokens,
    this.temperature = 0.7,
    required this.inputCostPerMillion,
    required this.outputCostPerMillion,
    this.supportsExtendedThinking = false,
    this.isDefault = false,
    this.isEnabled = true,
    required this.description,
  });

  /// Calculate cost for a given number of tokens
  double calculateCost(int inputTokens, int outputTokens) {
    final inputCost = (inputTokens / 1000000) * inputCostPerMillion;
    final outputCost = (outputTokens / 1000000) * outputCostPerMillion;
    return inputCost + outputCost;
  }
}

/// Available AI Models
class AIModels {
  // Claude 3 Models
  static const haiku = AIModelConfig(
    id: 'haiku',
    name: 'Claude 3 Haiku',
    modelId: 'claude-3-haiku-20240307',
    maxTokens: 2000,
    temperature: 0.7,
    inputCostPerMillion: 0.25,
    outputCostPerMillion: 1.25,
    isDefault: true,
    description: 'Fast and cost-effective model for quick analysis',
  );

  // Sonnet and Opus are defined but permanently disabled for journal processing
  static const sonnet = AIModelConfig(
    id: 'sonnet',
    name: 'Claude 3.5 Sonnet',
    modelId: 'claude-3-5-sonnet-20241022',
    maxTokens: 4000,
    temperature: 0.7,
    inputCostPerMillion: 3.0,
    outputCostPerMillion: 15.0,
    isEnabled: false, // Permanently disabled - not used for journal entries
    description: 'Not available for journal analysis',
  );

  static const opus = AIModelConfig(
    id: 'opus',
    name: 'Claude 3 Opus',
    modelId: 'claude-3-opus-20240229',
    maxTokens: 4000,
    temperature: 0.7,
    inputCostPerMillion: 15.0,
    outputCostPerMillion: 75.0,
    isEnabled: false, // Permanently disabled - not used for journal entries
    description: 'Not available for journal analysis',
  );

  // Future models can be added here
  // Example for future Claude 4 models (when available):
  /*
  static const claude4Haiku = AIModelConfig(
    id: 'claude4-haiku',
    name: 'Claude 4 Haiku',
    modelId: 'claude-4-haiku-20250601', // Example future model
    maxTokens: 4000,
    temperature: 0.7,
    inputCostPerMillion: 0.5,
    outputCostPerMillion: 2.5,
    supportsExtendedThinking: true,
    isEnabled: false,
    description: 'Next-gen fast model with extended thinking',
  );
  */

  /// Get all available models
  static List<AIModelConfig> get allModels => [
    haiku,
    sonnet,
    opus,
  ];

  /// Get enabled models only (always returns just Haiku for journal processing)
  static List<AIModelConfig> get enabledModels => [haiku];

  /// Get default model
  static AIModelConfig get defaultModel => 
    allModels.firstWhere((model) => model.isDefault, orElse: () => haiku);

  /// Get model by ID
  static AIModelConfig? getById(String id) {
    try {
      return allModels.firstWhere((model) => model.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get model by model ID (actual API model string)
  static AIModelConfig? getByModelId(String modelId) {
    try {
      return allModels.firstWhere((model) => model.modelId == modelId);
    } catch (_) {
      return null;
    }
  }
}

/// Model selection strategy (all strategies now use Haiku for cost control)
enum ModelSelectionStrategy {
  /// Always use Haiku model
  defaultOnly,
  
  /// Use Haiku (most cost-effective)
  costOptimized,
  
  /// Use Haiku (quality optimized for journal processing)
  qualityOptimized,
  
  /// Use Haiku regardless of content complexity
  automatic,
}

/// AI Model Manager - handles model selection and preferences
class AIModelManager {
  
  /// Get currently selected model from preferences
  static Future<AIModelConfig> getSelectedModel() async {
    // In a real implementation, this would read from SharedPreferences
    // For now, return the default
    return AIModels.defaultModel;
  }
  
  /// Save selected model to preferences
  static Future<void> setSelectedModel(String modelId) async {
    // In a real implementation, this would save to SharedPreferences
    // await prefs.setString(_selectedModelKey, modelId);
  }
  
  /// Get model selection strategy
  static Future<ModelSelectionStrategy> getStrategy() async {
    // In a real implementation, this would read from SharedPreferences
    return ModelSelectionStrategy.defaultOnly;
  }
  
  /// Set model selection strategy
  static Future<void> setStrategy(ModelSelectionStrategy strategy) async {
    // In a real implementation, this would save to SharedPreferences
    // await prefs.setString(_strategyKey, strategy.name);
  }
  
  /// Select optimal model based on strategy and content
  /// Always returns Haiku for journal processing to ensure cost control
  static Future<AIModelConfig> selectOptimalModel({
    required String content,
    ModelSelectionStrategy? strategy,
  }) async {
    // Always return Haiku regardless of strategy for journal processing
    return AIModels.haiku;
  }
}