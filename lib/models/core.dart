class EmotionalCore {
  final String id;
  final String name;
  final String description;
  final double percentage;
  final String trend; // 'rising', 'stable', 'declining'
  final String color;
  final String iconPath;
  final String insight;
  final List<String> relatedCores;

  EmotionalCore({
    required this.id,
    required this.name,
    required this.description,
    required this.percentage,
    required this.trend,
    required this.color,
    required this.iconPath,
    required this.insight,
    required this.relatedCores,
  });

  factory EmotionalCore.fromJson(Map<String, dynamic> json) {
    return EmotionalCore(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      percentage: json['percentage'].toDouble(),
      trend: json['trend'],
      color: json['color'],
      iconPath: json['iconPath'],
      insight: json['insight'],
      relatedCores: List<String>.from(json['relatedCores']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'percentage': percentage,
      'trend': trend,
      'color': color,
      'iconPath': iconPath,
      'insight': insight,
      'relatedCores': relatedCores,
    };
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
