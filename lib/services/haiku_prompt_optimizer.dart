import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';

/// Haiku-optimized prompt service for cost-effective AI analysis
/// 
/// This service implements aggressive prompt optimization techniques specifically
/// designed for Claude Haiku to maximize cost savings while maintaining analysis quality:
/// 
/// - Ultra-compressed prompts (50-70% reduction in tokens)
/// - Structured output format for parsing efficiency  
/// - Smart model selection based on entry complexity
/// - Batch processing for multiple entries
/// - Cost tracking and optimization metrics
class HaikuPromptOptimizer {
  static final HaikuPromptOptimizer _instance = HaikuPromptOptimizer._internal();
  factory HaikuPromptOptimizer() => _instance;
  HaikuPromptOptimizer._internal();

  // Cost tracking
  int _totalTokensUsed = 0;
  int _totalRequests = 0;
  double _estimatedCost = 0.0;

  // Haiku model pricing (per 1M tokens)
  static const double _haikuInputCost = 0.25;  // $0.25 per 1M input tokens
  static const double _haikuOutputCost = 1.25; // $1.25 per 1M output tokens

  // Optimization settings
  static const int _maxPromptTokens = 800;      // Ultra-short prompts for Haiku
  static const int _maxOutputTokens = 1024;     // Sufficient for structured output
  static const double _temperature = 0.7;       // Balanced creativity/consistency

  // Model selection thresholds
  static const int _complexityThresholdWords = 200;  // Switch to Sonnet for complex entries
  static const int _moodThreshold = 4;               // Multiple moods = complexity

  /// Create optimized system prompt for Haiku
  String createHaikuSystemPrompt() {
    return '''Analyze journal entries. Return JSON only:
{
  "emotions": ["str"],
  "intensity": 0.0-1.0,
  "themes": ["str"],
  "sentiment": -1.0-1.0,
  "insight": "str",
  "cores": {
    "optimism": -1.0-1.0,
    "resilience": -1.0-1.0,
    "self_awareness": -1.0-1.0,
    "creativity": -1.0-1.0,
    "social_connection": -1.0-1.0,
    "growth_mindset": -1.0-1.0
  },
  "patterns": ["str"],
  "growth": ["str"]
}
Limit: 3 emotions, 3 themes, 3 patterns, 3 growth items. Insight max 100 chars.''';
  }

  /// Create ultra-compressed entry analysis prompt
  String createOptimizedAnalysisPrompt(JournalEntry entry) {
    final content = _compressContent(entry.content);
    final moods = entry.moods.take(3).join(','); // Limit to 3 moods
    
    return '''Entry: "${content}"
Moods: ${moods.isNotEmpty ? moods : 'none'}
Date: ${_formatDateCompact(entry.date)}''';
  }

  /// Create batch analysis prompt for multiple entries (more cost-effective)
  String createBatchAnalysisPrompt(List<JournalEntry> entries) {
    final batchData = entries.take(5).map((entry) => {
      'id': entry.id,
      'content': _compressContent(entry.content, maxLength: 150),
      'moods': entry.moods.take(2).join(','),
      'date': _formatDateCompact(entry.date),
    }).toList();

    return '''Batch analysis:
${batchData.map((e) => '${e['id']}: "${e['content']}" [${e['moods']}] (${e['date']})').join('\\n')}

Return array of analyses:
[{"id":"","emotions":[],"intensity":0,"themes":[],"sentiment":0,"insight":"","cores":{},"patterns":[],"growth":[]}]''';
  }

  /// Create monthly insight prompt (heavily compressed)
  String createCompressedInsightPrompt(List<JournalEntry> entries) {
    final stats = _calculateEntryStats(entries);
    final topMoods = _getTopMoods(entries, limit: 5);
    final sampleEntries = _getSampleEntries(entries, limit: 3);

    return '''${entries.length} entries, ${stats['totalWords']} words
Top moods: ${topMoods.join(',')}
Samples: ${sampleEntries.map((e) => '"${_compressContent(e.content, maxLength: 50)}"').join('; ')}

JSON insight:
{"title":"","summary":"","patterns":[],"growth":[],"recommendations":[]}
Max 80 chars each field.''';
  }

  /// Determine optimal model for entry complexity
  ModelSelectionResult selectOptimalModel(JournalEntry entry) {
    final wordCount = entry.content.split(' ').length;
    final moodCount = entry.moods.length;
    final hasComplexThemes = _hasComplexThemes(entry.content);
    
    final complexityScore = _calculateComplexityScore(wordCount, moodCount, hasComplexThemes);
    
    if (complexityScore > 0.7) {
      return ModelSelectionResult(
        model: 'claude-3-5-sonnet-20241022',
        reason: 'High complexity (score: ${complexityScore.toStringAsFixed(2)})',
        estimatedCost: _estimateSonnetCost(entry),
        useExtendedThinking: true,
      );
    } else {
      return ModelSelectionResult(
        model: 'claude-3-haiku-20240307',
        reason: 'Optimized for Haiku (score: ${complexityScore.toStringAsFixed(2)})',
        estimatedCost: _estimateHaikuCost(entry),
        useExtendedThinking: false,
      );
    }
  }

