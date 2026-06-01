import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zen_music/main.dart';

void main() {
  testWidgets('shows the music library shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ZenMusicApp());

    expect(find.text('Zaloguj sie'), findsOneWidget);
    expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
  });
}
