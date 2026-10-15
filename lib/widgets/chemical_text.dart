import 'package:flutter/material.dart';

import '../models/electron_configuration.dart';

enum ChemicalScript {
  normal,
  subscript,
  superscript,
  preSubscript,
  preSuperscript,
}

class ChemicalToken {
  const ChemicalToken(this.text, [this.script = ChemicalScript.normal]);

  final String text;
  final ChemicalScript script;
}

class ChemicalFormulaText extends StatelessWidget {
  const ChemicalFormulaText({
    super.key,
    required this.tokens,
    this.style,
    this.semanticsLabel,
  });

  final List<ChemicalToken> tokens;
  final TextStyle? style;
  final String? semanticsLabel;

  factory ChemicalFormulaText.fromFormula(
    String formula, {
    Key? key,
    TextStyle? style,
    String? semanticsLabel,
  }) {
    return ChemicalFormulaText(
      key: key,
      tokens: parseFormula(formula),
      style: style,
      semanticsLabel: semanticsLabel,
    );
  }

  static List<ChemicalToken> parseFormula(String formula) {
    final tokens = <ChemicalToken>[];
    var index = 0;
    while (index < formula.length) {
      final character = formula[index];
      if (character == '_' || character == '^') {
        final script = character == '_'
            ? ChemicalScript.subscript
            : ChemicalScript.superscript;
        final start = ++index;
        while (index < formula.length &&
            !RegExp(r'[A-Za-z_^]').hasMatch(formula[index])) {
          index++;
        }
        tokens.add(ChemicalToken(formula.substring(start, index), script));
        continue;
      }
      if (RegExp(r'\d').hasMatch(character)) {
        final start = index;
        while (index < formula.length &&
            RegExp(r'\d').hasMatch(formula[index])) {
          index++;
        }
        tokens.add(
          ChemicalToken(
            formula.substring(start, index),
            ChemicalScript.subscript,
          ),
        );
        continue;
      }

      final start = index;
      while (index < formula.length &&
          !RegExp(r'[\d_^]').hasMatch(formula[index])) {
        index++;
      }
      tokens.add(ChemicalToken(formula.substring(start, index)));
    }
    return List.unmodifiable(tokens);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final spans = <InlineSpan>[];
    for (final token in tokens) {
      if (token.script == ChemicalScript.normal) {
        spans.add(TextSpan(text: token.text, style: effectiveStyle));
        continue;
      }
      final isSuperscript =
          token.script == ChemicalScript.superscript ||
          token.script == ChemicalScript.preSuperscript;
      spans.add(
        WidgetSpan(
          alignment: isSuperscript
              ? PlaceholderAlignment.top
              : PlaceholderAlignment.bottom,
          child: Transform.translate(
            offset: Offset(0, isSuperscript ? -3 : 2),
            child: Text(
              token.text,
              style: effectiveStyle.copyWith(
                fontSize: (effectiveStyle.fontSize ?? 14) * 0.66,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: semanticsLabel ?? _plainLabel(tokens),
      child: Text.rich(
        TextSpan(style: effectiveStyle, children: spans),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
      ),
    );
  }

  static String _plainLabel(List<ChemicalToken> tokens) {
    const superscript = {
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
      '+': '⁺',
      '-': '⁻',
    };
    const subscript = {
      '0': '₀',
      '1': '₁',
      '2': '₂',
      '3': '₃',
      '4': '₄',
      '5': '₅',
      '6': '₆',
      '7': '₇',
      '8': '₈',
      '9': '₉',
    };
    final buffer = StringBuffer();
    for (final token in tokens) {
      final map =
          token.script == ChemicalScript.superscript ||
              token.script == ChemicalScript.preSuperscript
          ? superscript
          : token.script == ChemicalScript.subscript ||
                token.script == ChemicalScript.preSubscript
          ? subscript
          : null;
      buffer.write(
        map == null
            ? token.text
            : token.text.split('').map((char) => map[char] ?? char).join(),
      );
    }
    return buffer.toString();
  }
}

class IsotopeSymbolText extends StatelessWidget {
  const IsotopeSymbolText({
    super.key,
    required this.massNumber,
    required this.atomicNumber,
    required this.symbol,
    this.style,
  });

  final int massNumber;
  final int atomicNumber;
  final String symbol;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final fontSize = effectiveStyle.fontSize ?? 14;
    final smallStyle = effectiveStyle.copyWith(
      fontSize: fontSize * 0.62,
      height: 1,
      fontWeight: FontWeight.w700,
    );
    return Semantics(
      label: '$massNumber-$atomicNumber $symbol',
      child: Text.rich(
        TextSpan(
          style: effectiveStyle,
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: SizedBox(
                width: fontSize * 1.25,
                height: fontSize * 1.85,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      right: 1,
                      child: Text('$massNumber', style: smallStyle),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 1,
                      child: Text('$atomicNumber', style: smallStyle),
                    ),
                  ],
                ),
              ),
            ),
            TextSpan(text: symbol, style: effectiveStyle),
          ],
        ),
      ),
    );
  }
}

class ElectronConfigurationText extends StatelessWidget {
  const ElectronConfigurationText({
    super.key,
    required this.configuration,
    this.style,
  });

  final ElectronConfiguration configuration;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final tokens = <ChemicalToken>[];
    if (configuration.nobleGasCore != null) {
      tokens.add(ChemicalToken('[${configuration.nobleGasCore}]'));
    }
    for (final orbital in configuration.orbitals) {
      if (tokens.isNotEmpty) tokens.add(const ChemicalToken(' '));
      tokens
        ..add(ChemicalToken(orbital.orbital))
        ..add(
          ChemicalToken('${orbital.electrons}', ChemicalScript.superscript),
        );
    }
    return ChemicalFormulaText(
      tokens: tokens,
      style: style,
      semanticsLabel: configuration.compactText,
    );
  }
}
