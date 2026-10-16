import 'package:flutter/material.dart';

import '../models/element_data.dart';
import '../theme/app_theme.dart';
import 'chemical_text.dart';

class ElementDetailPanel extends StatelessWidget {
  const ElementDetailPanel({
    super.key,
    required this.element,
    required this.onClose,
  });

  final ElementData element;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        AppColors.categoryColors[element.category] ??
        AppColors.categoryColors[ElementCategory.unknown]!;

    // 只负责卡片本身：尺寸、遮罩与展开动画由 TransformContainer 的模态浮层决定。
    return DecoratedBox(
      key: ValueKey('element-detail-${element.atomicNumber}'),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
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
          _CompactHeader(
            element: element,
            color: categoryColor,
            onClose: onClose,
          ),
          const Divider(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 840;
                final content = wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _BasicSection(element: element),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _ElectronSection(element: element),
                                const SizedBox(height: 8),
                                _DiscoverySection(element: element),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _BasicSection(element: element),
                          const SizedBox(height: 8),
                          _ElectronSection(element: element),
                          const SizedBox(height: 8),
                          _DiscoverySection(element: element),
                        ],
                      );

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                  child: content,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.element,
    required this.color,
    required this.onClose,
  });

  final ElementData element;
  final Color color;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withAlpha(72),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: color),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                element.symbol,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        element.nameZh,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        element.nameEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Tag(text: 'Z=${element.atomicNumber}'),
                    _Tag(text: '周期 ${element.period}'),
                    _Tag(text: '族 ${element.groupLabel}'),
                    _Tag(text: element.categoryLabel, color: color),
                  ],
                ),
              ],
            ),
          ),
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

class _BasicSection extends StatelessWidget {
  const _BasicSection({required this.element});

  final ElementData element;

  @override
  Widget build(BuildContext context) {
    return _SectionBlock(
      title: '基础属性',
      icon: Icons.science_outlined,
      properties: [
        _Property(_atomicMassLabel(element), _atomicMassValue(element)),
        _Property('标准状态', element.phaseAtStp),
        _Property('密度', _density(element)),
        _Property('熔点', _temperature(element.meltingPointK)),
        _Property('沸点', _temperature(element.boilingPointK)),
        _Property('电负性', _number(element.electronegativityPauling)),
        _Property('原子半径', _radius(element.atomicRadiusPm)),
        _Property('常见氧化态', _value(element.oxidationStates)),
      ],
    );
  }
}

class _ElectronSection extends StatelessWidget {
  const _ElectronSection({required this.element});

  final ElementData element;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.25);
    return _SectionBlock(
      title: '电子结构',
      icon: Icons.blur_circular,
      properties: [
        _Property(
          '价层构型',
          ElectronConfigurationText(
            configuration: element.valenceConfigurationData,
            style: valueStyle,
          ),
          wide: true,
        ),
        _Property(
          '电子排布',
          ElectronConfigurationText(
            configuration: element.electronConfigurationData,
            style: valueStyle,
          ),
          wide: true,
        ),
        _Property('电子层', element.shellDistribution.join(' · '), wide: true),
        _Property('能级区块', '${element.block} 区'),
        if (element.notes != null)
          _Property('排布说明', element.notes!, wide: true),
      ],
    );
  }
}

class _DiscoverySection extends StatelessWidget {
  const _DiscoverySection({required this.element});

  final ElementData element;

  @override
  Widget build(BuildContext context) {
    return _SectionBlock(
      title: '发现与用途',
      icon: Icons.history_edu_outlined,
      properties: [
        _Property('发现年份', element.discoveryYear?.toString() ?? '暂无数据'),
        _Property('发现者 / 机构', _value(element.discoverer)),
        _Property('常见用途', _value(element.uses), wide: true),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.icon,
    required this.properties,
  });

  final String title;
  final IconData icon;
  final List<_Property> properties;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep.withAlpha(108),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border.withAlpha(150)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(title: title, icon: icon),
            const SizedBox(height: 6),
            _PropertyGrid(properties: properties),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _PropertyGrid extends StatelessWidget {
  const _PropertyGrid({required this.properties});

  final List<_Property> properties;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 4
            : constraints.maxWidth >= 420
            ? 2
            : 1;
        const spacing = 6.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: properties
              .map(
                (property) => SizedBox(
                  width: property.wide ? constraints.maxWidth : width,
                  child: _PropertyCard(property: property),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _Property {
  const _Property(this.label, this.value, {this.wide = false});

  final String label;
  final Object value;
  final bool wide;
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final _Property property;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.panelRaised.withAlpha(170),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.border.withAlpha(128)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              property.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 3),
            if (property.value is Widget)
              property.value as Widget
            else
              SelectableText(
                property.value.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? AppColors.panelRaised).withAlpha(150),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color ?? AppColors.border, width: 0.8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(height: 1),
      ),
    );
  }
}

String _density(ElementData element) {
  if (element.density == null) return '暂无数据';
  return '${_trim(element.density!)} ${element.densityUnit}';
}

String _atomicMassLabel(ElementData element) {
  return element.atomicMassType == AtomicMassType.representativeMassNumber
      ? '代表性同位素质量数'
      : '标准原子量';
}

String _atomicMassValue(ElementData element) {
  if (element.atomicMassType == AtomicMassType.representativeMassNumber) {
    return '${element.representativeMassNumber}';
  }
  return element.displayAtomicMass;
}

String _temperature(double? kelvin) {
  if (kelvin == null) return '暂无数据';
  final celsius = kelvin - 273.15;
  return '${_trim(kelvin)} K / ${_trim(celsius)} °C';
}

String _radius(double? value) {
  return value == null ? '暂无数据' : '${_trim(value)} pm';
}

String _number(double? value) {
  return value == null ? '暂无数据' : _trim(value);
}

String _value(String? value) {
  return value == null || value.isEmpty ? '暂无数据' : value;
}

String _trim(double value) {
  final fixed = value.toStringAsFixed(4);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
