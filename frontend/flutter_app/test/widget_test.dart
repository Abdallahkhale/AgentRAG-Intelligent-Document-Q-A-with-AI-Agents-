import 'package:flutter_test/flutter_test.dart';

import 'package:agentrag_flutter_app/main.dart';

void main() {
  testWidgets('renders the GroundedLens workspace', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('GroundedLens: Agentic Document Q&A'), findsOneWidget);
    expect(find.text('Ask a question about your documents'), findsOneWidget);
  });
}
