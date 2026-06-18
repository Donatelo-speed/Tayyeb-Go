import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tayyebgo_core/ui/layouts/responsive_layout.dart';

void main() {
  group('ResponsiveLayout', () {
    testWidgets('renders mobile widget by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: const Text('Mobile'),
              tablet: const Text('Tablet'),
              desktop: const Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
    });

    testWidgets('renders mobile when only mobile provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: const Text('Fallback'),
            ),
          ),
        ),
      );

      expect(find.text('Fallback'), findsOneWidget);
    });
  });

  group('ResponsivePadding', () {
    testWidgets('wraps child in padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsivePadding(
              child: const Text('Padded Content'),
            ),
          ),
        ),
      );

      expect(find.text('Padded Content'), findsOneWidget);
      expect(find.byType(Padding), findsOneWidget);
    });
  });

  group('ContentCenter', () {
    testWidgets('centers child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentCenter(
              child: const Text('Centered'),
            ),
          ),
        ),
      );

      expect(find.text('Centered'), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
    });
  });
}
