class JournalEntry {
  final String id;
  final DateTime date;
  final String content;
  final List<String> mood;
  final List<String> tags;

  JournalEntry({
    required this.id,
    required this.date,
    required this.content,
    required this.mood,
    this.tags = const [],
  });

  String get dayOfWeek {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  // Keep backward compatibility
  List<String> get moods => mood;

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      content: json['content'],
      mood: List<String>.from(json['mood'] ?? json['moods'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'content': content,
      'mood': mood,
      'tags': tags,
      'dayOfWeek': dayOfWeek,
    };
  }
}

class MonthlySummary {
  final String month;
  final int year;
  final List<String> dominantMoods;
  final List<double> emotionalJourneyData;
  final String insight;
  final int entryCount;

  MonthlySummary({
    required this.month,
    required this.year,
    required this.dominantMoods,
    required this.emotionalJourneyData,
    required this.insight,
    required this.entryCount,
  });
}
