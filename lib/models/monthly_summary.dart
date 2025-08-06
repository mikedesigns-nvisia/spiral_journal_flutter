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
}