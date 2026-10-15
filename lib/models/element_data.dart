import 'electron_configuration.dart';

enum ElementCategory {
  alkaliMetal,
  alkalineEarthMetal,
  transitionMetal,
  postTransitionMetal,
  metalloid,
  reactiveNonmetal,
  halogen,
  nobleGas,
  lanthanide,
  actinide,
  unknown,
}

enum AtomicMassType { standardAtomicWeight, representativeMassNumber }

class ElementData {
  const ElementData({
    required this.atomicNumber,
    required this.symbol,
    required this.nameZh,
    required this.nameEn,
    required this.atomicMass,
    required this.atomicMassType,
    required this.representativeMassNumber,
    required this.period,
    required this.group,
    required this.displayRow,
    required this.displayColumn,
    required this.category,
    required this.block,
    required this.valenceConfiguration,
    required this.electronConfiguration,
    required this.valenceConfigurationData,
    required this.electronConfigurationData,
    required this.shellDistribution,
    required this.phaseAtStp,
    this.density,
    this.densityUnit = 'g/cm³',
    this.meltingPointK,
    this.boilingPointK,
    this.electronegativityPauling,
    this.atomicRadiusPm,
    this.oxidationStates = '',
    this.discoveryYear,
    this.discoverer,
    this.uses,
    this.notes,
  });

  final int atomicNumber;
  final String symbol;
  final String nameZh;
  final String nameEn;
  final String atomicMass;
  final AtomicMassType atomicMassType;
  final int? representativeMassNumber;
  final int period;
  final int? group;
  final int displayRow;
  final int displayColumn;
  final ElementCategory category;
  final String block;
  final String valenceConfiguration;
  final String electronConfiguration;
  final ElectronConfiguration valenceConfigurationData;
  final ElectronConfiguration electronConfigurationData;
  final List<int> shellDistribution;
  final String phaseAtStp;
  final double? density;
  final String densityUnit;
  final double? meltingPointK;
  final double? boilingPointK;
  final double? electronegativityPauling;
  final double? atomicRadiusPm;
  final String oxidationStates;
  final int? discoveryYear;
  final String? discoverer;
  final String? uses;
  final String? notes;

  bool get isInMainTable => displayRow <= 7;

  bool get isFBlock =>
      category == ElementCategory.lanthanide ||
      category == ElementCategory.actinide;

  String get groupLabel => group?.toString() ?? (isFBlock ? 'f 区元素' : '未知');

