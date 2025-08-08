/// Entry status enumeration
enum EntryStatus {
  draft,     // Entry is being written/edited
  saved,     // Entry is saved but can still be edited (same day)
  processed  // Entry is processed and cannot be edited (past days)
}

/// Represents mind reflection data from AI analysis
class MindReflection {
  final String title;
  final String summary;
  final List<String> insights;

  MindReflection({
    required this.title,
    required this.summary,
    required this.insights,
  });

  factory MindReflection.fromJson(Map<String, dynamic> json) {
    return MindReflection(
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      insights: List<String>.from(json['insights'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'insights': insights,
    };
  }
}

/// Represents emotional patterns identified in the analysis
class JournalEmotionalPattern {
  final String category;
  final String title;
  final String description;
  final String type; // 'growth' or 'challenge'

  JournalEmotionalPattern({
    required this.category,
    required this.title,
    required this.description,
    required this.type,
  });

  factory JournalEmotionalPattern.fromJson(Map<String, dynamic> json) {
    return JournalEmotionalPattern(
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'growth',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'type': type,
    };
  }

  bool get isGrowth => type == 'growth';
  bool get isChallenge => type == 'challenge';
}

/// Enhanced AI analysis results matching Claude's response structure
class EmotionalAnalysis {
  final List<String> primaryEmotions;
  final double emotionalIntensity; // 0.0 to 1.0
  final List<String> growthIndicators;
  final Map<String, double> coreAdjustments; // Core impact adjustments
  final MindReflection? mindReflection;
  final List<JournalEmotionalPattern> emotionalPatterns;
  final String? entryInsight; // Main insight for the entry
  final DateTime analyzedAt;
  
  // Legacy fields for backward compatibility
  final List<String> keyThemes;
  final String? personalizedInsight;

  EmotionalAnalysis({
    required this.primaryEmotions,
    required this.emotionalIntensity,
    this.growthIndicators = const [],
    this.coreAdjustments = const {},
    this.mindReflection,
    this.emotionalPatterns = const [],
    this.entryInsight,
    required this.analyzedAt,
    // Legacy fields
    this.keyThemes = const [],
    this.personalizedInsight,
  });

  factory EmotionalAnalysis.fromJson(Map<String, dynamic> json) {
    return EmotionalAnalysis(
      primaryEmotions: List<String>.from(json['primary_emotions'] ?? json['primaryEmotions'] ?? []),
      emotionalIntensity: (json['emotional_intensity'] ?? json['emotionalIntensity'] ?? 0.0).toDouble(),
      growthIndicators: List<String>.from(json['growth_indicators'] ?? []),
      coreAdjustments: Map<String, double>.from(json['core_adjustments'] ?? {}),
      mindReflection: json['mind_reflection'] != null 
          ? MindReflection.fromJson(json['mind_reflection']) 
          : null,
      emotionalPatterns: (json['emotional_patterns'] as List?)
          ?.map((pattern) => JournalEmotionalPattern.fromJson(pattern))
          .toList() ?? [],
      entryInsight: json['entry_insight'],
      analyzedAt: json['analyzedAt'] != null 
          ? DateTime.parse(json['analyzedAt']) 
          : DateTime.now(),
      // Legacy fields for backward compatibility
      keyThemes: List<String>.from(json['keyThemes'] ?? json['key_themes'] ?? []),
      personalizedInsight: json['personalizedInsight'] ?? json['personalized_insight'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_emotions': primaryEmotions,
      'emotional_intensity': emotionalIntensity,
      'growth_indicators': growthIndicators,
      'core_adjustments': coreAdjustments,
      'mind_reflection': mindReflection?.toJson(),
      'emotional_patterns': emotionalPatterns.map((p) => p.toJson()).toList(),
      'entry_insight': entryInsight,
      'analyzedAt': analyzedAt.toIso8601String(),
      // Legacy fields
      'keyThemes': keyThemes,
      'personalizedInsight': personalizedInsight,
    };
  }

  // Convenience getters for backward compatibility
  Map<String, double> get coreImpacts => coreAdjustments;
}

class JournalEntry {
  final String id;
  final String userId; // For multi-user support
  final DateTime date;
  final String content;
  final List<String> moods;
  final String dayOfWeek;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced; // For offline/online sync
  final Map<String, dynamic> metadata; // For AI analysis data
  
  final String? draftContent; // For crash recovery
  
  // Entry status tracking
  final EntryStatus status; // draft, saved, processed
  final bool isEditable; // Whether entry can be edited

  JournalEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.content,
    required this.moods,
    required this.dayOfWeek,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.metadata = const {},
    this.draftContent,
    this.status = EntryStatus.draft,
    bool? isEditable,
  }) : isEditable = isEditable ?? _calculateEditability(date, status);

  // Helper method to calculate if entry is editable
  static bool _calculateEditability(DateTime entryDate, EntryStatus status) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(entryDate.year, entryDate.month, entryDate.day);
    
    // Entry is editable if it's from today and not processed
    return entryDay.isAtSameMomentAs(today) && status != EntryStatus.processed;
  }

