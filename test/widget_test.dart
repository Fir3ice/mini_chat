import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_chat/main.dart';

void main() {
  testWidgets('MiniChat app launches', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MiniChatApp());

    // Verify that the app starts on the login screen.
    expect(find.text('MiniChat'), findsOneWidget);
    expect(find.text('Обмін короткими повідомленнями'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}