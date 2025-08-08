class CoreResonanceData {
  final double resonanceStrength;
  final String depthIndicator;
  final List<String> transitionSignals;
  final String supportingEvidence;
  
  const CoreResonanceData({
    required this.resonanceStrength,
    required this.depthIndicator,
    required this.transitionSignals,
    required this.supportingEvidence,
  });
  
  factory CoreResonanceData.fromJson(Map<String, dynamic> json) {
    return CoreResonanceData(
      resonanceStrength: (json['resonance_strength'] ?? json['resonanceStrength'] ?? 0.0).toDouble(),
      depthIndicator: json['depth_indicator'] ?? json['depthIndicator'] ?? 'dormant',
      transitionSignals: List<String>.from(json['transition_signals'] ?? json['transitionSignals'] ?? []),
      supportingEvidence: json['supporting_evidence'] ?? json['supportingEvidence'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'resonance_strength': resonanceStrength,
      'depth_indicator': depthIndicator,
      'transition_signals': transitionSignals,
      'supporting_evidence': supportingEvidence,
    };
  }
  
  CoreResonanceData copyWith({
    double? resonanceStrength,
    String? depthIndicator,
    List<String>? transitionSignals,
    String? supportingEvidence,
  }) {
    return CoreResonanceData(
      resonanceStrength: resonanceStrength ?? this.resonanceStrength,
      depthIndicator: depthIndicator ?? this.depthIndicator,
      transitionSignals: transitionSignals ?? this.transitionSignals,
      supportingEvidence: supportingEvidence ?? this.supportingEvidence,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreResonanceData) return false;
    return resonanceStrength == other.resonanceStrength &&
           depthIndicator == other.depthIndicator &&
           _listEquals(transitionSignals, other.transitionSignals) &&
           supportingEvidence == other.supportingEvidence;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      resonanceStrength,
      depthIndicator,
      transitionSignals,
      supportingEvidence,
    );
  }
  
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}