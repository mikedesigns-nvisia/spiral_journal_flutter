import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/constants/validation_constants.dart';

void main() {
  group('ValidationConstants', () {
    group('Mood Validation Data', () {
      test('should have non-empty valid moods list', () {
        expect(ValidationConstants.validMoods, isNotEmpty);
        expect(ValidationConstants.validMoods.length, greaterThan(10)); // Should have substantial mood options
      });

      test('should have all moods as lowercase strings', () {
        for (final mood in ValidationConstants.validMoods) {
          expect(mood, isA<String>());
          expect(mood, isNotEmpty);
          expect(mood, equals(mood.toLowerCase()));
        }
      });

      test('should have no duplicate moods', () {
        final uniqueMoods = ValidationConstants.validMoods.toSet();
        expect(uniqueMoods.length, equals(ValidationConstants.validMoods.length));
      });

      test('should categorize all moods correctly', () {
        final allCategorizedMoods = <String>{
          ...ValidationConstants.positiveMoods,
          ...ValidationConstants.neutralMoods,
          ...ValidationConstants.challengingMoods,
        };
        
        // Every valid mood should be in at least one category
        for (final mood in ValidationConstants.validMoods) {
          expect(allCategorizedMoods, contains(mood),
              reason: 'Mood "$mood" should be categorized');
        }
      });

      test('should have no overlap between mood categories', () {
        final positive = ValidationConstants.positiveMoods.toSet();
        final neutral = ValidationConstants.neutralMoods.toSet();
        final challenging = ValidationConstants.challengingMoods.toSet();
        
        expect(positive.intersection(neutral), isEmpty);
        expect(positive.intersection(challenging), isEmpty);
        expect(neutral.intersection(challenging), isEmpty);
      });

      test('should have high intensity moods as subset of valid moods', () {
        for (final mood in ValidationConstants.highIntensityMoods) {
          expect(ValidationConstants.validMoods, contains(mood));
        }
      });
    });

    group('Core Validation Data', () {
      test('should have non-empty valid core names list', () {
        expect(ValidationConstants.validCoreNames, isNotEmpty);
        expect(ValidationConstants.validCoreNames.length, equals(6)); // Should match expected core count
      });

      test('should have properly formatted core names', () {
        for (final coreName in ValidationConstants.validCoreNames) {
          expect(coreName, isA<String>());
          expect(coreName, isNotEmpty);
          // Core names should be title case
          expect(coreName[0], equals(coreName[0].toUpperCase()));
        }
      });

      test('should have no duplicate core names', () {
        final uniqueCores = ValidationConstants.validCoreNames.toSet();
        expect(uniqueCores.length, equals(ValidationConstants.validCoreNames.length));
      });

      test('should have valid trend values', () {
        expect(ValidationConstants.validCoreTrends, contains('rising'));
        expect(ValidationConstants.validCoreTrends, contains('stable'));
        expect(ValidationConstants.validCoreTrends, contains('declining'));
        expect(ValidationConstants.validCoreTrends.length, equals(3));
      });
    });

    group('Mood to Core Mapping', () {
      test('should map valid moods to valid cores', () {
        ValidationConstants.moodToCoreMapping.forEach((mood, core) {
          expect(ValidationConstants.validMoods, contains(mood),
              reason: 'Mapped mood "$mood" should be valid');
          expect(ValidationConstants.validCoreNames, contains(core),
              reason: 'Mapped core "$core" should be valid');
        });
      });

      test('should have multiple core mapping with valid data', () {
        ValidationConstants.moodToMultipleCoreMapping.forEach((mood, coreWeights) {
          expect(ValidationConstants.validMoods, contains(mood),
              reason: 'Multi-mapped mood "$mood" should be valid');
          
          coreWeights.forEach((core, weight) {
            expect(ValidationConstants.validCoreNames, contains(core),
                reason: 'Multi-mapped core "$core" should be valid');
            expect(weight, greaterThan(0));
            expect(weight, lessThanOrEqualTo(1.0)); // Weights should be fractional
          });
        });
      });

      test('should have consistent mood mappings', () {
        // Moods in multiple core mapping should also be in single core mapping or be valid moods
        for (final mood in ValidationConstants.moodToMultipleCoreMapping.keys) {
          expect(ValidationConstants.validMoods, contains(mood));
        }
      });
    });

    group('Analysis Constants', () {
      test('should have valid indicator words', () {
        expect(ValidationConstants.positiveIndicatorWords, isNotEmpty);
        expect(ValidationConstants.neutralIndicatorWords, isNotEmpty);
        expect(ValidationConstants.challengingIndicatorWords, isNotEmpty);
        
        // All indicator words should be lowercase
        for (final word in ValidationConstants.positiveIndicatorWords) {
          expect(word, equals(word.toLowerCase()));
        }
        for (final word in ValidationConstants.neutralIndicatorWords) {
          expect(word, equals(word.toLowerCase()));
        }
        for (final word in ValidationConstants.challengingIndicatorWords) {
          expect(word, equals(word.toLowerCase()));
        }
      });

      test('should have no overlap between indicator word categories', () {
        final positive = ValidationConstants.positiveIndicatorWords.toSet();
        final neutral = ValidationConstants.neutralIndicatorWords.toSet();
        final challenging = ValidationConstants.challengingIndicatorWords.toSet();
        
        expect(positive.intersection(neutral), isEmpty);
        expect(positive.intersection(challenging), isEmpty);
        expect(neutral.intersection(challenging), isEmpty);
      });
    });

    group('Date and Time Constants', () {
      test('should have all day names', () {
        expect(ValidationConstants.dayNames.length, equals(7));
        expect(ValidationConstants.dayNames, contains('Monday'));
        expect(ValidationConstants.dayNames, contains('Sunday'));
      });

      test('should have all month names', () {
        expect(ValidationConstants.monthNames.length, equals(12));
        expect(ValidationConstants.monthNames, contains('January'));
        expect(ValidationConstants.monthNames, contains('December'));
      });

      test('should have properly formatted day and month names', () {
        for (final day in ValidationConstants.dayNames) {
          expect(day[0], equals(day[0].toUpperCase()));
        }
        for (final month in ValidationConstants.monthNames) {
          expect(month[0], equals(month[0].toUpperCase()));
        }
      });
    });

    group('Validation Helper Methods', () {
      test('isValidMood should work correctly', () {
        // Test valid moods
        expect(ValidationConstants.isValidMood('happy'), isTrue);
        expect(ValidationConstants.isValidMood('HAPPY'), isTrue); // Case insensitive
        expect(ValidationConstants.isValidMood('Happy'), isTrue);
        
        // Test invalid moods
        expect(ValidationConstants.isValidMood('invalid'), isFalse);
        expect(ValidationConstants.isValidMood(''), isFalse);
      });

      test('isValidCoreName should work correctly', () {
        // Test valid cores
        expect(ValidationConstants.isValidCoreName('Optimism'), isTrue);
        expect(ValidationConstants.isValidCoreName('Resilience'), isTrue);
        
        // Test invalid cores
        expect(ValidationConstants.isValidCoreName('optimism'), isFalse); // Case sensitive
        expect(ValidationConstants.isValidCoreName('Invalid'), isFalse);
        expect(ValidationConstants.isValidCoreName(''), isFalse);
      });

      test('isValidTrend should work correctly', () {
        // Test valid trends
        expect(ValidationConstants.isValidTrend('rising'), isTrue);
        expect(ValidationConstants.isValidTrend('STABLE'), isTrue); // Case insensitive
        expect(ValidationConstants.isValidTrend('Declining'), isTrue);
        
        // Test invalid trends
        expect(ValidationConstants.isValidTrend('invalid'), isFalse);
        expect(ValidationConstants.isValidTrend(''), isFalse);
      });

      test('getPrimaryCoreForMood should work correctly', () {
        // Test mapped moods
        expect(ValidationConstants.getPrimaryCoreForMood('happy'), equals('Optimism'));
        expect(ValidationConstants.getPrimaryCoreForMood('HAPPY'), equals('Optimism')); // Case insensitive
        
        // Test unmapped moods
        expect(ValidationConstants.getPrimaryCoreForMood('invalid'), isNull);
        expect(ValidationConstants.getPrimaryCoreForMood(''), isNull);
      });

      test('mood category helpers should work correctly', () {
        // Test positive mood detection
        expect(ValidationConstants.isPositiveMood('happy'), isTrue);
        expect(ValidationConstants.isPositiveMood('HAPPY'), isTrue); // Case insensitive
        expect(ValidationConstants.isPositiveMood('sad'), isFalse);
        
        // Test challenging mood detection
        expect(ValidationConstants.isChallengingMood('sad'), isTrue);
        expect(ValidationConstants.isChallengingMood('SAD'), isTrue); // Case insensitive
        expect(ValidationConstants.isChallengingMood('happy'), isFalse);
        
        // Test high intensity mood detection
        expect(ValidationConstants.isHighIntensityMood('excited'), isTrue);
        expect(ValidationConstants.isHighIntensityMood('EXCITED'), isTrue); // Case insensitive
        expect(ValidationConstants.isHighIntensityMood('content'), isFalse);
      });
    });

    group('Data Consistency', () {
      test('should maintain consistency across all mood-related data structures', () {
        // All moods in categories should be in valid moods
        for (final mood in ValidationConstants.positiveMoods) {
          expect(ValidationConstants.validMoods, contains(mood));
        }
        for (final mood in ValidationConstants.neutralMoods) {
          expect(ValidationConstants.validMoods, contains(mood));
        }
        for (final mood in ValidationConstants.challengingMoods) {
          expect(ValidationConstants.validMoods, contains(mood));
        }
        for (final mood in ValidationConstants.highIntensityMoods) {
          expect(ValidationConstants.validMoods, contains(mood));
        }
      });

      test('should have indicator words that align with mood categories', () {
        // Some positive indicator words should match positive moods
        final positiveOverlap = ValidationConstants.positiveIndicatorWords
            .where((word) => ValidationConstants.positiveMoods.contains(word))
            .toList();
        expect(positiveOverlap, isNotEmpty);
        
        // Some challenging indicator words should match challenging moods
        final challengingOverlap = ValidationConstants.challengingIndicatorWords
            .where((word) => ValidationConstants.challengingMoods.contains(word))
            .toList();
        expect(challengingOverlap, isNotEmpty);
      });
    });
  });
}