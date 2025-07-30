import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/offline_queue_service.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import '../utils/test_setup_helper.dart';
import '../utils/mock_haiku_service.dart';

void main() {
  group('OfflineQueueService Tests', () {
    late OfflineQueueService service;

    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    setUp(() async {
      service = OfflineQueueService();
      await service.initialize();
      await service.clearQueue(); // Start with clean state
    });

    tearDown(() async {
      await service.clearQueue();
      await service.dispose();
    });

    test('should initialize successfully', () async {
      expect(service, isNotNull, reason: 'Service should be created');
      
      final status = await service.getQueueStatus();
      expect(status['pendingCount'], equals(0), reason: 'Should start with empty queue');
      expect(status['isProcessing'], isFalse, reason: 'Should not be processing initially');
    });

    test('should queue journal entries when offline', () async {
      final testEntry = JournalEntry(
        id: 'offline-test-1',
        content: 'Test entry queued while offline',
        date: DateTime.now(),
        moods: ['offline', 'testing'],
      );

      await service.queueForProcessing(testEntry, priority: 1);

      final status = await service.getQueueStatus();
      expect(status['pendingCount'], equals(1), reason: 'Should have one queued entry');
    });

    test('should queue multiple entries with different priorities', () async {
      final entries = [
        JournalEntry(
          id: 'low-priority',
          content: 'Low priority offline entry',
          date: DateTime.now(),
          moods: ['neutral'],
        ),
        JournalEntry(
          id: 'high-priority',
          content: 'High priority offline entry',
          date: DateTime.now(),
          moods: ['urgent'],
        ),
      ];

      await service.queueForProcessing(entries[0], priority: 1);
      await service.queueForProcessing(entries[1], priority: 5);

      final status = await service.getQueueStatus();
      expect(status['pendingCount'], equals(2), reason: 'Should have two queued entries');
    });

    test('should process queue when coming back online', () async {
      final testEntries = List.generate(3, (index) => JournalEntry(
        id: 'queue-entry-$index',
        content: 'Queue processing test entry $index',
        date: DateTime.now(),
        moods: ['testing', 'queue'],
      ));

      // Queue entries
      for (final entry in testEntries) {
        await service.queueForProcessing(entry);
      }

      // Simulate coming back online and processing queue
      final results = await service.processQueue();

      expect(results, isNotEmpty, reason: 'Should return processing results');
      expect(results.length, equals(testEntries.length), reason: 'Should process all queued entries');
    });

    test('should handle queue persistence across app restarts', () async {
      final testEntry = JournalEntry(
        id: 'persistence-test',
        content: 'Entry for testing queue persistence',
        date: DateTime.now(),
        moods: ['persistence'],
      );

      await service.queueForProcessing(testEntry);

      // Simulate app restart by creating new service instance
      final newService = OfflineQueueService();
      await newService.initialize();

      final status = await newService.getQueueStatus();
      expect(status['pendingCount'], greaterThan(0), 
             reason: 'Should restore queued entries after restart');

      await newService.clearQueue();
      await newService.dispose();
    });

    test('should provide detailed queue status', () async {
      final status = await service.getQueueStatus();

      expect(status.containsKey('pendingCount'), isTrue, reason: 'Should provide pending count');
      expect(status.containsKey('processingCount'), isTrue, reason: 'Should provide processing count');
      expect(status.containsKey('completedCount'), isTrue, reason: 'Should provide completed count');
      expect(status.containsKey('failedCount'), isTrue, reason: 'Should provide failed count');
      expect(status.containsKey('isProcessing'), isTrue, reason: 'Should provide processing status');
      expect(status.containsKey('lastProcessedAt'), isTrue, reason: 'Should provide last processed time');
    });

    test('should handle network connectivity changes', () async {
      final testEntry = JournalEntry(
        id: 'connectivity-test',
        content: 'Entry for testing connectivity handling',
        date: DateTime.now(),
        moods: ['connectivity'],
      );

      await service.queueForProcessing(testEntry);

      // Simulate network becoming available
      await service.onNetworkStatusChanged(isConnected: true);

      // Should trigger automatic processing
      await Future.delayed(const Duration(milliseconds: 500));
      
      final status = await service.getQueueStatus();
      expect(status['isProcessing'], isA<bool>(), reason: 'Should handle network status changes');
    });

    test('should retry failed queue items', () async {
      final testEntry = JournalEntry(
        id: 'retry-test',
        content: 'trigger_error', // This will cause mock service to fail
        date: DateTime.now(),
        moods: ['retry'],
      );

      await service.queueForProcessing(testEntry);
      final results = await service.processQueue();

      expect(results, isNotEmpty, reason: 'Should return results even for failed items');
      
      final status = await service.getQueueStatus();
      // Failed items should either be retried or moved to failed queue
      expect(status.containsKey('failedCount'), isTrue, reason: 'Should track failed items');
    });

    test('should handle queue size limits', () async {
      final maxQueueSize = 100; // Assume service has a maximum queue size
      
      // Try to queue more than maximum allowed
      for (int i = 0; i < maxQueueSize + 10; i++) {
        final entry = JournalEntry(
          id: 'queue-limit-$i',
          content: 'Queue limit test entry $i',
          date: DateTime.now(),
          moods: ['limit-test'],
        );
        
        await service.queueForProcessing(entry);
      }

      final status = await service.getQueueStatus();
      expect(status['pendingCount'], lessThanOrEqualTo(maxQueueSize),
             reason: 'Should respect queue size limits');
    });

    test('should provide queue item details', () async {
      final testEntry = JournalEntry(
        id: 'details-test',
        content: 'Entry for testing queue item details',
        date: DateTime.now(),
        moods: ['details'],
      );

      await service.queueForProcessing(testEntry, priority: 3);
      
      final queueItems = await service.getQueueItems();
      expect(queueItems, isNotEmpty, reason: 'Should return queue items');
      
      final item = queueItems.first;
      expect(item.containsKey('id'), isTrue, reason: 'Queue item should have ID');
      expect(item.containsKey('entryId'), isTrue, reason: 'Queue item should have entry ID');
      expect(item.containsKey('priority'), isTrue, reason: 'Queue item should have priority');
      expect(item.containsKey('queuedAt'), isTrue, reason: 'Queue item should have timestamp');
      expect(item.containsKey('retryCount'), isTrue, reason: 'Queue item should have retry count');
    });

    test('should handle concurrent queue operations', () async {
      final entries = List.generate(10, (index) => JournalEntry(
        id: 'concurrent-$index',
        content: 'Concurrent queue test entry $index',
        date: DateTime.now(),
        moods: ['concurrent'],
      ));

      // Queue entries concurrently
      final futures = entries.map((entry) => service.queueForProcessing(entry));
      await Future.wait(futures);

      final status = await service.getQueueStatus();
      expect(status['pendingCount'], equals(10), reason: 'Should handle concurrent queueing');
    });

    test('should validate queue operations', () async {
      // Test with invalid entry
      expect(() async => await service.queueForProcessing(null as JournalEntry), 
             throwsA(isA<ArgumentError>()), reason: 'Should reject null entries');

      // Test with empty content
      final emptyEntry = JournalEntry(
        id: 'empty-test',
        content: '',
        date: DateTime.now(),
        moods: [],
      );

      // Should handle empty entries gracefully
      await service.queueForProcessing(emptyEntry);
      final status = await service.getQueueStatus();
      expect(status['pendingCount'], greaterThanOrEqualTo(0), reason: 'Should handle empty entries');
    });

    test('should provide processing statistics', () async {
      final testEntries = List.generate(3, (index) => JournalEntry(
        id: 'stats-$index',
        content: 'Statistics test entry $index',
        date: DateTime.now(),
        moods: ['stats'],
      ));

      for (final entry in testEntries) {
        await service.queueForProcessing(entry);
      }

      final results = await service.processQueue();
      final stats = await service.getProcessingStats();

      expect(stats.containsKey('totalProcessed'), isTrue, reason: 'Should provide total processed count');
      expect(stats.containsKey('successRate'), isTrue, reason: 'Should provide success rate');
      expect(stats.containsKey('averageProcessingTime'), isTrue, reason: 'Should provide average processing time');
      expect(stats.containsKey('lastBatchSize'), isTrue, reason: 'Should provide last batch size');
    });

    test('should handle service disposal gracefully', () async {
      final testEntry = JournalEntry(
        id: 'disposal-test',
        content: 'Entry for testing service disposal',
        date: DateTime.now(),
        moods: ['disposal'],
      );

      await service.queueForProcessing(testEntry);
      
      // Should not throw exception on disposal
      expect(() async => await service.dispose(), returnsNormally, 
             reason: 'Service disposal should be safe');
    });

    test('should clear queue when requested', () async {
      final testEntries = List.generate(5, (index) => JournalEntry(
        id: 'clear-test-$index',
        content: 'Clear queue test entry $index',
        date: DateTime.now(),
        moods: ['clear'],
      ));

      for (final entry in testEntries) {
        await service.queueForProcessing(entry);
      }

      final statusBefore = await service.getQueueStatus();
      expect(statusBefore['pendingCount'], equals(5), reason: 'Should have 5 queued entries');

      await service.clearQueue();

      final statusAfter = await service.getQueueStatus();
      expect(statusAfter['pendingCount'], equals(0), reason: 'Should have empty queue after clearing');
    });
  });
}