  /// Create cost-optimized request configuration
  Map<String, dynamic> createOptimizedRequestConfig(
    String model,
    String systemPrompt,
    String userPrompt, {
    bool useExtendedThinking = false,
  }) {
    final config = <String, dynamic>{
      'model': model,
      'max_tokens': model.contains('haiku') ? _maxOutputTokens : 2048,
      'temperature': _temperature,
      'system': systemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': userPrompt,
        }
      ],
    };

    // Only add extended thinking for complex Sonnet requests
    if (useExtendedThinking && !model.contains('haiku')) {
      config['thinking'] = {
        'type': 'enabled',
        'budget_tokens': 1024, // Reduced thinking budget for cost optimization
      };
    }

    return config;
  }

  /// Track token usage and costs
  void trackUsage(String model, int inputTokens, int outputTokens) {
    _totalTokensUsed += (inputTokens + outputTokens);
    _totalRequests++;

    if (model.contains('haiku')) {
      _estimatedCost += (inputTokens * _haikuInputCost / 1000000) + 
                       (outputTokens * _haikuOutputCost / 1000000);
    } else {
      // Sonnet pricing (approximate)
      _estimatedCost += (inputTokens * 3.0 / 1000000) + 
                       (outputTokens * 15.0 / 1000000);
    }

    if (kDebugMode) {
      debugPrint('💰 Cost Tracking - Model: $model, Tokens: ${inputTokens + outputTokens}, '
                'Total Cost: \$${_estimatedCost.toStringAsFixed(4)}');
    }
  }

  /// Get cost optimization metrics
  CostMetrics getCostMetrics() {
    return CostMetrics(
      totalRequests: _totalRequests,
      totalTokensUsed: _totalTokensUsed,
      estimatedCostUSD: _estimatedCost,
      averageTokensPerRequest: _totalRequests > 0 ? _totalTokensUsed / _totalRequests : 0,
      averageCostPerRequest: _totalRequests > 0 ? _estimatedCost / _totalRequests : 0,
    );
  }

  /// Reset cost tracking
  void resetCostTracking() {
    _totalTokensUsed = 0;
    _totalRequests = 0;
    _estimatedCost = 0.0;
  }

  /// Compress content while preserving emotional context
  String _compressContent(String content, {int maxLength = 300}) {
    if (content.length <= maxLength) return content;
    
    // Remove redundant words while preserving emotional markers
    final compressed = content
        .replaceAll(RegExp(r'\b(really|very|quite|just|actually|basically)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    if (compressed.length <= maxLength) return compressed;
    
    // Truncate but try to preserve complete sentences
    final truncated = compressed.substring(0, maxLength);
    final lastPeriod = truncated.lastIndexOf('.');
    final lastExclamation = truncated.lastIndexOf('!');
    final lastQuestion = truncated.lastIndexOf('?');
    
    final lastSentenceEnd = [lastPeriod, lastExclamation, lastQuestion].reduce((a, b) => a > b ? a : b);
    
    if (lastSentenceEnd > maxLength * 0.7) {
      return truncated.substring(0, lastSentenceEnd + 1);
    }
    
    return '$truncated...';
  }

  /// Format date in compact form
  String _formatDateCompact(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7) return '${diff}d ago';
    if (diff < 30) return '${(diff / 7).round()}w ago';
    return '${date.month}/${date.day}';
  }

  /// Calculate entry statistics for insights
  Map<String, dynamic> _calculateEntryStats(List<JournalEntry> entries) {
    final totalWords = entries.fold<int>(0, (sum, entry) => sum + entry.content.split(' ').length);
    final avgWordsPerEntry = entries.isNotEmpty ? totalWords / entries.length : 0;
    
    return {
      'totalWords': totalWords,
      'avgWordsPerEntry': avgWordsPerEntry.round(),
      'totalEntries': entries.length,
    };
  }

  /// Get top moods across entries
  List<String> _getTopMoods(List<JournalEntry> entries, {int limit = 5}) {
    final moodCounts = <String, int>{};
    
    for (final entry in entries) {
      for (final mood in entry.moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }
    
    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedMoods.take(limit).map((e) => e.key).toList();
  }

  /// Get representative sample entries
  List<JournalEntry> _getSampleEntries(List<JournalEntry> entries, {int limit = 3}) {
    if (entries.length <= limit) return entries;
    
    // Select entries distributed across the time range
    final step = entries.length / limit;
    final samples = <JournalEntry>[];
    
    for (int i = 0; i < limit; i++) {
      final index = (i * step).round().clamp(0, entries.length - 1);
      samples.add(entries[index]);
    }
    
    return samples;
  }

  /// Check for complex themes requiring Sonnet
  bool _hasComplexThemes(String content) {
    final complexIndicators = [
      'relationship', 'career', 'family', 'future', 'past', 'trauma',
      'depression', 'anxiety', 'therapy', 'meditation', 'philosophy',
      'spirituality', 'meaning', 'purpose', 'identity', 'growth'
    ];
    
    final contentLower = content.toLowerCase();
    return complexIndicators.any((indicator) => contentLower.contains(indicator));
  }

  /// Calculate complexity score for model selection
  double _calculateComplexityScore(int wordCount, int moodCount, bool hasComplexThemes) {
    double score = 0.0;
    
    // Word count factor (normalized to 0-1)
    score += (wordCount / 500).clamp(0.0, 1.0) * 0.4;
    
    // Mood complexity factor
    score += (moodCount / 8).clamp(0.0, 1.0) * 0.3;
    
    // Complex themes factor
    if (hasComplexThemes) score += 0.3;
    
    return score.clamp(0.0, 1.0);
  }

  /// Estimate Haiku cost for entry
  double _estimateHaikuCost(JournalEntry entry) {
    final estimatedInputTokens = (entry.content.length / 4).round() + 200; // +200 for system prompt
    final estimatedOutputTokens = 300; // Structured output estimate
    
    return (estimatedInputTokens * _haikuInputCost / 1000000) + 
           (estimatedOutputTokens * _haikuOutputCost / 1000000);
  }

  /// Estimate Sonnet cost for entry
  double _estimateSonnetCost(JournalEntry entry) {
    final estimatedInputTokens = (entry.content.length / 4).round() + 500; // +500 for detailed system prompt
    final estimatedOutputTokens = 800; // More detailed output
    
    return (estimatedInputTokens * 3.0 / 1000000) + 
           (estimatedOutputTokens * 15.0 / 1000000);
  }
}

/// Result of model selection optimization
class ModelSelectionResult {
  final String model;
  final String reason;
  final double estimatedCost;
  final bool useExtendedThinking;

  ModelSelectionResult({
    required this.model,
    required this.reason,
    required this.estimatedCost,
    this.useExtendedThinking = false,
  });

  bool get isHaiku => model.contains('haiku');
  bool get isSonnet => model.contains('sonnet');
}

/// Cost tracking metrics
class CostMetrics {
  final int totalRequests;
  final int totalTokensUsed;
  final double estimatedCostUSD;
  final double averageTokensPerRequest;
  final double averageCostPerRequest;

  CostMetrics({
    required this.totalRequests,
    required this.totalTokensUsed,
    required this.estimatedCostUSD,
    required this.averageTokensPerRequest,
    required this.averageCostPerRequest,
  });

  @override
  String toString() {
    return 'CostMetrics(requests: $totalRequests, tokens: $totalTokensUsed, '
           'cost: \$${estimatedCostUSD.toStringAsFixed(4)}, '
           'avg tokens/req: ${averageTokensPerRequest.toStringAsFixed(1)}, '
           'avg cost/req: \$${averageCostPerRequest.toStringAsFixed(6)})';
  }
}

/// Prompt compression techniques
class PromptCompressionTechniques {
  /// Remove unnecessary words and phrases
  static String removeRedundancy(String text) {
    return text
        .replaceAll(RegExp(r'\b(the|a|an|is|are|was|were|that|this|these|those)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Convert to abbreviated format
  static String abbreviate(String text) {
    return text
        .replaceAll('feeling', 'feel')
        .replaceAll('thinking', 'think')
        .replaceAll('emotional', 'emot')
        .replaceAll('relationship', 'rel')
        .replaceAll('situation', 'sit')
        .replaceAll('experience', 'exp')
        .replaceAll('different', 'diff')
        .replaceAll('important', 'imp')
        .replaceAll('something', 'sth')
        .replaceAll('someone', 'sb');
  }

  /// Extract key emotional phrases
  static List<String> extractKeyPhrases(String content) {
    final emotionalMarkers = RegExp(r'\b(feel|felt|feeling|think|thought|happy|sad|angry|scared|excited|worried|anxious|peaceful|grateful|frustrated|overwhelmed|confident|insecure)\w*\b', caseSensitive: false);
    
    final matches = emotionalMarkers.allMatches(content);
    final context = <String>[];
    
    for (final match in matches) {
      final start = (match.start - 20).clamp(0, content.length);
      final end = (match.end + 20).clamp(0, content.length);
      context.add(content.substring(start, end).replaceAll(RegExp(r'\s+'), ' ').trim());
    }
    
    return context.take(5).toList(); // Limit to 5 key phrases
  }
}