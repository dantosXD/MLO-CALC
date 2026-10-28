import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';
import 'package:loan_ranger/src/features/reporting/domain/services/brand_header.dart';
import 'package:loan_ranger/src/features/reporting/domain/services/report_service.dart';

BrandInfo _brand(Uint8List? logo) => BrandInfo(
  name: 'Jane',
  nmls: '123',
  company: 'Acme',
  phone: '555',
  email: 'j@a.com',
  applyUrl: 'https://apply.example.com',
  disclaimer: 'Estimates only.',
  logo: logo,
  accentColor: 0xFF0891B2,
);

void main() {
  setUpAll(() async => configureDependencies());

  CalculatorProvider build() => CalculatorProvider(
    coreCalculationService: serviceLocator<CoreCalculationService>(),
    amortizationService: serviceLocator<AmortizationService>(),
    qualificationService: serviceLocator<QualificationService>(),
    persistenceService: serviceLocator<CalculatorPersistenceService>(),
  );

  final png = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    ),
  );

  test('report without logo', () async {
    final bytes = await ReportService.generateLoanReport(
      provider: build(),
      brand: _brand(null),
    );
    expect(bytes, isNotEmpty);
  });

  test('report with 1x1 png', () async {
    final bytes = await ReportService.generateLoanReport(
      provider: build(),
      brand: _brand(png),
    );
    expect(bytes, isNotEmpty);
  });

  test('report with garbage logo does not throw', () async {
    final bytes = await ReportService.generateLoanReport(
      provider: build(),
      brand: _brand(Uint8List.fromList([1, 2, 3])),
    );
    expect(bytes, isNotEmpty);
  });
}
