import 'package:flutter_test/flutter_test.dart';

/// Utility class for verifying test coverage
class TestCoverageVerifier {
  /// Map of requirements to test coverage status
  static final Map<String, bool> _requirementsCoverage = {};

  /// Mark a requirement as covered by tests
  static void markRequirementCovered(String requirementId) {
    _requirementsCoverage[requirementId] = true;
  }

  /// Check if a requirement is covered by tests
  static bool isRequirementCovered(String requirementId) {
    return _requirementsCoverage[requirementId] ?? false;
  }

  /// Get all covered requirements
  static List<String> getCoveredRequirements() {
    return _requirementsCoverage.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get all uncovered requirements from a list of required requirements
  static List<String> getUncoveredRequirements(List<String> requiredRequirements) {
    return requiredRequirements
        .where((req) => !isRequirementCovered(req))
        .toList();
  }

  /// Verify that all required requirements are covered
  static void verifyRequirementsCoverage(List<String> requiredRequirements) {
    final uncoveredRequirements = getUncoveredRequirements(requiredRequirements);
    
    if (uncoveredRequirements.isNotEmpty) {
      fail('The following requirements are not covered by tests: ${uncoveredRequirements.join(', ')}');
    }
  }

  /// Reset the coverage tracking
  static void reset() {
    _requirementsCoverage.clear();
  }
}