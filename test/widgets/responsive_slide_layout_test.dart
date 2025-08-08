import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spiral_journal/widgets/responsive_slide_layout.dart';

void main() {
  group('ResponsiveSlideLayout', () {
    testWidgets('should render with required properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideLayout(
              slideId: 'test_slide',
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(ResponsiveSlideLayout), findsOneWidget);
    });

    testWidgets('should adapt to compact iPhone size', (WidgetTester tester) async {
      // Set iPhone SE size
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideLayout(
              slideId: 'test_slide',
              child: Text('Compact Content'),
            ),
          ),
        ),
      );

      expect(find.text('Compact Content'), findsOneWidget);
      expect(find.byType(ResponsiveSlideLayout), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('should adapt to large iPhone size', (WidgetTester tester) async {
      // Set iPhone Pro Max size
      tester.view.physicalSize = const Size(414, 896);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideLayout(
              slideId: 'test_slide',
              child: Text('Large Content'),
            ),
          ),
        ),
      );

      expect(find.text('Large Content'), findsOneWidget);
      expect(find.byType(ResponsiveSlideLayout), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('should adapt to tablet size', (WidgetTester tester) async {
      // Set iPad size
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideLayout(
              slideId: 'test_slide',
              enableTabletOptimization: true,
              child: Text('Tablet Content'),
            ),
          ),
        ),
      );

      expect(find.text('Tablet Content'), findsOneWidget);
      expect(find.byType(ResponsiveSlideLayout), findsOneWidget);
      expect(find.byType(Center), findsOneWidget); // Should center content on tablet
      expect(find.byType(ConstrainedBox), findsOneWidget); // Should constrain width

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('should handle orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideLayout(
              slideId: 'test_slide',
              enableOrientationOptimization: true,
              child: Text('Orientation Content'),
            ),
          ),
        ),
      );

      expect(find.text('Orientation Content'), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets('should use custom padding when provided', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(32.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideLayout(
              slideId: 'test_slide',
              customPadding: customPadding,
              child: Text('Custom Padding Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ResponsiveSlideLayout),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.padding, equals(customPadding));
    });

    testWidgets('should disable optimizations when specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideLayout(
              slideId: 'test_slide',
              enableOrientationOptimization: false,
              enableTabletOptimization: false,
              child: Text('No Optimization Content'),
            ),
          ),
        ),
      );

      expect(find.text('No Optimization Content'), findsOneWidget);
      expect(find.byType(ResponsiveSlideLayout), findsOneWidget);
    });
  });

  group('ResponsiveChartContainer', () {
    testWidgets('should render chart with proper aspect ratio', (WidgetTester tester) async {
      const testChart = Placeholder();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveChartContainer(
              chart: testChart,
              chartType: 'line',
            ),
          ),
        ),
      );

      expect(find.byType(Placeholder), findsOneWidget);
      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('should use custom aspect ratio when provided', (WidgetTester tester) async {
      const customAspectRatio = 2.5;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveChartContainer(
              chart: Placeholder(),
              chartType: 'line',
              aspectRatio: customAspectRatio,
            ),
          ),
        ),
      );

      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, equals(customAspectRatio));
    });

    testWidgets('should adapt chart aspect ratio for different chart types', (WidgetTester tester) async {
      // Test pie chart (should be square)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveChartContainer(
              chart: Placeholder(),
              chartType: 'pie',
            ),
          ),
        ),
      );

      final pieAspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(pieAspectRatio.aspectRatio, equals(1.0));

      // Test line chart (should be wider)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveChartContainer(
              chart: Placeholder(),
              chartType: 'line',
            ),
          ),
        ),
      );

      final lineAspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(lineAspectRatio.aspectRatio, greaterThan(1.0));
    });

    testWidgets('should adapt to device size', (WidgetTester tester) async {
      // Test compact device
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveChartContainer(
              chart: Placeholder(),
              chartType: 'line',
            ),
          ),
        ),
      );

      expect(find.byType(ResponsiveChartContainer), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });

  group('ResponsiveTextContainer', () {
    testWidgets('should render text with responsive scaling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveTextContainer(
              text: 'Responsive Text',
            ),
          ),
        ),
      );

      expect(find.text('Responsive Text'), findsOneWidget);
    });

    testWidgets('should scale text for tablet', (WidgetTester tester) async {
      // Set tablet size
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveTextContainer(
              text: 'Tablet Text',
              baseStyle: TextStyle(fontSize: 16.0),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Tablet Text'));
      expect(textWidget.style!.fontSize, greaterThan(16.0)); // Should be scaled up

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('should scale text for compact device', (WidgetTester tester) async {
      // Set compact device size
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveTextContainer(
              text: 'Compact Text',
              baseStyle: TextStyle(fontSize: 16.0),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Compact Text'));
      expect(textWidget.style!.fontSize, lessThan(16.0)); // Should be scaled down

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('should handle text properties correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveTextContainer(
              text: 'Test Text with Properties',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Test Text with Properties'));
      expect(textWidget.textAlign, equals(TextAlign.center));
      expect(textWidget.maxLines, equals(2));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });
  });

  group('ResponsiveSlideGrid', () {
    testWidgets('should render grid with children', (WidgetTester tester) async {
      final children = List.generate(6, (index) => Text('Item $index'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideGrid(
              children: children,
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      for (int i = 0; i < 6; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
    });

    testWidgets('should adapt column count for different devices', (WidgetTester tester) async {
      final children = List.generate(4, (index) => Text('Item $index'));

      // Test compact device (should have 1 column)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideGrid(
              children: children,
            ),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(1));

      // Test tablet (should have more columns)
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideGrid(
              children: children,
            ),
          ),
        ),
      );

      final tabletGridView = tester.widget<GridView>(find.byType(GridView));
      final tabletDelegate = tabletGridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(tabletDelegate.crossAxisCount, greaterThan(1));

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('should use custom spacing when provided', (WidgetTester tester) async {
      const customSpacing = 20.0;
      final children = List.generate(4, (index) => Text('Item $index'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideGrid(
              children: children,
              spacing: customSpacing,
              runSpacing: customSpacing,
            ),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisSpacing, equals(customSpacing));
      expect(delegate.mainAxisSpacing, equals(customSpacing));
    });

    testWidgets('should use custom child aspect ratio when provided', (WidgetTester tester) async {
      const customAspectRatio = 2.0;
      final children = List.generate(4, (index) => Text('Item $index'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideGrid(
              children: children,
              childAspectRatio: customAspectRatio,
            ),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.childAspectRatio, equals(customAspectRatio));
    });

    testWidgets('should handle orientation changes', (WidgetTester tester) async {
      final children = List.generate(4, (index) => Text('Item $index'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideGrid(
              children: children,
            ),
          ),
        ),
      );

      expect(find.byType(ResponsiveSlideGrid), findsOneWidget);
      expect(find.byType(OrientationBuilder), findsOneWidget);
    });
  });

  group('Responsive Layout Integration', () {
    testWidgets('should work together in complex layouts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideLayout(
              slideId: 'complex_slide',
              child: Column(
                children: [
                  const ResponsiveTextContainer(
                    text: 'Slide Title',
                    baseStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Expanded(
                    child: ResponsiveChartContainer(
                      chart: Placeholder(),
                      chartType: 'line',
                    ),
                  ),
                  ResponsiveSlideGrid(
                    children: List.generate(4, (index) => Text('Grid Item $index')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Slide Title'), findsOneWidget);
      expect(find.byType(Placeholder), findsOneWidget);
      expect(find.text('Grid Item 0'), findsOneWidget);
      expect(find.text('Grid Item 3'), findsOneWidget);
    });

    testWidgets('should maintain performance with nested responsive components', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideLayout(
              slideId: 'performance_test',
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) => ResponsiveTextContainer(
                  text: 'Item $index',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ResponsiveSlideLayout), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      
      // Should render without performance issues
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Error Handling', () {
    testWidgets('should handle empty children gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveSlideGrid(
              children: [],
            ),
          ),
        ),
      );

      expect(find.byType(ResponsiveSlideGrid), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle null or empty text gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveTextContainer(
              text: '',
            ),
          ),
        ),
      );

      expect(find.byType(ResponsiveTextContainer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
