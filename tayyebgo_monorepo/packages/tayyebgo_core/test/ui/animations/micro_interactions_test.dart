import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tayyebgo_core/ui/animations/micro_interactions.dart';

void main() {
  group('PressScale', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressScale(
              onTap: () {},
              child: const Text('Press Me'),
            ),
          ),
        ),
      );

      expect(find.text('Press Me'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressScale(
              onTap: () => tapCount++,
              child: const Text('Press Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Press Me'));
      expect(tapCount, 1);
    });

    testWidgets('does not crash when onTap is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressScale(
              child: const Text('No Tap'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('No Tap'));
      await tester.pumpAndSettle();
      expect(find.text('No Tap'), findsOneWidget);
    });

    testWidgets('has ScaleTransition animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressScale(
              onTap: () {},
              child: const Text('Animated'),
            ),
          ),
        ),
      );

      expect(find.byType(ScaleTransition), findsWidgets);
    });
  });

  group('AnimatedQuantityStepper', () {
    testWidgets('renders current value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedQuantityStepper(
              value: 5,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('increment button exists', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedQuantityStepper(
              value: 1,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('decrement button exists', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedQuantityStepper(
              value: 5,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    });

    testWidgets('value updates on increment', (tester) async {
      int currentValue = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AnimatedQuantityStepper(
                  value: currentValue,
                  onChanged: (v) => setState(() => currentValue = v),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });
  });
}
