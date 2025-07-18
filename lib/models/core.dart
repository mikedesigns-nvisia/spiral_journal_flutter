class EmotionalCore {
  final String id;
  final String name;
  final String description;
  final double currentLevel; // 0.0 to 1.0 (replaces percentage)
  final double previousLevel;
  final DateTime lastUpdated;
  final String trend; // 'rising', 'stable', 'declining'
  final String color;
  final String iconPath;
  final String insight;
  final List<String> relatedCores;
  final List<CoreMilestone> milestones;
  final List<CoreInsight> recentInsights;

  EmotionalCore({
    required this.id,
    required this.name,
    required this.description,
    required this.currentLevel,
    required this.previousLevel,
    required this.lastUpdated,
    required this.trend,
    required this.color,
    required this.iconPath,
    required this.insight,
    required this.relatedCores,
    this.milestones = const [],
    this.recentInsights = const [],
  });

  // Backward compatibility getter
  double get percentage => currentLevel * 100;

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
      'trend': trend,
      'color': color,
      'iconPath': iconPath,
      'insight': insight,
      'relatedCores': relatedCores,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'recentInsights': recentInsights.map((i) => i.toJson()).toList(),
      // Backward compatibility
      'percentage': percentage,
    };
  }

  EmotionalCore copyWith({
    String? id,
    String? name,
    String? description,
    double? currentLevel,
    double? previousLevel,
    DateTime? lastUpdated,
    String? trend,
    String? color,
    String? iconPath,
    String? insight,
    List<String>? relatedCores,
    List<CoreMilestone>? milestones,
    List<CoreInsight>? recentInsights,
  }) {
    return EmotionalCore(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      currentLevel: currentLevel ?? this.currentLevel,
      previousLevel: previousLevel ?? this.previousLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      trend: trend ?? this.trend,
      color: color ?? this.color,
      iconPath: iconPath ?? this.iconPath,
      insight: insight ?? this.insight,
      relatedCores: relatedCores ?? this.relatedCores,
      milestones: milestones ?? this.milestones,
      recentInsights: recentInsights ?? this.recentInsights,
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
  final String category;
  final String title;
  final String description;
  final String type; // 'growth', 'recurring', 'awareness'

  EmotionalPattern({
    required this.category,
    required this.title,
    required this.description,
    required this.type,
  });
}
