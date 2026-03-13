import 'package:loan_ranger/src/core/utils/formatters.dart';

class QualifyingRatio {
  final String id;
  final String name;
  final String? description;
  final double housingRatio; // Front-end DTI
  final double debtRatio;    // Back-end DTI
  final bool isBuiltIn;      // Cannot delete built-in ratios

  const QualifyingRatio({
    required this.id,
    required this.name,
    this.description,
    required this.housingRatio,
    required this.debtRatio,
    this.isBuiltIn = false,
  });

  QualifyingRatio copyWith({
    String? id,
    String? name,
    String? description,
    double? housingRatio,
    double? debtRatio,
    bool? isBuiltIn,
  }) {
    return QualifyingRatio(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      housingRatio: housingRatio ?? this.housingRatio,
      debtRatio: debtRatio ?? this.debtRatio,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'housingRatio': housingRatio,
      'debtRatio': debtRatio,
      'isBuiltIn': isBuiltIn,
    };
  }

  factory QualifyingRatio.fromJson(Map<String, dynamic> json) {
    return QualifyingRatio(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      housingRatio: (json['housingRatio'] as num).toDouble(),
      debtRatio: (json['debtRatio'] as num).toDouble(),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }

  String get displayName =>
      '$name (${_formatRatioValue(housingRatio)}/${_formatRatioValue(debtRatio)})';

  static String _formatRatioValue(double value) =>
      CurrencyFormatter.formatPercent(value, decimals: 2).replaceAll('%', '');
}

/// Default built-in qualifying ratios
class DefaultQualifyingRatios {
  static const List<QualifyingRatio> ratios = [
    QualifyingRatio(
      id: 'conventional',
      name: 'Conventional',
      description: 'Standard conforming loan ratios',
      housingRatio: 28,
      debtRatio: 36,
      isBuiltIn: true,
    ),
    QualifyingRatio(
      id: 'fha',
      name: 'FHA',
      description: 'FHA loan program ratios',
      housingRatio: 31,
      debtRatio: 43,
      isBuiltIn: true,
    ),
    QualifyingRatio(
      id: 'va',
      name: 'VA',
      description: 'VA loan - no front-end ratio, 41% back-end',
      housingRatio: 0, // VA doesn't use front-end ratio
      debtRatio: 41,
      isBuiltIn: true,
    ),
    QualifyingRatio(
      id: 'usda',
      name: 'USDA',
      description: 'USDA Rural Development loan ratios',
      housingRatio: 29,
      debtRatio: 41,
      isBuiltIn: true,
    ),
    QualifyingRatio(
      id: 'jumbo',
      name: 'Jumbo',
      description: 'Non-conforming jumbo loan ratios',
      housingRatio: 28,
      debtRatio: 43,
      isBuiltIn: true,
    ),
  ];
}
