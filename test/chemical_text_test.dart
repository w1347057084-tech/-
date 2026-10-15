import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:periodic_table_study/models/electron_configuration.dart';
import 'package:periodic_table_study/widgets/chemical_text.dart';

void main() {
  test('formula parser distinguishes subscripts and ionic charges', () {
    final water = ChemicalFormulaText.parseFormula('H_2O');
    expect(water[1].text, '2');
    expect(water[1].script, ChemicalScript.subscript);

    final sulfate = ChemicalFormulaText.parseFormula('SO_4^2-');
    expect(sulfate.last.text, '2-');
    expect(sulfate.last.script, ChemicalScript.superscript);

    final iron = ChemicalFormulaText.parseFormula('Fe^3+');
    expect(iron.last.text, '3+');
    expect(iron.last.script, ChemicalScript.superscript);
  });

  test(
    'structured electron configuration rejects invalid orbital capacities',
    () {
      expect(
        const ElectronConfiguration(
          nobleGasCore: null,
          orbitals: [OrbitalOccupancy(orbital: '2p', electrons: 7)],
        ).isStructurallyValid,
        isFalse,
      );
      expect(
        const ElectronConfiguration(
          nobleGasCore: 'Ar',
          orbitals: [OrbitalOccupancy(orbital: '3d', electrons: 5)],
        ).totalElectrons,
        23,
      );
    },
  );

  testWidgets('electron configuration renders counts as superscript spans', (
    tester,
  ) async {
    final configuration = ElectronConfiguration.parse('[Ar]3d5 4s1');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ElectronConfigurationText(configuration: configuration),
        ),
      ),
    );

    final text = tester.widget<Text>(
      find
          .descendant(
            of: find.byType(ElectronConfigurationText),
            matching: find.byWidgetPredicate(
              (widget) => widget is Text && widget.textSpan != null,
            ),
          )
          .first,
    );
    final root = text.textSpan! as TextSpan;
    final superscripts = root.children!.whereType<WidgetSpan>().toList();
    expect(superscripts, hasLength(2));
    expect(((superscripts[0].child as Transform).child! as Text).data, '5');
    expect(((superscripts[1].child as Transform).child! as Text).data, '1');
  });

  testWidgets('isotope notation places mass and atomic numbers before symbol', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IsotopeSymbolText(massNumber: 13, atomicNumber: 6, symbol: 'C'),
        ),
      ),
    );

    expect(find.byType(IsotopeSymbolText), findsOneWidget);
    final text = tester.widget<Text>(
      find
          .descendant(
            of: find.byType(IsotopeSymbolText),
            matching: find.byWidgetPredicate(
              (widget) => widget is Text && widget.textSpan != null,
            ),
          )
          .first,
    );
    final root = text.textSpan! as TextSpan;
    expect(root.children!.whereType<WidgetSpan>(), hasLength(1));
    expect(root.children!.whereType<TextSpan>().single.text, 'C');
    final semantics = tester.getSemantics(find.byType(IsotopeSymbolText));
    expect(semantics.label, startsWith('13-6 C'));
    semanticsHandle.dispose();
  });
}
