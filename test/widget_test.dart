import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traderep/main.dart';

void main() {
  testWidgets('TradeRep app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TradeRepApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
