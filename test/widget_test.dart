import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/app.dart';
import 'package:local_lending_app/flavors/clients/local_lending_hub.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

void main() {
  setUp(() {
    FlavorConfig.instance = LocalLendingHubConfig();
  });

  testWidgets('App renders brand title from FlavorConfig', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    expect(find.text(FlavorConfig.appName), findsOneWidget);
  });
}
