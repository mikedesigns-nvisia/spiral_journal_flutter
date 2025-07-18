/// Represents the AI analysis results for a journal entry
class EmotionalAnalysis {
  final List<String> primaryEmotions;
  final double emotionalIntensity; // 0.0 to 1.0
  final List<String> keyThemes;
  final String? personalizedInsight;
  final Map<String, double> coreImpacts; // Impact on each personality core
  final DateTime analyzedAt;

  EmotionalAnalysis({
    required this.primaryEmotions,
    required this.emotionalIntensity,
    required this.keyThemes,
    this.personalizedInsight,
    required this.coreImpacts,
    required this.analyzedAt,
  });

  factory EmotionalAnalysis.fromJson(Map<String, dynamic> json) {
    return EmotionalAnalysis(
      primaryEmotions: List<String>.from(json['primaryEmotions'] ?? []),
      emotionalIntensity: (json['emotionalIntensity'] ?? 0.0).toDouble(),
      keyThemes: List<String>.from(json['keyThemes'] ?? []),
      personalizedInsight: json['personalizedInsight'],
      coreImpacts: Map<String, double>.from(json['coreImpacts'] ?? {}),
      analyzedAt: DateTime.parse(json['analyzedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryEmotions': primaryEmotions,
      'emotionalIntensity': emotionalIntensity,
      'keyThemes': keyThemes,
      'personalizedInsight': personalizedInsight,
      'coreImpacts': coreImpacts,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }
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
  
  // Enhanced fields for AI analysis
  final EmotionalAnalysis? aiAnalysis;
  final bool isAnalyzed;
  final String? draftContent; // For crash recovery
  final List<String> aiDetectedMoods; // AI-detected emotions
  final double? emotionalIntensity; // 0.0 to 1.0
  final List<String> keyThemes; // Main themes from AI analysis
  final String? personalizedInsight; // AI-generated personal insight

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
    this.aiAnalysis,
    this.isAnalyzed = false,
    this.draftContent,
    this.aiDetectedMoods = const [],
    this.emotionalIntensity,
    this.keyThemes = const [],
    this.personalizedInsight,
  });

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
      isAnalyzed: isAnalyzed ?? this.isAnalyzed,
      draftContent: draftContent ?? this.draftContent,
      aiDetectedMoods: aiDetectedMoods ?? this.aiDetectedMoods,
      emotionalIntensity: emotionalIntensity ?? this.emotionalIntensity,
      keyThemes: keyThemes ?? this.keyThemes,
      personalizedInsight: personalizedInsight ?? this.personalizedInsight,
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
