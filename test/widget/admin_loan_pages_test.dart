import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/features/admin/presentation/pages/create_loan_page.dart';
import 'package:local_lending_app/features/admin/presentation/pages/loan_approvals_page.dart';
import 'package:local_lending_app/flavors/clients/local_lending_hub.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:local_lending_app/theme/app_theme.dart';

void main() {
  setUp(() {
    FlavorConfig.instance = LocalLendingHubConfig();
    getIt.reset();
    configureDependencies();
  });

  testWidgets('New Loan Requests page loads pending applications', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const LoanApprovalsPage(quickActionsOnly: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('New Loan Requests'), findsOneWidget);
    expect(find.text('Suresh Patel'), findsOneWidget);
    expect(find.text('Approve'), findsWidgets);
  });

  testWidgets('Create Loan for User page loads borrowers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.build(), home: const CreateLoanPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Create Loan for User'), findsOneWidget);
    expect(find.text('Disburse loan'), findsOneWidget);
  });
}
