import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/navigation/feature_catalog.dart';
import 'package:loan_ranger/src/features/arm/domain/services/arm_calculator_service.dart';
import 'package:loan_ranger/src/features/arm/domain/services/arm_preset_service.dart';
import 'package:loan_ranger/src/features/arm/presentation/screens/arm_wizard_screen.dart';
import 'package:loan_ranger/src/features/calculator/presentation/screens/calculator_layout_preview_screen.dart';
import 'package:loan_ranger/src/features/comparison/domain/models/comparison_data.dart';
import 'package:loan_ranger/src/features/comparison/presentation/screens/comparison_screen.dart';
import 'package:loan_ranger/src/features/loan_programs/domain/models/loan_program.dart';
import 'package:loan_ranger/src/features/loan_programs/presentation/widgets/loan_program_editor.dart';
import 'package:loan_ranger/src/features/reporting/domain/services/report_service.dart';
import 'package:loan_ranger/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:loan_ranger/src/features/workspace/presentation/screens/workspace_dashboard_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/loan_parameters_read_model.dart';

class AppRouter extends ChangeNotifier {
  AppRouter({
    required ArmCalculatorService armCalculatorService,
    required ArmPresetStorage armPresetStorage,
  }) : _catalog = const FeatureCatalog(),
       _armCalculatorService = armCalculatorService,
       _armPresetStorage = armPresetStorage;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FeatureCatalog _catalog;
  final ArmCalculatorService _armCalculatorService;
  final ArmPresetStorage _armPresetStorage;

  String _primaryFeatureId = FeatureCatalog.calculatorId;

  String get primaryFeatureId => _primaryFeatureId;

  int get primaryFeatureIndex {
    final index = FeatureCatalog.primaryFeatures.indexWhere(
      (entry) => entry.id == _primaryFeatureId,
    );
    return index < 0 ? 0 : index;
  }

  void selectPrimaryFeature(String featureId) {
    if (_primaryFeatureId == featureId) return;
    _primaryFeatureId = featureId;
    notifyListeners();
  }

  Future<void> openFeatureById(String featureId) async {
    final primaryIndex = FeatureCatalog.primaryFeatures.indexWhere(
      (entry) => entry.id == featureId,
    );
    if (primaryIndex != -1) {
      selectPrimaryFeature(featureId);
      return;
    }

    final feature = _catalog.byId(featureId);
    if (feature == null) return;
    await _push(feature.builder);
  }

  Future<String?> openWorkspaceDashboard() {
    return _push<String>((_) => const WorkspaceDashboardScreen());
  }

  Future<void> openSettings() {
    return _push((_) => const SettingsScreen());
  }

  Future<void> openCalculatorLayoutPreview() {
    return _push((_) => const CalculatorLayoutPreviewScreen());
  }

  Future<void> openArmWizard() {
    return _push(
      (_) => ArmWizardScreen(
        calculator: _armCalculatorService,
        presetStorage: _armPresetStorage,
      ),
    );
  }

  Future<void> openLoanPrograms() {
    return openFeatureById(FeatureCatalog.loanProgramsId);
  }

  Future<void> openRentVsBuy() {
    return openFeatureById(FeatureCatalog.rentVsBuyId);
  }

  Future<void> openComparison(ComparisonData data) {
    return _push((_) => ComparisonScreen(data: data));
  }

  Future<void> openLoanProgramEditor({LoanProgram? program}) {
    return _push((_) => LoanProgramEditor(program: program));
  }

  Future<void> openReportPreview(LoanParametersReadModel provider) async {
    final data = await ReportService.generateLoanReport(provider: provider);
    await _push<void>((_) => _PdfPreviewRoute(data: data));
  }

  Future<T?> _push<T>(WidgetBuilder builder) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return Future<T?>.value();
    }
    return navigator.push<T>(MaterialPageRoute(builder: builder));
  }
}

class _PdfPreviewRoute extends StatelessWidget {
  const _PdfPreviewRoute({required this.data});

  final Uint8List data;

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: (_) async => data,
      initialPageFormat: PdfPageFormat.a4,
      canDebug: false,
      canChangePageFormat: false,
      allowPrinting: true,
      allowSharing: true,
      pdfFileName: 'loan-estimate.pdf',
    );
  }
}
