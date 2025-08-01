import 'resonance_depth.dart';

class EmotionalCore {
  final String id;
  final String name;
  final String description;
  final double currentLevel; // Keep for internal calculations only
  final double previousLevel;
  final DateTime lastUpdated;
  final DateTime? lastTransitionDate;
  final int entriesAtCurrentDepth;
  final String trend; // 'rising', 'stable', 'declining'
  final String color;
  final String iconPath;
  final String insight;
  final List<String> relatedCores;
  final List<CoreMilestone> milestones;
  final List<CoreInsight> recentInsights;
  final List<String> transitionSignals; // New field
  final String? supportingEvidence; // New field

  EmotionalCore({
    required this.id,
    required this.name,
    required this.description,
    required this.currentLevel,
    required this.previousLevel,
    required this.lastUpdated,
    this.lastTransitionDate,
    this.entriesAtCurrentDepth = 0,
    required this.trend,
    required this.color,
    required this.iconPath,
    required this.insight,
    required this.relatedCores,
    this.milestones = const [],
    this.recentInsights = const [],
    this.transitionSignals = const [],
    this.supportingEvidence,
  });

  // Remove percentage getter - no longer needed
  
  ResonanceDepth get resonanceDepth => ResonanceDepth.fromLevel(currentLevel);
  
  ResonanceDepth get previousResonanceDepth => ResonanceDepth.fromLevel(previousLevel);

  double get depthProgress {
    final depth = resonanceDepth;
    final range = depth.maxLevel - depth.minLevel;
    final progress = (currentLevel - depth.minLevel) / range;
    return progress.clamp(0.0, 1.0);
  }
  
  bool get isTransitioning => transitionSignals.isNotEmpty && depthProgress > 0.7;

  factory EmotionalCore.fromJson(Map<String, dynamic> json) {
    return EmotionalCore(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      currentLevel: json['currentLevel']?.toDouble() ?? (json['percentage']?.toDouble() ?? 0.0) / 100.0,
      previousLevel: json['previousLevel']?.toDouble() ?? (json['percentage']?.toDouble() ?? 0.0) / 100.0,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      lastTransitionDate: json['lastTransitionDate'] != null 
          ? DateTime.parse(json['lastTransitionDate'])
          : null,
      entriesAtCurrentDepth: json['entriesAtCurrentDepth'] ?? 0,
      trend: json['trend'] ?? 'stable',
      color: json['color'],
      iconPath: json['iconPath'],
      insight: json['insight'] ?? '',
      relatedCores: List<String>.from(json['relatedCores'] ?? []),
      milestones: (json['milestones'] as List<dynamic>?)
          ?.map((m) => CoreMilestone.fromJson(m))
          .toList() ?? [],
      recentInsights: (json['recentInsights'] as List<dynamic>?)
          ?.map((i) => CoreInsight.fromJson(i))
          .toList() ?? [],
      transitionSignals: List<String>.from(json['transitionSignals'] ?? []),
      supportingEvidence: json['supportingEvidence'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'currentLevel': currentLevel,
      'previousLevel': previousLevel,
      'lastUpdated': lastUpdated.toIso8601String(),
      'lastTransitionDate': lastTransitionDate?.toIso8601String(),
      'entriesAtCurrentDepth': entriesAtCurrentDepth,
      'trend': trend,
      'color': color,
      'iconPath': iconPath,
      'insight': insight,
      'relatedCores': relatedCores,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'recentInsights': recentInsights.map((i) => i.toJson()).toList(),
      'transitionSignals': transitionSignals,
      'supportingEvidence': supportingEvidence,
    };
  }

  EmotionalCore copyWith({
    String? id,
    String? name,
    String? description,
    double? currentLevel,
    double? previousLevel,
    DateTime? lastUpdated,
    DateTime? lastTransitionDate,
    int? entriesAtCurrentDepth,
    String? trend,
    String? color,
    String? iconPath,
    String? insight,
    List<String>? relatedCores,
    List<CoreMilestone>? milestones,
    List<CoreInsight>? recentInsights,
    List<String>? transitionSignals,
    String? supportingEvidence,
  }) {
    return EmotionalCore(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      currentLevel: currentLevel ?? this.currentLevel,
      previousLevel: previousLevel ?? this.previousLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastTransitionDate: lastTransitionDate ?? this.lastTransitionDate,
      entriesAtCurrentDepth: entriesAtCurrentDepth ?? this.entriesAtCurrentDepth,
      trend: trend ?? this.trend,
      color: color ?? this.color,
      iconPath: iconPath ?? this.iconPath,
      insight: insight ?? this.insight,
      relatedCores: relatedCores ?? this.relatedCores,
      milestones: milestones ?? this.milestones,
      recentInsights: recentInsights ?? this.recentInsights,
      transitionSignals: transitionSignals ?? this.transitionSignals,
      supportingEvidence: supportingEvidence ?? this.supportingEvidence,
    );
  }
}

class CoreMilestone {
  final String id;
  final String title;
  final String description;
  final double threshold; // 0.0 to 1.0
  final bool isAchieved;
  final DateTime? achievedAt;

  CoreMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.threshold,
    required this.isAchieved,
    this.achievedAt,
  });

  factory CoreMilestone.fromJson(Map<String, dynamic> json) {
    return CoreMilestone(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      threshold: json['threshold'].toDouble(),
      isAchieved: json['isAchieved'] ?? false,
      achievedAt: json['achievedAt'] != null 
          ? DateTime.parse(json['achievedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'threshold': threshold,
      'isAchieved': isAchieved,
      'achievedAt': achievedAt?.toIso8601String(),
    };
  }

  CoreMilestone copyWith({
    String? id,
    String? title,
    String? description,
    double? threshold,
    bool? isAchieved,
    DateTime? achievedAt,
  }) {
    return CoreMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      threshold: threshold ?? this.threshold,
      isAchieved: isAchieved ?? this.isAchieved,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }
}

class CoreInsight {
  final String id;
  final String coreId;
  final String title;
  final String description;
  final String type; // 'growth', 'pattern', 'milestone', 'recommendation'
  final DateTime createdAt;
  final double relevanceScore; // 0.0 to 1.0

  CoreInsight({
    required this.id,
    required this.coreId,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.relevanceScore,
  });

  factory CoreInsight.fromJson(Map<String, dynamic> json) {
    return CoreInsight(
      id: json['id'],
      coreId: json['coreId'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      createdAt: DateTime.parse(json['createdAt']),
      relevanceScore: json['relevanceScore'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coreId': coreId,
      'title': title,
      'description': description,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'relevanceScore': relevanceScore,
    };
  }

  CoreInsight copyWith({
    String? id,
    String? coreId,
    String? title,
    String? description,
    String? type,
    DateTime? createdAt,
    double? relevanceScore,
  }) {
    return CoreInsight(
      id: id ?? this.id,
      coreId: coreId ?? this.coreId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      relevanceScore: relevanceScore ?? this.relevanceScore,
    );
  }
}

class CoreCombination {
  final String name;
  final List<String> coreIds;
  final String description;
  final String benefit;

  CoreCombination({
    required this.name,
    required this.coreIds,
    required this.description,
    required this.benefit,
  });

  factory CoreCombination.fromJson(Map<String, dynamic> json) {
    return CoreCombination(
      name: json['name'],
      coreIds: List<String>.from(json['coreIds']),
      description: json['description'],
      benefit: json['benefit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'coreIds': coreIds,
      'description': description,
      'benefit': benefit,
    };
  }
}

class EmotionalPattern {
  final String title;
  final String description;
  final String type; // 'growth', 'recurring', 'awareness'
  final String category;
  final double confidence;
  final DateTime firstDetected;
  final DateTime lastSeen;
  final List<String> relatedEmotions;

  EmotionalPattern({
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.confidence,
    required this.firstDetected,
    required this.lastSeen,
    required this.relatedEmotions,
  });

  factory EmotionalPattern.fromJson(Map<String, dynamic> json) {
    return EmotionalPattern(
      title: json['title'],
      description: json['description'],
      type: json['type'],
      category: json['category'] ?? 'General',
      confidence: json['confidence']?.toDouble() ?? 0.0,
      firstDetected: DateTime.parse(json['firstDetected']),
      lastSeen: DateTime.parse(json['lastSeen']),
      relatedEmotions: List<String>.from(json['relatedEmotions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'confidence': confidence,
      'firstDetected': firstDetected.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'relatedEmotions': relatedEmotions,
    };
  }
}

// Enhanced models for CoreProvider integration

/// Represents different types of core update events
enum CoreUpdateEventType {
  levelChanged,
  trendChanged,
  milestoneAchieved,
  insightGenerated,
  analysisCompleted,
  batchUpdate,
}

/// Event model for real-time core updates
class CoreUpdateEvent {
  final String coreId;
  final CoreUpdateEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? relatedJournalEntryId;
  final String? updateSource; // 'ai_analysis', 'manual', 'background_sync'

  CoreUpdateEvent({
    required this.coreId,
    required this.type,
    required this.data,
    required this.timestamp,
    this.relatedJournalEntryId,
    this.updateSource,
  });

  factory CoreUpdateEvent.fromJson(Map<String, dynamic> json) {
    return CoreUpdateEvent(
      coreId: json['coreId'],
      type: CoreUpdateEventType.values.firstWhere(
        (e) => e.toString() == 'CoreUpdateEventType.${json['type']}',
        orElse: () => CoreUpdateEventType.levelChanged,
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      relatedJournalEntryId: json['relatedJournalEntryId'],
      updateSource: json['updateSource'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coreId': coreId,
      'type': type.toString().split('.').last,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'relatedJournalEntryId': relatedJournalEntryId,
      'updateSource': updateSource,
    };
  }
}

/// Navigation context for preserving state between core screens
class CoreNavigationContext {
  final String sourceScreen;
  final String? triggeredBy;
  final String? targetCoreId;
  final String? relatedJournalEntryId;
  final Map<String, dynamic> additionalData;
  final DateTime timestamp;

  CoreNavigationContext({
    required this.sourceScreen,
    this.triggeredBy,
    this.targetCoreId,
    this.relatedJournalEntryId,
    this.additionalData = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory CoreNavigationContext.fromJson(Map<String, dynamic> json) {
    return CoreNavigationContext(
      sourceScreen: json['sourceScreen'],
      triggeredBy: json['triggeredBy'],
      targetCoreId: json['targetCoreId'],
      relatedJournalEntryId: json['relatedJournalEntryId'],
      additionalData: Map<String, dynamic>.from(json['additionalData'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceScreen': sourceScreen,
      'triggeredBy': triggeredBy,
      'targetCoreId': targetCoreId,
      'relatedJournalEntryId': relatedJournalEntryId,
      'additionalData': additionalData,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Detailed context for core display with related data
class CoreDetailContext {
  final EmotionalCore core;
  final List<String> relatedJournalEntryIds;
  final List<CoreUpdateEvent> recentUpdates;
  final CoreInsight? latestInsight;
  final List<CoreMilestone> upcomingMilestones;
  final DateTime lastAccessed;

  CoreDetailContext({
    required this.core,
    this.relatedJournalEntryIds = const [],
    this.recentUpdates = const [],
    this.latestInsight,
    this.upcomingMilestones = const [],
    DateTime? lastAccessed,
  }) : lastAccessed = lastAccessed ?? DateTime.now();

  factory CoreDetailContext.fromJson(Map<String, dynamic> json) {
    return CoreDetailContext(
      core: EmotionalCore.fromJson(json['core']),
      relatedJournalEntryIds: List<String>.from(json['relatedJournalEntryIds'] ?? []),
      recentUpdates: (json['recentUpdates'] as List<dynamic>?)
          ?.map((e) => CoreUpdateEvent.fromJson(e))
          .toList() ?? [],
      latestInsight: json['latestInsight'] != null 
          ? CoreInsight.fromJson(json['latestInsight'])
          : null,
      upcomingMilestones: (json['upcomingMilestones'] as List<dynamic>?)
          ?.map((e) => CoreMilestone.fromJson(e))
          .toList() ?? [],
      lastAccessed: DateTime.parse(json['lastAccessed']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'core': core.toJson(),
      'relatedJournalEntryIds': relatedJournalEntryIds,
      'recentUpdates': recentUpdates.map((e) => e.toJson()).toList(),
      'latestInsight': latestInsight?.toJson(),
      'upcomingMilestones': upcomingMilestones.map((e) => e.toJson()).toList(),
      'lastAccessed': lastAccessed.toIso8601String(),
    };
  }
}

/// Navigation state for core provider
class CoreNavigationState {
  final String? currentCoreId;
  final CoreNavigationContext? currentContext;
  final List<String> navigationHistory;
  final DateTime lastNavigation;

  CoreNavigationState({
    this.currentCoreId,
    this.currentContext,
    this.navigationHistory = const [],
    DateTime? lastNavigation,
  }) : lastNavigation = lastNavigation ?? DateTime.now();

  factory CoreNavigationState.initial() {
    return CoreNavigationState();
  }

  CoreNavigationState copyWith({
    String? currentCoreId,
    CoreNavigationContext? currentContext,
    List<String>? navigationHistory,
    DateTime? lastNavigation,
  }) {
    return CoreNavigationState(
      currentCoreId: currentCoreId ?? this.currentCoreId,
      currentContext: currentContext ?? this.currentContext,
      navigationHistory: navigationHistory ?? this.navigationHistory,
      lastNavigation: lastNavigation ?? this.lastNavigation,
    );
  }
}

