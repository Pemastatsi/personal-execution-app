import 'package:flutter_test/flutter_test.dart';
import 'package:personal_execution_app/main.dart';

void main() {
  testWidgets('shows the development starter', (tester) async {
    await tester.pumpWidget(const PersonalExecutionApp());

    expect(find.text('A calmer way to get things done'), findsOneWidget);
    expect(
      find.text('Development starter — your tasks stay on this device.'),
      findsOneWidget,
    );
  });
}
