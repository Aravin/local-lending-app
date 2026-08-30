import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/admin/presentation/pages/customers_page.dart';
import 'package:local_lending_app/flavors/clients/local_lending_hub.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:local_lending_app/theme/app_theme.dart';

void main() {
  setUp(() {
    FlavorConfig.instance = LocalLendingHubConfig();
    getIt.reset();
    configureDependencies(useMocks: true);
  });

  testWidgets('Customers page loads borrowers without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.build(), home: const CustomersPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final exception = tester.takeException();
    expect(exception, isNull, reason: '$exception');
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<RiskTier?>));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Medium risk').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsNothing);
  });
}
