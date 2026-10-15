import 'package:flutter/animation.dart';

class AppMotion {
  const AppMotion._();

  static const detailDuration = Duration(milliseconds: 420);
  static const seriesDuration = Duration(milliseconds: 460);
  static const modeDuration = Duration(milliseconds: 500);
  static const feedbackDuration = Duration(milliseconds: 1120);

  static const standardCurve = Curves.easeOutCubic;
  static const emphasisCurve = Curves.easeInOutCubic;
}
