import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/shared/widgets/metric_card.dart';

void main() {
  testWidgets('shows title value and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricCard(
            title: 'Total Disbursed',
            value: '₹2.4L',
            subValue: '85 loans',
            icon: Icons.account_balance,
            accentColor: Colors.teal,
          ),
        ),
      ),
    );
    expect(find.text('Total Disbursed'), findsOneWidget);
    expect(find.text('₹2.4L'), findsOneWidget);
    expect(find.text('85 loans'), findsOneWidget);
  });
}
