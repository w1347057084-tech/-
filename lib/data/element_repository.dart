import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/element_data.dart';

class ElementRepository {
  ElementRepository({Future<String> Function()? loader})
    : _loader = loader ?? _loadBundledData;

  final Future<String> Function() _loader;
  List<ElementData> _elements = const [];

  List<ElementData> get elements => List.unmodifiable(_elements);

  Future<void> load() async {
    final raw = await _loader();
    final decoded = jsonDecode(raw);
    if (decoded is! List<Object?>) {
      throw const FormatException('elements.json 顶层必须是数组');
    }

    final parsed = decoded
        .map((item) {
          if (item is! Map<String, Object?>) {
            throw const FormatException('元素记录必须是 JSON 对象');
          }
          return ElementData.fromJson(item);
        })
        .toList(growable: false);

    _validate(parsed);
    _elements = List<ElementData>.unmodifiable(parsed);
  }

  ElementData byAtomicNumber(int atomicNumber) {
    return _elements.firstWhere(
      (element) => element.atomicNumber == atomicNumber,
      orElse: () => throw StateError('找不到原子序数 $atomicNumber'),
    );
  }

  ElementData? bySymbol(String symbol) {
    for (final element in _elements) {
      if (element.symbol == symbol) return element;
    }
    return null;
  }

  static Future<String> _loadBundledData() {
    return rootBundle.loadString('assets/data/elements.json');
  }

  static void _validate(List<ElementData> elements) {
    if (elements.length != 118) {
      throw FormatException('元素数量应为 118，实际为 ${elements.length}');
    }

    final numbers = <int>{};
    final symbols = <String>{};
    final coordinates = <String>{};
    const validRows = <int>{1, 2, 3, 4, 5, 6, 7, 9, 10};

    for (final element in elements) {
      if (element.atomicNumber < 1 || element.atomicNumber > 118) {
        throw FormatException('无效原子序数: ${element.atomicNumber}');
      }
      if (!numbers.add(element.atomicNumber)) {
        throw FormatException('重复原子序数: ${element.atomicNumber}');
      }
      if (!symbols.add(element.symbol)) {
        throw FormatException('重复元素符号: ${element.symbol}');
      }
      if (element.period < 1 || element.period > 7) {
        throw FormatException('${element.symbol} 的周期无效');
      }
      if (!element.isFBlock &&
          (element.group == null ||
              element.group! < 1 ||
              element.group! > 18)) {
        throw FormatException('${element.symbol} 的族信息无效');
      }
      if (!const {'s', 'p', 'd', 'f'}.contains(element.block)) {
        throw FormatException('${element.symbol} 的能级区块无效');
      }
      if (element.category == ElementCategory.lanthanide &&
          (element.period != 6 || element.displayRow != 9)) {
        throw FormatException('${element.symbol} 的镧系周期或显示位置错误');
      }
      if (element.category == ElementCategory.actinide &&
          (element.period != 7 || element.displayRow != 10)) {
        throw FormatException('${element.symbol} 的锕系周期或显示位置错误');
      }
      if (element.symbol.isEmpty ||
          element.nameZh.isEmpty ||
          element.nameEn.isEmpty ||
          element.atomicMass.isEmpty) {
        throw FormatException('${element.symbol} 的基础字段不完整');
      }
      if ((element.density != null && element.density! < 0) ||
          (element.meltingPointK != null && element.meltingPointK! <= 0) ||
          (element.boilingPointK != null && element.boilingPointK! <= 0) ||
          (element.atomicRadiusPm != null && element.atomicRadiusPm! <= 0) ||
          (element.electronegativityPauling != null &&
              (element.electronegativityPauling! < 0 ||
                  element.electronegativityPauling! > 4))) {
        throw FormatException('${element.symbol} 存在异常物性数值');
      }
      if (element.displayColumn < 1 || element.displayColumn > 18) {
        throw FormatException('${element.symbol} 的显示列无效');
      }
      if (!validRows.contains(element.displayRow)) {
        throw FormatException('${element.symbol} 的显示行无效');
      }
      final coordinate = '${element.displayRow}:${element.displayColumn}';
      if (!coordinates.add(coordinate)) {
        throw FormatException('${element.symbol} 与另一元素坐标冲突: $coordinate');
      }
      if (element.atomicMassType == AtomicMassType.representativeMassNumber) {
        if (element.representativeMassNumber == null ||
            element.atomicMass != '[${element.representativeMassNumber}]') {
          throw FormatException('${element.symbol} 的代表性质量数标记无效');
        }
      } else if (element.representativeMassNumber != null) {
        throw FormatException('${element.symbol} 的标准原子量标记无效');
      }
      if (!element.electronConfigurationData.isStructurallyValid ||
          !element.valenceConfigurationData.isStructurallyValid) {
        throw FormatException('${element.symbol} 的电子排布结构无效');
      }
      if (element.electronConfigurationData.totalElectrons !=
          element.atomicNumber) {
        throw FormatException('${element.symbol} 的电子排布电子数错误');
      }
      if (element.electronConfigurationData.compactText.replaceAll(' ', '') !=
              element.electronConfiguration.replaceAll(RegExp(r'\s+'), '') ||
          element.valenceConfigurationData.compactText.replaceAll(' ', '') !=
              element.valenceConfiguration.replaceAll(RegExp(r'\s+'), '')) {
        throw FormatException('${element.symbol} 的电子排布结构不一致');
      }
      if (element.shellDistribution.fold<int>(0, (sum, value) => sum + value) !=
          element.atomicNumber) {
        throw FormatException('${element.symbol} 的电子层分布总和错误');
      }
    }

    for (var number = 1; number <= 118; number++) {
      if (!numbers.contains(number)) {
        throw FormatException('缺少原子序数 $number');
      }
    }
  }
}
