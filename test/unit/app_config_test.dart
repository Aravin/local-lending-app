import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/flavors/clients/cape_finance.dart';
import 'package:local_lending_app/flavors/clients/local_lending_hub.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

void main() {
  group('White-label Client Configs', () {
    test('LocalLendingHubConfig properties', () {
      final config = LocalLendingHubConfig();
      expect(config.appName, equals('Local Lending Hub'));
      expect(config.packageName, equals('com.locallendinghub.app'));
      expect(config.currencySymbol, equals('₹'));
      expect(config.phoneCountryCode, equals('+91'));
      expect(config.supportedFrequencies.length, equals(4));
    });

    test('CapeFinanceConfig properties', () {
      final config = CapeFinanceConfig();
      expect(config.appName, equals('Cape Finance'));
      expect(config.packageName, equals('com.capefinance.app'));
      expect(
        config.logoAssetPath,
        equals('assets/images/cape_finance/logo.png'),
      );
      expect(
        config.logoFullAssetPath,
        equals('assets/images/cape_finance/logo_full.png'),
      );
      expect(config.currencySymbol, equals('₹'));
      expect(config.phoneCountryCode, equals('+91'));

      expect(config.maxLoanAmountPaise, equals(100000000)); // ₹10 Lakhs
      expect(config.minLoanAmountPaise, equals(100000)); // ₹1,000
      expect(config.supportedFrequencies, contains(RepaymentFrequency.daily));
      expect(config.supportedFrequencies, contains(RepaymentFrequency.monthly));
    });

    test('FlavorConfig dynamically switches active client config', () {
      FlavorConfig.instance = CapeFinanceConfig();
      expect(FlavorConfig.appName, equals('Cape Finance'));
      expect(FlavorConfig.primaryColor, equals(const Color(0xFF0F3D3E)));

      FlavorConfig.instance = LocalLendingHubConfig();
      expect(FlavorConfig.appName, equals('Local Lending Hub'));
      expect(FlavorConfig.primaryColor, equals(const Color(0xFF0D9488)));
    });
  });
}
