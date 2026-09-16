import 'package:flutter_test/flutter_test.dart';

import 'package:agentrag_flutter_app/main.dart';

void main() {
  testWidgets('renders the AgentRAG workspace', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('AgentRAG: Intelligent Document Q&A with AI Agents'), findsOneWidget);
    expect(find.text('Ask a question about your documents'), findsOneWidget);
  });
}
