import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/core_navigation_context_service.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('CoreNavigationContextService Unit Tests', () {
    late CoreNavigationContextService service;
    late TestSetupHelper testHelper;

    setUp(() async {
      testHelper = TestSetupHelper();
      await testHelper.setUp();
      
      service = CoreNavigationContextService();
    });

    tearDown(() async {
      service.dispose();
      await testHelper.tearDown();
    });

    group('Context Creation', () {
      test('should create basic navigation context', () {
        final context = service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'core_tap',
          targetCoreId: 'optimism',
        );

        expect(context.sourceScreen, equals('journal'));
        expect(context.triggeredBy, equals('core_tap'));
        expect(context.targetCoreId, equals('optimism'));
        expect(context.timestamp, isNotNull);
        expect(context.additionalData, isEmpty);
      });

      test('should create context with additional data', () {
        final additionalData = {
          'showJournalConnection': true,
          'highlightRecentChanges': true,
        };

        final context = service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'core_tap',
          targetCoreId: 'resilience',
          additionalData: additionalData,
        );

        expect(context.additionalData, equals(additionalData));
      });

      test('should create context with related journal entry', () {
        final journalEntry = JournalEntry(
          id: 'test_entry',
          userId: 'test_user',
          content: 'Test content',
          date: DateTime.now(),
          moods: ['happy'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final context = service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'ai_analysis',
          targetCoreId: 'creativity',
          relatedEntry: journalEntry,
        );

        expect(context.relatedJournalEntryId, equals(journalEntry.id));
      });

      test('should create journal-to-core context', () {
        final journalEntry = JournalEntry(
          id: 'journal_entry',
          userId: 'user',
          content: 'Content',
          date: DateTime.now(),
          moods: ['grateful'],
          dayOfWeek: 'Tuesday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final context = service.createJournalToCoreContext(
          targetCoreId: 'optimism',
          relatedEntry: journalEntry,
          triggeredBy: 'your_cores_tap',
        );

        expect(context.sourceScreen, equals('journal'));
        expect(context.triggeredBy, equals('your_cores_tap'));
        expect(context.targetCoreId, equals('optimism'));
        expect(context.relatedJournalEntryId, equals(journalEntry.id));
        expect(context.additionalData['showJournalConnection'], isTrue);
        expect(context.additionalData['highlightRecentChanges'], isTrue);
      });

      test('should create core library context', () {
        final context = service.createCoreLibraryContext(
          targetCoreId: 'self_awareness',
          triggeredBy: 'library_navigation',
          additionalData: {'filterBy': 'rising'},
        );

        expect(context.sourceScreen, equals('core_library'));
        expect(context.triggeredBy, equals('library_navigation'));
        expect(context.targetCoreId, equals('self_awareness'));
        expect(context.additionalData['filterBy'], equals('rising'));
      });

      test('should create explore all context', () {
        final journalEntry = JournalEntry(
          id: 'explore_entry',
          userId: 'user',
          content: 'Explore content',
          date: DateTime.now(),
          moods: ['curious'],
          dayOfWeek: 'Wednesday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final highlightCores = ['optimism', 'creativity'];

        final context = service.createExploreAllContext(
          relatedEntry: journalEntry,
          highlightCoreIds: highlightCores,
        );

        expect(context.sourceScreen, equals('journal'));
        expect(context.triggeredBy, equals('explore_all'));
        expect(context.additionalData['showAllCores'], isTrue);
        expect(context.additionalData['highlightCoreIds'], equals(highlightCores));
        expect(context.additionalData['preserveJournalContext'], isTrue);
        expect(context.additionalData['relatedJournalEntryId'], equals(journalEntry.id));
      });
    });

    group('Context Stack Management', () {
      test('should maintain context stack correctly', () {
        expect(service.contextHistory, isEmpty);
        expect(service.currentContext, isNull);

        final context1 = service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
        );

        expect(service.contextHistory.length, equals(1));
        expect(service.currentContext, equals(context1));

        final context2 = service.createContext(
          sourceScreen: 'core_library',
          triggeredBy: 'navigation',
          targetCoreId: 'resilience',
        );

        expect(service.contextHistory.length, equals(2));
        expect(service.currentContext, equals(context2));
      });

      test('should limit context stack size', () {
        // Create more than 10 contexts
        for (int i = 0; i < 15; i++) {
          service.createContext(
            sourceScreen: 'test',
            triggeredBy: 'test',
            targetCoreId: 'test_$i',
          );
        }

        // Stack should be limited to 10
        expect(service.contextHistory.length, equals(10));
        
        // Should contain the most recent contexts
        expect(service.contextHistory.last.targetCoreId, equals('test_14'));
        expect(service.contextHistory.first.targetCoreId, equals('test_5'));
      });

      test('should preserve context correctly', () {
        final context = service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
        );

        service.preserveContext(context);

        expect(service.currentContext, equals(context));
        expect(service.contextHistory, contains(context));
      });

      test('should restore previous context', () {
        final context1 = service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap1',
          targetCoreId: 'optimism',
        );

        final context2 = service.createContext(
          sourceScreen: 'core_library',
          triggeredBy: 'tap2',
          targetCoreId: 'resilience',
        );

        expect(service.currentContext, equals(context2));

        final restoredContext = service.restoreContext();

        expect(restoredContext, equals(context1));
        expect(service.currentContext, equals(context1));
        expect(service.contextHistory.length, equals(1));
      });

      test('should handle restore when no previous context exists', () {
        final context = service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
        );

        final restoredContext = service.restoreContext();

        expect(restoredContext, isNull);
        expect(service.currentContext, equals(context));
      });

      test('should get previous context without removing it', () {
        final context1 = service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap1',
          targetCoreId: 'optimism',
        );

        final context2 = service.createContext(
          sourceScreen: 'core_library',
          triggeredBy: 'tap2',
          targetCoreId: 'resilience',
        );

        final previousContext = service.getPreviousContext();

        expect(previousContext, equals(context1));
        expect(service.contextHistory.length, equals(2)); // Should not modify stack
        expect(service.currentContext, equals(context2)); // Should not change current
      });

      test('should clear context correctly', () {
        service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
        );

        expect(service.contextHistory, isNotEmpty);
        expect(service.currentContext, isNotNull);

        service.clearContext();

        expect(service.contextHistory, isEmpty);
        expect(service.currentContext, isNull);
      });
    });

    group('Context Queries and Utilities', () {
      test('should check navigation back capability', () {
        expect(service.canNavigateBack(), isFalse);

        service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap1',
          targetCoreId: 'optimism',
        );

        expect(service.canNavigateBack(), isFalse);

        service.createContext(
          sourceScreen: 'core_library',
          triggeredBy: 'tap2',
          targetCoreId: 'resilience',
        );

        expect(service.canNavigateBack(), isTrue);
      });

      test('should get context for specific core ID', () {
        service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap1',
          targetCoreId: 'optimism',
        );

        service.createContext(
          sourceScreen: 'core_library',
          triggeredBy: 'tap2',
          targetCoreId: 'resilience',
        );

        service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap3',
          targetCoreId: 'optimism',
        );

        final optimismContext = service.getContextForCore('optimism');
        expect(optimismContext, isNotNull);
        expect(optimismContext!.triggeredBy, equals('tap3')); // Should get most recent

        final creativityContext = service.getContextForCore('creativity');
        expect(creativityContext, isNull);
      });

      test('should update current context with additional data', () {
        service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
          additionalData: {'initial': 'data'},
        );

        service.updateCurrentContext({
          'updated': 'value',
          'another': 'field',
        });

        final currentContext = service.currentContext!;
        expect(currentContext.additionalData['initial'], equals('data'));
        expect(currentContext.additionalData['updated'], equals('value'));
        expect(currentContext.additionalData['another'], equals('field'));
      });

      test('should handle update when no current context exists', () {
        expect(service.currentContext, isNull);

        // Should not throw when no current context
        expect(() => service.updateCurrentContext({'test': 'data'}), returnsNormally);

        expect(service.currentContext, isNull);
      });

      test('should check source screen correctly', () {
        service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
        );

        expect(service.isFromJournal(), isTrue);
        expect(service.isFromCoreLibrary(), isFalse);

        service.createContext(
          sourceScreen: 'core_library',
          triggeredBy: 'tap',
          targetCoreId: 'resilience',
        );

        expect(service.isFromJournal(), isFalse);
        expect(service.isFromCoreLibrary(), isTrue);
      });

      test('should get related journal entry ID', () {
        expect(service.getRelatedJournalEntryId(), isNull);

        final journalEntry = JournalEntry(
          id: 'test_entry',
          userId: 'user',
          content: 'Content',
          date: DateTime.now(),
          moods: ['happy'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
          relatedEntry: journalEntry,
        );

        expect(service.getRelatedJournalEntryId(), equals(journalEntry.id));
      });

      test('should check context flags correctly', () {
        service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
          additionalData: {
            'showJournalConnection': true,
            'highlightRecentChanges': false,
            'highlightCoreIds': ['optimism', 'resilience'],
          },
        );

        expect(service.shouldShowJournalConnection(), isTrue);
        expect(service.shouldHighlightRecentChanges(), isFalse);
        expect(service.getCoreIdsToHighlight(), equals(['optimism', 'resilience']));
      });

      test('should handle missing context flags', () {
        service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
        );

        expect(service.shouldShowJournalConnection(), isFalse);
        expect(service.shouldHighlightRecentChanges(), isFalse);
        expect(service.getCoreIdsToHighlight(), isEmpty);
      });
    });

    group('Deep Link Support', () {
      test('should generate core deep link correctly', () {
        final deepLink = service.generateCoreDeepLink(
          'optimism',
          sourceScreen: 'journal',
          relatedEntryId: 'entry_123',
          additionalParams: {'highlight': 'true'},
        );

        expect(deepLink, contains('/core/optimism'));
        expect(deepLink, contains('source=journal'));
        expect(deepLink, contains('entry=entry_123'));
        expect(deepLink, contains('trigger=deep_link'));
        expect(deepLink, contains('highlight=true'));
      });

      test('should generate core library deep link correctly', () {
        final deepLink = service.generateCoreLibraryDeepLink(
          sourceScreen: 'external',
          highlightCores: ['optimism', 'resilience'],
          additionalParams: {'filter': 'rising'},
        );

        expect(deepLink, contains('/core-library'));
        expect(deepLink, contains('source=external'));
        expect(deepLink, contains('highlight=optimism%2Cresilience'));
        expect(deepLink, contains('trigger=deep_link'));
        expect(deepLink, contains('filter=rising'));
      });

      test('should generate minimal deep links', () {
        final coreLink = service.generateCoreDeepLink('creativity');
        expect(coreLink, equals('/core/creativity?trigger=deep_link'));

        final libraryLink = service.generateCoreLibraryDeepLink();
        expect(libraryLink, equals('/core-library?trigger=deep_link'));
      });
    });

    group('Navigation Stream', () {
      test('should broadcast navigation events', () async {
        final eventCompleter = Completer<CoreNavigationContext>();
        final subscription = service.navigationStream.listen((context) {
          if (!eventCompleter.isCompleted) {
            eventCompleter.complete(context);
          }
        });

        final context = service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
        );

        final receivedContext = await eventCompleter.future.timeout(
          const Duration(seconds: 1),
        );

        expect(receivedContext, equals(context));
        await subscription.cancel();
      });

      test('should broadcast context updates', () async {
        service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
        );

        final eventCompleter = Completer<CoreNavigationContext>();
        final subscription = service.navigationStream.listen((context) {
          if (!eventCompleter.isCompleted) {
            eventCompleter.complete(context);
          }
        });

        service.updateCurrentContext({'updated': 'true'});

        final receivedContext = await eventCompleter.future.timeout(
          const Duration(seconds: 1),
        );

        expect(receivedContext.additionalData['updated'], equals('true'));
        await subscription.cancel();
      });

      test('should broadcast context restoration', () async {
        service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap1',
          targetCoreId: 'optimism',
        );

        service.createContext(
          sourceScreen: 'core_library',
          triggeredBy: 'tap2',
          targetCoreId: 'resilience',
        );

        final eventCompleter = Completer<CoreNavigationContext>();
        final subscription = service.navigationStream.listen((context) {
          if (context.targetCoreId == 'optimism' && !eventCompleter.isCompleted) {
            eventCompleter.complete(context);
          }
        });

        service.restoreContext();

        final receivedContext = await eventCompleter.future.timeout(
          const Duration(seconds: 1),
        );

        expect(receivedContext.targetCoreId, equals('optimism'));
        await subscription.cancel();
      });
    });

    group('Transition Creation', () {
      testWidgets('should create core transition route', (WidgetTester tester) async {
        final context = service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
        );

        final destination = Container(key: const Key('destination'));
        final route = service.createCoreTransition<void>(destination, context);

        expect(route, isA<PageRouteBuilder<void>>());
        expect(route.transitionDuration, equals(const Duration(milliseconds: 300)));
        expect(route.reverseTransitionDuration, equals(const Duration(milliseconds: 250)));
      });

      testWidgets('should create hero transition', (WidgetTester tester) async {
        final child = Container(key: const Key('hero_child'));
        final heroWidget = service.createCoreHeroTransition(
          heroTag: 'test_hero',
          child: child,
          coreId: 'optimism',
        );

        expect(heroWidget, isA<Hero>());
        
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: heroWidget),
        ));

        expect(find.byKey(const Key('hero_child')), findsOneWidget);
      });

      testWidgets('should create progress indicator transition', (WidgetTester tester) async {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: tester,
        );

        final transitionWidget = service.createProgressIndicatorTransition(
          animation: controller,
          fromProgress: 0.3,
          toProgress: 0.7,
          builder: (progress) => Text('Progress: ${progress.toStringAsFixed(2)}'),
        );

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: transitionWidget),
        ));

        expect(find.text('Progress: 0.30'), findsOneWidget);

        controller.forward();
        await tester.pump(const Duration(milliseconds: 150));

        // Progress should be somewhere between 0.3 and 0.7
        final progressText = tester.widget<Text>(find.byType(Text)).data!;
        final progress = double.parse(progressText.split(': ')[1]);
        expect(progress, greaterThan(0.3));
        expect(progress, lessThan(0.7));

        controller.dispose();
      });
    });

    group('Navigation Arguments', () {
      test('should build navigation arguments correctly', () {
        final context = service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
        );

        final args = service.buildNavigationArguments(
          coreId: 'resilience',
          context: context,
          additionalArgs: {'custom': 'value'},
        );

        expect(args['coreId'], equals('resilience'));
        expect(args['context'], equals(context));
        expect(args['custom'], equals('value'));
        expect(args['timestamp'], isA<String>());
      });

      test('should extract navigation arguments from route settings', () {
        final routeSettings = RouteSettings(
          name: '/test',
          arguments: {
            'coreId': 'optimism',
            'context': service.createContext(
              sourceScreen: 'journal',
              triggeredBy: 'tap',
              targetCoreId: 'optimism',
            ),
          },
        );

        final args = CoreNavigationContextService.extractNavigationArguments(routeSettings);
        expect(args, isNotNull);
        expect(args!['coreId'], equals('optimism'));

        final coreId = CoreNavigationContextService.extractCoreId(routeSettings);
        expect(coreId, equals('optimism'));

        final context = CoreNavigationContextService.extractNavigationContext(routeSettings);
        expect(context, isNotNull);
        expect(context!.targetCoreId, equals('optimism'));
      });

      test('should handle invalid route arguments', () {
        final routeSettings = RouteSettings(
          name: '/test',
          arguments: 'invalid_arguments',
        );

        final args = CoreNavigationContextService.extractNavigationArguments(routeSettings);
        expect(args, isNull);

        final coreId = CoreNavigationContextService.extractCoreId(routeSettings);
        expect(coreId, isNull);

        final context = CoreNavigationContextService.extractNavigationContext(routeSettings);
        expect(context, isNull);
      });
    });

    group('Resource Management', () {
      test('should dispose resources correctly', () {
        service.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'tap',
          targetCoreId: 'optimism',
        );

        expect(service.contextHistory, isNotEmpty);
        expect(service.currentContext, isNotNull);

        service.dispose();

        expect(service.contextHistory, isEmpty);
        expect(service.currentContext, isNull);
      });

      test('should handle multiple dispose calls', () {
        service.dispose();
        
        // Should not throw on second dispose
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });
}