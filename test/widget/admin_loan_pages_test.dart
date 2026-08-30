import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/features/admin/presentation/pages/create_loan_page.dart';
import 'package:local_lending_app/features/admin/presentation/pages/loan_approvals_page.dart';
import 'package:local_lending_app/flavors/clients/local_lending_hub.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:local_lending_app/shared/widgets/app_choice_chip.dart';
import 'package:local_lending_app/theme/app_theme.dart';

Future<void> _pumpApprovals(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.build(), home: const LoanApprovalsPage()),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() {
    FlavorConfig.instance = LocalLendingHubConfig();
    getIt.reset();
    configureDependencies(useMocks: true);
  });

  testWidgets('Loan approvals page loads pending applications', (tester) async {
    await _pumpApprovals(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Loan Management & Approvals'), findsOneWidget);
    expect(find.text('Suresh Patel'), findsOneWidget);
    expect(find.text('Approve'), findsWidgets);
    expect(find.text('Counter-offer'), findsWidgets);
    expect(find.text('Awaiting fund release'), findsOneWidget);
    expect(find.text('Release funds'), findsWidgets);
    expect(find.text('All'), findsOneWidget);
    expect(find.byType(AppChoiceChip), findsWidgets);
  });

  testWidgets('Approve removes the request from the pending queue', (
    tester,
  ) async {
    await _pumpApprovals(tester);

    expect(find.text('Suresh Patel'), findsOneWidget);
    await tester.tap(find.text('Approve').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('Suresh Patel'), findsOneWidget);
    expect(
      find.text('Loan approved. Release funds after you send the amount.'),
      findsOneWidget,
    );
    expect(find.text('Release funds'), findsWidgets);
  });

  testWidgets('Release funds moves an approved loan into confirmation', (
    tester,
  ) async {
    await _pumpApprovals(tester);

    await tester.tap(find.text('Release funds').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(
      find.text(
        'Funds marked as released. Borrower can confirm receipt now or report a problem within 2 days.',
      ),
      findsOneWidget,
    );
    expect(find.text('Confirmation window'), findsOneWidget);
  });

  testWidgets('Create Loan for User page can search and select a borrower', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.build(), home: const CreateLoanPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Create Loan for User'), findsOneWidget);
    expect(find.text('Select a borrower'), findsOneWidget);
    expect(find.text('Repayment frequency'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Biweekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('EMI breakdown'), findsOneWidget);

    await tester.tap(find.byKey(const Key('borrower-field')));
    await tester.pumpAndSettle();

    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Anjali Devi'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('borrower-search-field')),
      'Anjali',
    );
    await tester.pumpAndSettle();

    expect(find.text('Priya Sharma'), findsNothing);
    await tester.tap(find.text('Anjali Devi'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Anjali Devi'), findsOneWidget);
    expect(find.textContaining('+91 98765 33303'), findsOneWidget);
    expect(find.text('Disburse loan'), findsOneWidget);
  });
}
