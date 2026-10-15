import 'package:flutter/material.dart';

import '../models/element_data.dart';
import '../theme/app_theme.dart';

class ElementTile extends StatelessWidget {
  const ElementTile({
    super.key,
    required this.element,
    required this.hidden,
    required this.completed,
    required this.onTap,
    this.isWrong = false,
  });

  final ElementData element;
  final bool hidden;
  final bool completed;
  final VoidCallback onTap;
  final bool isWrong;

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        AppColors.categoryColors[element.category] ??
        AppColors.categoryColors[ElementCategory.unknown]!;
    final borderColor = isWrong
        ? const Color(0xFFFF6B7A)
        : completed
        ? AppColors.success
        : categoryColor.withAlpha(230);
    final fillColor = hidden
        ? AppColors.backgroundDeep.withAlpha(209)
        : categoryColor.withAlpha(230);

    return Semantics(
      button: true,
      label: hidden ? '待放置元素位置' : '${element.nameZh} ${element.symbol}',
      child: AnimatedScale(
        scale: isWrong ? 0.94 : 1,
        duration: const Duration(milliseconds: 140),
        child: Material(
          color: fillColor,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: borderColor,
                  width: completed ? 1.5 : 0.8,
                ),
              ),
              child: hidden
                  ? const _HiddenTileContent()
                  : _VisibleTileContent(element: element),
            ),
          ),
        ),
      ),
    );
  }
}

class _VisibleTileContent extends StatelessWidget {
  const _VisibleTileContent({required this.element});

  final ElementData element;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final topSize = (height * 0.13).clamp(7.0, 15.0).toDouble();
        final symbolSize = (height * 0.38).clamp(12.0, 36.0).toDouble();
        final zhSize = (height * 0.20).clamp(7.5, 18.0).toDouble();
        final massSize = (height * 0.12).clamp(6.0, 13.0).toDouble();

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: (constraints.maxWidth * 0.07)
                .clamp(3.0, 8.0)
                .toDouble(),
            vertical: (height * 0.05).clamp(1.5, 5.0).toDouble(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${element.atomicNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: topSize,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          color: AppColors.textPrimary.withAlpha(245),
                        ),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          element.displayAtomicMass,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: massSize,
                            height: 1,
                            color: AppColors.textPrimary.withAlpha(209),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    element.symbol,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: symbolSize,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: Text(
                      element.nameZh,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: zhSize,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HiddenTileContent extends StatelessWidget {
  const _HiddenTileContent();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dotSize = (constraints.maxHeight * 0.09)
            .clamp(2.5, 5.0)
            .toDouble();
        return Center(
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withAlpha(89),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class SeriesMarkerTile extends StatelessWidget {
  const SeriesMarkerTile({
    super.key,
    required this.label,
    required this.range,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String range;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(184),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      range,
                      style: TextStyle(
                        fontSize: (height * 0.22).clamp(7, 18).toDouble(),
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: (height * 0.08).clamp(1, 4).toDouble()),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: (height * 0.18).clamp(6, 15).toDouble(),
                        height: 1,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
