import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/insight_template_service.dart';
import 'package:spiral_journal/models/insight_template.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('InsightTemplateService Tests', () {
    late InsightTemplateService service;

    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    setUp(() {
      service = InsightTemplateService();
    });

    test('should initialize with default templates', () async {
      service.initialize();
      
      final templates = service.getAllTemplates();
      expect(templates, isNotEmpty, reason: 'Should have default templates after initialization');
      
      final categories = service.getCategories();
      expect(categories, isNotEmpty, reason: 'Should have template categories');
    });

    test('should get templates by category', () async {
      service.initialize();
      
      final categories = service.getCategories();
      expect(categories, isNotEmpty, reason: 'Should have categories');
      
      final firstCategory = categories.first;
      final categoryTemplates = service.getTemplatesByCategory(firstCategory.id);
      
      expect(categoryTemplates, isNotEmpty, reason: 'Category should have templates');
      expect(categoryTemplates.every((t) => t.category.id == firstCategory.id), isTrue,
             reason: 'All templates should belong to the requested category');
    });

    test('should get templates by priority', () async {
      service.initialize();
      
      final highPriorityTemplates = service.getTemplatesByPriority(TemplatePriority.high);
      final criticalTemplates = service.getTemplatesByPriority(TemplatePriority.critical);
      
      expect(highPriorityTemplates.every((t) => t.priority == TemplatePriority.high), isTrue,
             reason: 'Should only return high priority templates');
      expect(criticalTemplates.every((t) => t.priority == TemplatePriority.critical), isTrue,
             reason: 'Should only return critical priority templates');
    });

    test('should select templates for journal entry', () async {
      service.initialize();
      
      final testEntry = JournalEntry(
        id: 'test-entry',
        content: 'Today I felt grateful and learned something new about myself',
        date: DateTime.now(),
        moods: ['grateful', 'reflective'],
      );
      
      final selections = await service.selectTemplatesForEntry(testEntry);
      
      expect(selections, isNotEmpty, reason: 'Should select templates for valid entry');
      expect(selections.length, lessThanOrEqualTo(5), reason: 'Should not exceed maximum template selections');
      
      for (final selection in selections) {
        expect(selection.score, greaterThan(0), reason: 'Selection score should be positive');
        expect(selection.score, lessThanOrEqualTo(10), reason: 'Selection score should not exceed maximum');
        expect(selection.generatedInsight, isNotEmpty, reason: 'Should generate insight text');
      }
    });

    test('should handle empty journal entry', () async {
      service.initialize();
      
      final emptyEntry = JournalEntry(
        id: 'empty-entry',
        content: '',
        date: DateTime.now(),
        moods: [],
      );
      
      final selections = await service.selectTemplatesForEntry(emptyEntry);
      
      expect(selections, isEmpty, reason: 'Should not select templates for empty entry');
    });

    test('should generate insights with proper content', () async {
      service.initialize();
      
      final testEntry = JournalEntry(
        id: 'test-entry',
        content: 'I overcame a difficult challenge today and feel proud of my growth',
        date: DateTime.now(),
        moods: ['proud', 'accomplished'],
      );
      
      final selections = await service.selectTemplatesForEntry(testEntry);
      
      expect(selections, isNotEmpty, reason: 'Should generate insights for meaningful entry');
      
      for (final selection in selections) {
        expect(selection.generatedInsight.length, greaterThan(10), 
               reason: 'Generated insight should have meaningful content');
        expect(selection.generatedInsight.length, lessThan(200), 
               reason: 'Generated insight should be concise');
        expect(selection.generatedInsight, contains(RegExp(r'\w+')), 
               reason: 'Generated insight should contain actual words');
      }
    });

    test('should handle different mood combinations', () async {
      service.initialize();
      
      final moodTestCases = [
        ['happy', 'grateful'],
        ['sad', 'reflective'],
        ['anxious', 'worried'],
        ['excited', 'optimistic'],
        ['calm', 'peaceful'],
      ];
      
      for (final moods in moodTestCases) {
        final testEntry = JournalEntry(
          id: 'mood-test-${moods.join('-')}',
          content: 'Today I felt ${moods.join(' and ')} about my experiences',
          date: DateTime.now(),
          moods: moods,
        );
        
        final selections = await service.selectTemplatesForEntry(testEntry);
        
        // Should handle all mood combinations gracefully
        expect(() => selections, isNotNull, reason: 'Should handle moods: ${moods.join(', ')}');
      }
    });

    test('should validate template requirements', () async {
      service.initialize();
      
      final templates = service.getAllTemplates();
      
      for (final template in templates) {
        expect(template.id, isNotEmpty, reason: 'Template ID should not be empty');
        expect(template.title, isNotEmpty, reason: 'Template title should not be empty');
        expect(template.promptTemplate, isNotEmpty, reason: 'Template prompt should not be empty');
        expect(template.tags, isNotEmpty, reason: 'Template should have tags');
        expect(template.category, isNotNull, reason: 'Template should have a category');
        expect(template.priority, isNotNull, reason: 'Template should have priority');
        expect(template.animationType, isNotNull, reason: 'Template should have animation type');
      }
    });

    test('should handle template scoring correctly', () async {
      service.initialize();
      
      final highRelevanceEntry = JournalEntry(
        id: 'high-relevance',
        content: 'I had a breakthrough moment today where I realized I have been growing so much. I feel incredibly grateful for this journey of self-discovery and personal development.',
        date: DateTime.now(),
        moods: ['grateful', 'enlightened', 'proud'],
      );
      
      final lowRelevanceEntry = JournalEntry(
        id: 'low-relevance',
        content: 'Went to the store.',
        date: DateTime.now(),
        moods: ['neutral'],
      );
      
      final highSelections = await service.selectTemplatesForEntry(highRelevanceEntry);
      final lowSelections = await service.selectTemplatesForEntry(lowRelevanceEntry);
      
      if (highSelections.isNotEmpty && lowSelections.isNotEmpty) {
        final avgHighScore = highSelections.map((s) => s.score).reduce((a, b) => a + b) / highSelections.length;
        final avgLowScore = lowSelections.map((s) => s.score).reduce((a, b) => a + b) / lowSelections.length;
        
        expect(avgHighScore, greaterThan(avgLowScore), 
               reason: 'High relevance entry should score higher than low relevance entry');
      }
    });

    test('should filter templates by content length', () async {
      service.initialize();
      
      final shortEntry = JournalEntry(
        id: 'short',
        content: 'Good day.',
        date: DateTime.now(),
        moods: ['happy'],
      );
      
      final longEntry = JournalEntry(
        id: 'long',
        content: 'Today was an incredible day filled with so many meaningful experiences. I started the morning with meditation and reflection, then spent quality time with loved ones. I tackled some challenging work projects and felt a real sense of accomplishment. Throughout the day I noticed myself practicing gratitude and mindfulness. I ended the evening with reading and journaling, feeling grateful for all the growth and connections in my life.',
        date: DateTime.now(),
        moods: ['grateful', 'accomplished', 'peaceful'],
      );
      
      final shortSelections = await service.selectTemplatesForEntry(shortEntry);
      final longSelections = await service.selectTemplatesForEntry(longEntry);
      
      expect(longSelections.length, greaterThanOrEqualTo(shortSelections.length),
             reason: 'Longer entries should typically generate more template selections');
    });

    test('should handle template caching', () async {
      service.initialize();
      
      final startTime = DateTime.now();
      final templates1 = service.getAllTemplates();
      final time1 = DateTime.now().difference(startTime);
      
      final startTime2 = DateTime.now();
      final templates2 = service.getAllTemplates();
      final time2 = DateTime.now().difference(startTime2);
      
      expect(templates1.length, equals(templates2.length), 
             reason: 'Cached templates should be identical');
      expect(time2.inMicroseconds, lessThan(time1.inMicroseconds),
             reason: 'Second call should be faster due to caching');
    });

    test('should generate diverse insights for similar entries', () async {
      service.initialize();
      
      final entries = List.generate(3, (index) => JournalEntry(
        id: 'similar-$index',
        content: 'Today I felt grateful for my personal growth and learning experiences',
        date: DateTime.now(),
        moods: ['grateful', 'reflective'],
      ));
      
      final allSelections = <TemplateSelection>[];
      for (final entry in entries) {
        final selections = await service.selectTemplatesForEntry(entry);
        allSelections.addAll(selections);
      }
      
      // Check for insight diversity
      final uniqueInsights = allSelections.map((s) => s.generatedInsight).toSet();
      expect(uniqueInsights.length, greaterThan(1),
             reason: 'Should generate diverse insights even for similar entries');
    });

    test('should respect maximum template limit', () async {
      service.initialize();
      
      final comprehensiveEntry = JournalEntry(
        id: 'comprehensive',
        content: 'Today I experienced gratitude, growth, creativity, social connection, resilience, optimism, and self-awareness all at once. It was a transformative day of learning and reflection.',
        date: DateTime.now(),
        moods: ['grateful', 'creative', 'social', 'resilient', 'optimistic', 'reflective'],
      );
      
      final selections = await service.selectTemplatesForEntry(comprehensiveEntry);
      
      expect(selections.length, lessThanOrEqualTo(5),
             reason: 'Should not exceed maximum template selection limit');
    });

    test('should handle template validation rules', () async {
      service.initialize();
      
      final templates = service.getAllTemplates();
      final templatesWithRules = templates.where((t) => t.validationRules.isNotEmpty).toList();
      
      if (templatesWithRules.isNotEmpty) {
        final testEntry = JournalEntry(
          id: 'validation-test',
          content: 'Test entry for validation',
          date: DateTime.now(),
          moods: ['neutral'],
        );
        
        // Should not throw exception when processing templates with validation rules
        expect(() async => await service.selectTemplatesForEntry(testEntry), 
               returnsNormally, reason: 'Should handle validation rules gracefully');
      }
    });
  });
}