  String get displayAtomicMass {
    if (atomicMass.startsWith('[')) return atomicMass;
    final value = double.tryParse(atomicMass);
    if (value == null) return atomicMass;
    return value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String get categoryLabel {
    switch (category) {
      case ElementCategory.alkaliMetal:
        return '碱金属';
      case ElementCategory.alkalineEarthMetal:
        return '碱土金属';
      case ElementCategory.transitionMetal:
        return '过渡金属';
      case ElementCategory.postTransitionMetal:
        return '后过渡金属';
      case ElementCategory.metalloid:
        return '类金属';
      case ElementCategory.reactiveNonmetal:
        return '非金属';
      case ElementCategory.halogen:
        return '卤素';
      case ElementCategory.nobleGas:
        return '稀有气体';
      case ElementCategory.lanthanide:
        return '镧系元素';
      case ElementCategory.actinide:
        return '锕系元素';
      case ElementCategory.unknown:
        return '性质未知';
    }
  }

  static ElementData fromJson(Map<String, Object?> json) {
    return ElementData(
      atomicNumber: _int(json['atomicNumber']),
      symbol: _string(json['symbol']),
      nameZh: _string(json['nameZh']),
      nameEn: _string(json['nameEn']),
      atomicMass: _string(json['atomicMass']),
      atomicMassType: _atomicMassType(
        json['atomicMassType'],
        atomicMass: _string(json['atomicMass']),
      ),
      representativeMassNumber:
          _nullableInt(json['representativeMassNumber']) ??
          _representativeMassNumber(_string(json['atomicMass'])),
      period: _int(json['period']),
      group: _nullableInt(json['group']),
      displayRow: _int(json['displayRow']),
      displayColumn: _int(json['displayColumn']),
      category: _category(json['category']),
      block: _string(json['block']),
      valenceConfiguration: _string(json['valenceConfiguration']),
      electronConfiguration: _string(json['electronConfiguration']),
      valenceConfigurationData: _configuration(
        json['valenceConfigurationData'],
        fallback: _string(json['valenceConfiguration']),
      ),
      electronConfigurationData: _configuration(
        json['electronConfigurationData'],
        fallback: _string(json['electronConfiguration']),
      ),
      shellDistribution: (json['shellDistribution'] as List<Object?>)
          .map(_int)
          .toList(growable: false),
      phaseAtStp: _string(json['phaseAtStp']),
      density: _nullableDouble(json['density']),
      densityUnit: _string(json['densityUnit']),
      meltingPointK: _nullableDouble(json['meltingPointK']),
      boilingPointK: _nullableDouble(json['boilingPointK']),
      electronegativityPauling: _nullableDouble(
        json['electronegativityPauling'],
      ),
      atomicRadiusPm: _nullableDouble(json['atomicRadiusPm']),
      oxidationStates: _string(json['oxidationStates']),
      discoveryYear: _nullableInt(json['discoveryYear']),
      discoverer: _nullableString(json['discoverer']),
      uses: _nullableString(json['uses']),
      notes: _nullableString(json['notes']),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'atomicNumber': atomicNumber,
    'symbol': symbol,
    'nameZh': nameZh,
    'nameEn': nameEn,
    'atomicMass': atomicMass,
    'atomicMassType': atomicMassType.name,
    'representativeMassNumber': representativeMassNumber,
    'period': period,
    'group': group,
    'displayRow': displayRow,
    'displayColumn': displayColumn,
    'category': category.name,
    'block': block,
    'valenceConfiguration': valenceConfiguration,
    'electronConfiguration': electronConfiguration,
    'valenceConfigurationData': valenceConfigurationData.toJson(),
    'electronConfigurationData': electronConfigurationData.toJson(),
    'shellDistribution': shellDistribution,
    'phaseAtStp': phaseAtStp,
    'density': density,
    'densityUnit': densityUnit,
    'meltingPointK': meltingPointK,
    'boilingPointK': boilingPointK,
    'electronegativityPauling': electronegativityPauling,
    'atomicRadiusPm': atomicRadiusPm,
    'oxidationStates': oxidationStates,
    'discoveryYear': discoveryYear,
    'discoverer': discoverer,
    'uses': uses,
    'notes': notes,
  };

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Expected integer, got $value');
  }

  static int? _nullableInt(Object? value) => value == null ? null : _int(value);

  static double? _nullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw FormatException('Expected number, got $value');
  }

  static String _string(Object? value) => value?.toString() ?? '';

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static ElementCategory _category(Object? value) {
    if (value is ElementCategory) return value;
    final name = _string(value);
    return ElementCategory.values.firstWhere(
      (item) => item.name == name,
      orElse: () => ElementCategory.unknown,
    );
  }

  static AtomicMassType _atomicMassType(
    Object? value, {
    required String atomicMass,
  }) {
    final name = _string(value);
    return AtomicMassType.values.firstWhere(
      (item) => item.name == name,
      orElse: () => atomicMass.startsWith('[')
          ? AtomicMassType.representativeMassNumber
          : AtomicMassType.standardAtomicWeight,
    );
  }

  static ElectronConfiguration _configuration(
    Object? value, {
    required String fallback,
  }) {
    if (value is Map<String, Object?>) {
      return ElectronConfiguration.fromJson(value);
    }
    return ElectronConfiguration.parse(fallback);
  }

  static int? _representativeMassNumber(String atomicMass) {
    final match = RegExp(r'^\[(\d+)\]$').firstMatch(atomicMass);
    return match == null ? null : int.parse(match.group(1)!);
  }
}
