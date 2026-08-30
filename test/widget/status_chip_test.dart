import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/domain/entities/repayment_installment.dart';
import 'package:local_lending_app/shared/widgets/status_chip.dart';

void main() {
  testWidgets('renders installment status label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StatusChip.installment(InstallmentStatus.overdue)),
      ),
    );
    expect(find.text('Overdue'), findsOneWidget);
  });
}
