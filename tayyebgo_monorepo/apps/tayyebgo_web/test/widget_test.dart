import 'package:flutter_test/flutter_test.dart';
import 'package:tayyebgo_web/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TayyebGoWebApp());
    await tester.pumpAndSettle();
  });
}
