import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/features/admin/presentation/pages/kyc_review_page.dart';
import 'package:local_lending_app/flavors/clients/local_lending_hub.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:local_lending_app/shared/widgets/app_choice_chip.dart';
import 'package:local_lending_app/theme/app_theme.dart';

Future<void> _pumpReview(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.build(), home: const KycReviewPage()),
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

  testWidgets('KYC review lists registered borrowers by default', (
    tester,
  ) async {
    await _pumpReview(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('KYC review'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Anjali Devi'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.byType(AppChoiceChip), findsWidgets);
  });

  testWidgets('Submitted filter keeps only packs waiting for approval', (
    tester,
  ) async {
    await _pumpReview(tester);

    await tester.tap(find.widgetWithText(AppChoiceChip, 'Submitted'));
    await tester.pump();

    expect(find.text('Anjali Devi'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsNothing);
    expect(find.text('Approve'), findsOneWidget);
  });
}
