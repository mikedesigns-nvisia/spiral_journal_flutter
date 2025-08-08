/// Stub class for JournalEmotionalPattern to maintain compatibility
/// This class is kept as a stub since the actual AI analysis has been removed
class JournalEmotionalPattern {
  final String category;
  final String title;
  final String description;
  final String type;

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
}