import 'package:flutter/material.dart';

import '../models/element_data.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFF06142C);
  static const backgroundDeep = Color(0xFF030D1D);
  static const panel = Color(0xFF0B2246);
  static const panelRaised = Color(0xFF102B55);
  static const border = Color(0xFF1D456D);
  static const textPrimary = Color(0xFFE4F0FF);
  static const textSecondary = Color(0xFF91AFCE);
  static const accent = Color(0xFF4DB8FF);
  static const success = Color(0xFF55D6A7);
  static const warning = Color(0xFFFFCE68);

  static const categoryColors = <ElementCategory, Color>{
    ElementCategory.alkaliMetal: Color(0xFFB64A67),
    ElementCategory.alkalineEarthMetal: Color(0xFF9B526A),
    ElementCategory.transitionMetal: Color(0xFF315F89),
    ElementCategory.postTransitionMetal: Color(0xFF3A8078),
    ElementCategory.metalloid: Color(0xFF677F54),
    ElementCategory.reactiveNonmetal: Color(0xFF347A64),
    ElementCategory.halogen: Color(0xFF2D7E8D),
    ElementCategory.nobleGas: Color(0xFF6B4F9B),
    ElementCategory.lanthanide: Color(0xFF3D866E),
    ElementCategory.actinide: Color(0xFF3D837F),
    ElementCategory.unknown: Color(0xFF5B6478),
  };
}

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      surface: AppColors.background,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamilyFallback: const [
        'Microsoft YaHei',
        'Noto Sans CJK SC',
        'PingFang SC',
      ],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xE91A2940),
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.panelRaised,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    );
  }
}
