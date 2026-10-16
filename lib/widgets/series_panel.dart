import 'package:flutter/material.dart';

import '../models/element_data.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'element_detail_panel.dart';
import 'element_tile.dart';
import 'transform_container.dart';

class SeriesPanel extends StatelessWidget {
  const SeriesPanel({
    super.key,
    required this.category,
    required this.elements,
    required this.onClose,
  });

  final ElementCategory category;
  final List<ElementData> elements;
  final VoidCallback onClose;

  bool get isLanthanide => category == ElementCategory.lanthanide;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[category]!;
    final title = isLanthanide ? '镧系元素' : '锕系元素';
    final range = isLanthanide ? '57-71' : '89-103';
    // 只负责卡片本身：尺寸、遮罩与展开动画由 TransformContainer 的模态浮层决定。
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _SeriesHeader(
            title: title,
            range: range,
            color: color,
            count: elements.length,
            onClose: onClose,
          ),
          const Divider(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _columnsFor(constraints.maxWidth);
                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: elements.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 7,
                    mainAxisSpacing: 7,
                    childAspectRatio: constraints.maxWidth >= 900 ? 1.34 : 1.18,
                  ),
                  itemBuilder: (context, index) {
                    final element = elements[index];
                    return TransformContainer(
                      key: ValueKey('series-element-${element.atomicNumber}'),
                      routeName: '/elements/${element.atomicNumber}',
                      openMaxWidth: 1120,
                      openMaxHeight: (MediaQuery.sizeOf(context).height - 20)
                          .clamp(260.0, 460.0),
                      transitionDuration: AppMotion.detailDuration,
                      closedBuilder: (openContainer) {
                        return ElementTile(
                          element: element,
                          hidden: false,
                          completed: false,
                          onTap: openContainer,
                        );
                      },
                      openBuilder: (closeContainer) {
                        return ElementDetailPanel(
                          element: element,
                          onClose: closeContainer,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _columnsFor(double width) {
    if (width >= 1180) return 8;
    if (width >= 980) return 7;
    if (width >= 760) return 6;
    if (width >= 560) return 5;
    return 4;
  }
}

class _SeriesHeader extends StatelessWidget {
  const _SeriesHeader({
    required this.title,
    required this.range,
    required this.color,
    required this.count,
    required this.onClose,
  });

  final String title;
  final String range;
  final Color color;
  final int count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 10),
          Text(
            '$range · $count 个元素',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            tooltip: '关闭',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }
}