  // Create a new entry with current date
  factory JournalEntry.create({
    required String content,
    required List<String> moods,
    String? id,
    String? userId,
  }) {
    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return JournalEntry(
      id: id ?? '',
      userId: userId ?? 'local_user', // Default for local-only
      date: now,
      content: content,
      moods: moods,
      dayOfWeek: dayNames[now.weekday - 1],
      createdAt: now,
      updatedAt: now,
      isSynced: true, // Always synced in local-only mode
      metadata: {},
    );
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final status = EntryStatus.values.firstWhere(
      (e) => e.toString() == 'EntryStatus.${json['status']}',
      orElse: () => EntryStatus.draft,
    );
    
    return JournalEntry(
      id: json['id'],
      userId: json['userId'] ?? 'local_user',
      date: DateTime.parse(json['date']),
      content: json['content'],
      moods: List<String>.from(json['moods']),
      dayOfWeek: json['dayOfWeek'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['date']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['date']),
      isSynced: json['isSynced'] ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      aiAnalysis: json['aiAnalysis'] != null 
          ? EmotionalAnalysis.fromJson(json['aiAnalysis']) 
          : null,
      isAnalyzed: json['isAnalyzed'] ?? false,
      draftContent: json['draftContent'],
      aiDetectedMoods: List<String>.from(json['aiDetectedMoods'] ?? []),
      emotionalIntensity: json['emotionalIntensity']?.toDouble(),
      keyThemes: List<String>.from(json['keyThemes'] ?? []),
      personalizedInsight: json['personalizedInsight'],
      status: status,
      isEditable: json['isEditable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'content': content,
      'moods': moods,
      'dayOfWeek': dayOfWeek,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
      'metadata': metadata,
      'aiAnalysis': aiAnalysis?.toJson(),
      'isAnalyzed': isAnalyzed,
      'draftContent': draftContent,
      'aiDetectedMoods': aiDetectedMoods,
      'emotionalIntensity': emotionalIntensity,
      'keyThemes': keyThemes,
      'personalizedInsight': personalizedInsight,
      'status': status.toString().split('.').last,
      'isEditable': isEditable,
    };
  }

  // Helper methods
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get monthYear {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String get preview {
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }

  bool containsMood(String mood) {
    return moods.any((m) => m.toLowerCase() == mood.toLowerCase());
  }

  JournalEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? content,
    List<String>? moods,
    String? dayOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    Map<String, dynamic>? metadata,
    EmotionalAnalysis? aiAnalysis,
    bool? isAnalyzed,
    String? draftContent,
    List<String>? aiDetectedMoods,
    double? emotionalIntensity,
    List<String>? keyThemes,
    String? personalizedInsight,
    EntryStatus? status,
    bool? isEditable,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      content: content ?? this.content,
      moods: moods ?? this.moods,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      metadata: metadata ?? this.metadata,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      isAnalyzed: isAnalyzed ?? this.moods.isNotEmpty,
      draftContent: draftContent ?? this.draftContent,
      aiDetectedMoods: aiDetectedMoods ?? this.aiDetectedMoods,
      emotionalIntensity: emotionalIntensity ?? this.emotionalIntensity,
      keyThemes: keyThemes ?? this.keyThemes,
      personalizedInsight: personalizedInsight ?? this.personalizedInsight,
      status: status ?? this.status,
      isEditable: isEditable ?? this.isEditable,
    );
  }
}

class MonthlySummary {
  final String id;
  final String month;
  final int year;
  final List<String> dominantMoods;
  final List<double> emotionalJourneyData;
  final String insight;
  final int entryCount;

  MonthlySummary({
    required this.id,
    required this.month,
    required this.year,
    required this.dominantMoods,
    required this.emotionalJourneyData,
    required this.insight,
    required this.entryCount,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      id: json['id'],
      month: json['month'],
      year: json['year'],
      dominantMoods: List<String>.from(json['dominantMoods']),
      emotionalJourneyData: List<double>.from(json['emotionalJourneyData']),
      insight: json['insight'],
      entryCount: json['entryCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'dominantMoods': dominantMoods,
      'emotionalJourneyData': emotionalJourneyData,
      'insight': insight,
      'entryCount': entryCount,
    };
  }

  String get displayName => '$month $year';
}
