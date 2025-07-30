import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/haiku_batch_processor.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import '../utils/test_setup_helper.dart';
import '../utils/mock_haiku_service.dart';

void main() {
  group('HaikuBatchProcessor Tests', () {
    late HaikuBatchProcessor processor;

    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    setUp(() async {
      processor = HaikuBatchProcessor();
      await processor.clearAllData(); // Start with clean state
      await processor.initialize();
    });

    tearDown(() async {
      await processor.clearAllData();
      processor.dispose();
    });

    test('should initialize successfully', () async {
      expect(processor, isNotNull, reason: 'Processor should be created');
      
      final status = processor.getQueueStatus();
      expect(status.pendingCount, equals(0), reason: 'Should start with empty queue');
      expect(status.processingCount, equals(0), reason: 'Should start with no processing items');
      expect(status.isProcessing, isFalse, reason: 'Should not be processing initially');
    });

    test('should queue journal entries', () async {
      final testEntry = JournalEntry(
        id: 'test-entry-1',
        content: 'Today was a great day for learning and growth',
        date: DateTime.now(),
        moods: ['happy', 'grateful'],
      );

      await processor.queueEntry(testEntry);

      final status = processor.getQueueStatus();
      expect(status.pendingCount, equals(1), reason: 'Should have one queued entry');
    });

    test('should queue multiple entries with priority ordering', () async {
      final entries = [
        JournalEntry(
          id: 'low-priority',
          content: 'Low priority entry',
          date: DateTime.now(),
          moods: ['neutral'],
        ),
        JournalEntry(
          id: 'high-priority',
          content: 'High priority entry',
          date: DateTime.now(),
          moods: ['important'],
        ),
      ];

      await processor.queueEntry(entries[0], priority: 1);
      await processor.queueEntry(entries[1], priority: 5);

      final status = processor.getQueueStatus();
      expect(status.pendingCount, equals(2), reason: 'Should have two queued entries');
    });

    test('should process batch when queue reaches limit', () async {
      // In debug mode, processor processes when queue reaches 3 items
      final entries = List.generate(3, (index) => JournalEntry(
        id: 'batch-entry-$index',
        content: 'Batch test entry $index with meaningful content for processing',
        date: DateTime.now(),
        moods: ['reflective', 'growth'],
      ));

      for (final entry in entries) {
        await processor.queueEntry(entry);
      }

      // Wait for processing to complete
      await Future.delayed(const Duration(seconds: 3));

      final results = processor.getCompletedResults();
      expect(results, isNotEmpty, reason: 'Should have completed batch results');
    });

    test('should handle force processing', () async {
      final testEntry = JournalEntry(
        id: 'force-test',
        content: 'Entry for force processing test',
        date: DateTime.now(),
        moods: ['testing'],
      );

      await processor.queueEntry(testEntry);

      final results = await processor.forceProcessQueue();
      
      expect(results, isNotEmpty, reason: 'Force processing should return results');
      expect(results.first.itemCount, equals(1), reason: 'Should process one item');
    });

    test('should provide queue status information', () async {
      final status = processor.getQueueStatus();
      
      expect(status.pendingCount, isA<int>(), reason: 'Should provide pending count');
      expect(status.processingCount, isA<int>(), reason: 'Should provide processing count');
      expect(status.completedBatchesCount, isA<int>(), reason: 'Should provide completed count');
      expect(status.nextProcessingTime, isA<DateTime>(), reason: 'Should provide next processing time');
      expect(status.isProcessing, isA<bool>(), reason: 'Should provide processing status');
    });

    test('should handle batch results correctly', () async {
      final testEntries = List.generate(2, (index) => JournalEntry(
        id: 'result-test-$index',
        content: 'Test entry $index for result validation',
        date: DateTime.now(),
        moods: ['testing', 'validation'],
      ));

      for (final entry in testEntries) {
        await processor.queueEntry(entry);
      }

      final results = await processor.forceProcessQueue();
      expect(results, isNotEmpty, reason: 'Should have batch results');

      final batchResult = results.first;
      expect(batchResult.batchId, isNotEmpty, reason: 'Batch should have ID');
      expect(batchResult.processedAt, isA<DateTime>(), reason: 'Batch should have timestamp');
      expect(batchResult.itemCount, equals(2), reason: 'Batch should process 2 items');
      expect(batchResult.itemResults, hasLength(2), reason: 'Should have 2 item results');
      expect(batchResult.processingTimeMs, greaterThan(0), reason: 'Should track processing time');
    });

    test('should handle empty queue processing', () async {
      final results = await processor.forceProcessQueue();
      expect(results, isEmpty, reason: 'Empty queue should return no results');
    });

    test('should calculate processing costs', () async {
      final testEntry = JournalEntry(
        id: 'cost-test',
        content: 'This is a test entry for cost calculation with sufficient content to estimate token usage accurately',
        date: DateTime.now(),
        moods: ['cost', 'testing'],
      );

      await processor.queueEntry(testEntry);
      final results = await processor.forceProcessQueue();
      
      expect(results, isNotEmpty, reason: 'Should have results for cost calculation');
      expect(results.first.totalCost, greaterThan(0), reason: 'Should calculate positive cost');
    });

    test('should handle concurrent processing safely', () async {
      final entries = List.generate(5, (index) => JournalEntry(
        id: 'concurrent-$index',
        content: 'Concurrent processing test entry $index',
        date: DateTime.now(),
        moods: ['concurrent', 'testing'],
      ));

      // Queue entries concurrently
      final futures = entries.map((entry) => processor.queueEntry(entry));
      await Future.wait(futures);

      final status = processor.getQueueStatus();
      expect(status.pendingCount, greaterThan(0), reason: 'Should handle concurrent queueing');
    });

    test('should persist and restore queue data', () async {
      final testEntry = JournalEntry(
        id: 'persistence-test',
        content: 'Entry for testing persistence',
        date: DateTime.now(),
        moods: ['persistence'],
      );

      await processor.queueEntry(testEntry);
      
      // Create new processor instance to test persistence
      final newProcessor = HaikuBatchProcessor();
      await newProcessor.initialize();
      
      final status = newProcessor.getQueueStatus();
      expect(status.pendingCount, greaterThan(0), reason: 'Should restore queued entries after restart');
      
      await newProcessor.clearAllData();
    });

    test('should handle batch item results correctly', () async {
      final testEntry = JournalEntry(
        id: 'item-result-test',
        content: 'Entry for testing individual item results',
        date: DateTime.now(),
        moods: ['item', 'result'],
      );

      await processor.queueEntry(testEntry);
      final results = await processor.forceProcessQueue();
      
      expect(results, isNotEmpty, reason: 'Should have batch results');
      
      final itemResult = results.first.itemResults.first;
      expect(itemResult.queueItemId, isNotEmpty, reason: 'Item result should have queue ID');
      expect(itemResult.entryId, equals(testEntry.id), reason: 'Item result should match entry ID');
      expect(itemResult.success, isA<bool>(), reason: 'Item result should have success status');
      expect(itemResult.processingTimeMs, greaterThanOrEqualTo(0), reason: 'Should track item processing time');
    });

    test('should handle queue status time calculations', () async {
      final status = processor.getQueueStatus();
      final timeUntilNext = status.timeUntilNextProcessing;
      
      expect(timeUntilNext.inHours, greaterThanOrEqualTo(0), reason: 'Time until next processing should be valid');
      expect(timeUntilNext.inHours, lessThan(25), reason: 'Time until next processing should be within 24 hours');
    });

    test('should provide meaningful batch statistics', () async {
      final entries = List.generate(3, (index) => JournalEntry(
        id: 'stats-$index',
        content: 'Statistical analysis test entry $index',
        date: DateTime.now(),
        moods: ['stats', 'analysis'],
      ));

      for (final entry in entries) {
        await processor.queueEntry(entry);
      }

      final results = await processor.forceProcessQueue();
      expect(results, isNotEmpty, reason: 'Should have results for statistics');

      final batch = results.first;
      expect(batch.successCount + batch.failureCount, equals(batch.itemCount),
             reason: 'Success and failure counts should sum to total items');
      expect(batch.successRate, greaterThanOrEqualTo(0), reason: 'Success rate should be non-negative');
      expect(batch.successRate, lessThanOrEqualTo(1), reason: 'Success rate should not exceed 1.0');
    });

    test('should handle disposal correctly', () async {
      // Should not throw exception on disposal
      expect(() => processor.dispose(), returnsNormally, reason: 'Disposal should be safe');
    });
  });
}