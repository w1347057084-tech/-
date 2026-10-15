import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:periodic_table_study/data/element_repository.dart';
import 'package:periodic_table_study/models/element_data.dart';

void main() {
  late List<ElementData> elements;

  setUpAll(() async {
    final repository = ElementRepository(
      loader: () => File('assets/data/elements.json').readAsString(),
    );
    await repository.load();
    elements = repository.elements;
  });

  test('contains exactly 118 continuous elements', () {
    expect(elements, hasLength(118));
    expect(
      elements.map((element) => element.atomicNumber),
      orderedEquals(List<int>.generate(118, (index) => index + 1)),
    );
  });

  test('symbols and display coordinates are unique', () {
    expect(elements.map((element) => element.symbol).toSet(), hasLength(118));
    expect(
      elements
          .map((element) => '${element.displayRow}:${element.displayColumn}')
          .toSet(),
      hasLength(118),
    );
  });

  test('lanthanides and actinides keep their true periods', () {
    final lanthanides = elements.where(
      (element) => element.category == ElementCategory.lanthanide,
    );
    final actinides = elements.where(
      (element) => element.category == ElementCategory.actinide,
    );

    expect(lanthanides, hasLength(15));
    expect(lanthanides.every((element) => element.period == 6), isTrue);
    expect(lanthanides.every((element) => element.displayRow == 9), isTrue);
    expect(actinides, hasLength(15));
    expect(actinides.every((element) => element.period == 7), isTrue);
    expect(actinides.every((element) => element.displayRow == 10), isTrue);
  });

  test('electron shell totals match atomic numbers', () {
    for (final element in elements) {
      expect(
        element.shellDistribution.fold<int>(0, (sum, value) => sum + value),
        element.atomicNumber,
        reason: element.symbol,
      );
    }
  });

  test('structured electron configurations match raw notation and totals', () {
    for (final element in elements) {
      expect(
        element.electronConfigurationData.isStructurallyValid,
        isTrue,
        reason: element.symbol,
      );
      expect(
        element.valenceConfigurationData.isStructurallyValid,
        isTrue,
        reason: element.symbol,
      );
      expect(
        element.electronConfigurationData.totalElectrons,
        element.atomicNumber,
        reason: element.symbol,
      );
      expect(
        element.electronConfigurationData.compactText.replaceAll(' ', ''),
        element.electronConfiguration.replaceAll(' ', ''),
        reason: element.symbol,
      );
      expect(
        element.valenceConfigurationData.compactText.replaceAll(' ', ''),
        element.valenceConfiguration.replaceAll(' ', ''),
        reason: element.symbol,
      );
    }
  });

  test('notes do not duplicate unformatted electron configurations', () {
    for (final element in elements) {
      if (element.notes == null) continue;
      expect(
        RegExp(r'[1-7][spdf]\d').hasMatch(element.notes!),
        isFalse,
        reason: element.symbol,
      );
    }
  });

  test('known electron configuration exceptions are represented', () {
    final repository = ElementRepository(
      loader: () => File('assets/data/elements.json').readAsString(),
    );
    return repository.load().then((_) {
      expect(
        repository.byAtomicNumber(24).electronConfiguration,
        contains('3d5 4s1'),
      );
      expect(
        repository.byAtomicNumber(29).electronConfiguration,
        contains('3d10 4s1'),
      );
      expect(
        repository.byAtomicNumber(78).electronConfiguration,
        contains('5d9 6s1'),
      );
      expect(
        repository.byAtomicNumber(103).electronConfiguration,
        contains('7p1'),
      );
      expect(repository.byAtomicNumber(68).valenceConfiguration, '4f12 6s2');
      expect(repository.byAtomicNumber(92).valenceConfiguration, '5f3 6d1 7s2');
    });
  });

  test('JSON fields include explicit missing values', () {
    final raw =
        jsonDecode(File('assets/data/elements.json').readAsStringSync())
            as List<Object?>;
    final helium =
        raw.firstWhere(
              (item) => (item! as Map<String, Object?>)['symbol'] == 'He',
            )
            as Map<String, Object?>;
    expect(helium, contains('electronegativityPauling'));
    expect(helium['electronegativityPauling'], isNull);
    expect(helium['notes'], isNull);
  });

  test(
    'atomic mass display precision is consistent and preserves brackets',
    () {
      final hydrogen = elements.firstWhere((element) => element.symbol == 'H');
      final helium = elements.firstWhere((element) => element.symbol == 'He');
      final technetium = elements.firstWhere(
        (element) => element.symbol == 'Tc',
      );

      expect(hydrogen.displayAtomicMass, '1.008');
      expect(hydrogen.atomicMassType, AtomicMassType.standardAtomicWeight);
      expect(helium.displayAtomicMass, '4.0026');
      expect(technetium.displayAtomicMass, '[98]');
      expect(
        technetium.atomicMassType,
        AtomicMassType.representativeMassNumber,
      );
      expect(technetium.representativeMassNumber, 98);
    },
  );
}
