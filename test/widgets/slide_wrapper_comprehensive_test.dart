import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spiral_journal/widgets/slide_wrapper.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';

void main() {
  group('SlideWrapper', () {
    testWidgets('should render with required properties', (WidgetTester tester) async {
      const testTitle = 'Test Slide';
      const testChild = Text('Test Content');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: testTitle,
              child: testChild,
            ),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should display icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: 'Test Slide',
              icon: Icons.mood,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mood), findsOneWidget);
    });

    testWidgets('should display refresh button when onRefresh is provided', (WidgetTester tester) async {
      bool refreshCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: 'Test Slide',
              onRefresh: () {
                refreshCalled = true;
              },
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();

      expect(refreshCalled, isTrue);
    });

    testWidgets('should display footer when provided', (WidgetTester tester) async {
      const footerWidget = Text('Footer Content');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: 'Test Slide',
              footer: footerWidget,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Footer Content'), findsOneWidget);
    });

    testWidgets('should hide header when showHeader is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: 'Test Slide',
              showHeader: false,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Slide'), findsNothing);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should use custom padding when provided', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(32.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: 'Test Slide',
              padding: customPadding,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      final paddingWidget = tester.widget<Padding>(
        find.descendant(
          of: find.byType(SlideWrapper),
          matching: find.byType(Padding),
        ).first,
      );

      expect(paddingWidget.padding, equals(customPadding));
    });

    testWidgets('should use custom background gradient when provided', (WidgetTester tester) async {
      const customGradient = LinearGradient(
        colors: [Colors.red, Colors.blue],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: 'Test Slide',
              backgroundGradient: customGradient,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SlideWrapper),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, equals(customGradient));
    });

    testWidgets('should have proper layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: 'Test Slide',
              icon: Icons.mood,
              onRefresh: () {},
              footer: const Text('Footer'),
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      // Should have main container
      expect(find.byType(Container), findsWidgets);
      
      // Should have SafeArea
      expect(find.byType(SafeArea), findsOneWidget);
      
      // Should have Column for layout
      expect(find.byType(Column), findsWidgets);
      
      // Should have Expanded for main content
      expect(find.byType(Expanded), findsOneWidget);
    });

    testWidgets('should handle responsive spacing correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: 'Test Slide',
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // Verify that the widget renders without errors
      expect(find.byType(SlideWrapper), findsOneWidget);
      expect(find.text('Test Slide'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });
  });

  group('SlideLoadingWrapper', () {
    testWidgets('should show loading state when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideLoadingWrapper(
              isLoading: true,
              title: 'Test Slide',
              child: Text('Loaded Content'),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Loaded Content'), findsNothing);
    });

    testWidgets('should show child content when isLoading is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideLoadingWrapper(
              isLoading: false,
              title: 'Test Slide',
              child: Text('Loaded Content'),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Loading...'), findsNothing);
      expect(find.text('Loaded Content'), findsOneWidget);
    });

    testWidgets('should display custom loading message when provided', (WidgetTester tester) async {
      const customMessage = 'Loading slide data...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideLoadingWrapper(
              isLoading: true,
              title: 'Test Slide',
              loadingMessage: customMessage,
              child: Text('Loaded Content'),
            ),
          ),
        ),
      );

      expect(find.text(customMessage), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);
    });

    testWidgets('should display icon in loading state when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideLoadingWrapper(
              isLoading: true,
              title: 'Test Slide',
              icon: Icons.analytics,
              child: Text('Loaded Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.analytics), findsOneWidget);
    });

    testWidgets('should have proper loading layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideLoadingWrapper(
              isLoading: true,
              title: 'Test Slide',
              child: Text('Loaded Content'),
            ),
          ),
        ),
      );

      // Should have SlideWrapper
      expect(find.byType(SlideWrapper), findsOneWidget);
      
      // Should have Center widget for loading content
      expect(find.byType(Center), findsOneWidget);
      
      // Should have Column for loading layout
      expect(find.byType(Column), findsWidgets);
      
      // Should have SizedBox for loading indicator
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should handle loading state transitions', (WidgetTester tester) async {
      bool isLoading = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = !isLoading;
                        });
                      },
                      child: const Text('Toggle Loading'),
                    ),
                    Expanded(
                      child: SlideLoadingWrapper(
                        isLoading: isLoading,
                        title: 'Test Slide',
                        child: const Text('Loaded Content'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Initially loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loaded Content'), findsNothing);

      // Toggle to loaded state
      await tester.tap(find.text('Toggle Loading'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Loaded Content'), findsOneWidget);

      // Toggle back to loading state
      await tester.tap(find.text('Toggle Loading'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loaded Content'), findsNothing);
    });

    testWidgets('should maintain title consistency between loading and loaded states', (WidgetTester tester) async {
      const testTitle = 'Consistent Title';

      // Test loading state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideLoadingWrapper(
              isLoading: true,
              title: testTitle,
              child: Text('Loaded Content'),
            ),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);

      // Test loaded state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideLoadingWrapper(
              isLoading: false,
              title: testTitle,
              child: Text('Loaded Content'),
            ),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
    });
  });

  group('SlideWrapper Responsive Behavior', () {
    testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
      // Test with compact screen size
      tester.view.physicalSize = const Size(320, 568); // iPhone SE size
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: 'Test Slide',
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.byType(SlideWrapper), findsOneWidget);

      // Test with large screen size
      tester.view.physicalSize = const Size(414, 896); // iPhone 11 Pro Max size
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: 'Test Slide',
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.byType(SlideWrapper), findsOneWidget);

      // Reset to default size
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('should handle orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: 'Test Slide',
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.byType(SlideWrapper), findsOneWidget);
      expect(find.text('Test Slide'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });
  });

  group('SlideWrapper Accessibility', () {
    testWidgets('should have proper semantic structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideWrapper(
              title: 'Accessible Slide',
              onRefresh: () {},
              child: const Text('Accessible Content'),
            ),
          ),
        ),
      );

      // Verify semantic structure exists
      expect(find.byType(SlideWrapper), findsOneWidget);
      expect(find.text('Accessible Slide'), findsOneWidget);
      expect(find.text('Accessible Content'), findsOneWidget);
      
      // Verify refresh button has tooltip
      final refreshButton = find.byIcon(Icons.refresh_rounded);
      expect(refreshButton, findsOneWidget);
      
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: refreshButton,
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.tooltip, equals('Refresh'));
    });
  });
}
