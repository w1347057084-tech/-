import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class TransformContainer extends StatelessWidget {
  const TransformContainer({
    super.key,
    required this.routeName,
    required this.closedColor,
    required this.openColor,
    required this.middleColor,
    required this.closedBuilder,
    required this.openBuilder,
    this.transitionDuration = AppMotion.detailDuration,
  });

  final String routeName;
  final Color closedColor;
  final Color openColor;
  final Color middleColor;
  final Widget Function(VoidCallback open) closedBuilder;
  final Widget Function(VoidCallback close) openBuilder;
  final Duration transitionDuration;

  @override
  Widget build(BuildContext context) {
    return OpenContainer<bool>(
      transitionDuration: transitionDuration,
      transitionType: ContainerTransitionType.fade,
      closedColor: closedColor,
      middleColor: middleColor,
      openColor: openColor,
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      openShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      routeSettings: RouteSettings(name: routeName),
      tappable: false,
      closedBuilder: (context, openContainer) {
        return closedBuilder(openContainer);
      },
      openBuilder: (context, action) {
        return openBuilder(() => action());
      },
    );
  }
}
