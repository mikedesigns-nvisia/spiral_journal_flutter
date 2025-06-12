class JournalEntry {
  final String id;
  final DateTime date;
  final String content;
  final List<String> moods;
  final String dayOfWeek;

  JournalEntry({
    required this.id,
    required this.date,
    required this.content,
    required this.moods,
    required this.dayOfWeek,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      content: json['content'],
      moods: List<String>.from(json['moods']),
      dayOfWeek: json['dayOfWeek'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'content': content,
      'moods': moods,
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
