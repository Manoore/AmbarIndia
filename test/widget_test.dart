import 'package:ambar_direct/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows location selector on launch', (tester) async {
    await tester.pumpWidget(const AmbarDirectApp());
    expect(find.text('Choose your location'), findsOneWidget);
    expect(find.text('Ambar India Clifton'), findsOneWidget);
  });
}
