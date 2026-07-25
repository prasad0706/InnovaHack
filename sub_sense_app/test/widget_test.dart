import 'package:flutter_test/flutter_test.dart';
import 'package:sub_sense_app/main.dart';

void main() {
  testWidgets('SubSenseApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SubSenseApp());
    expect(find.text('SubSense'), findsOneWidget);
  });
}
