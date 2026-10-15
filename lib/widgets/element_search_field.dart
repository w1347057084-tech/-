import 'package:flutter/material.dart';

import '../models/element_data.dart';
import '../theme/app_theme.dart';

class ElementSearchField extends StatefulWidget {
  const ElementSearchField({
    super.key,
    required this.elements,
    required this.onLocate,
  });

  final List<ElementData> elements;
  final ValueChanged<ElementData> onLocate;

  @override
  State<ElementSearchField> createState() => _ElementSearchFieldState();
}

class _ElementSearchFieldState extends State<ElementSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final MenuController _menuController = MenuController();
  List<ElementData> _results = const [];
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String raw) {
    final query = raw.trim();
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _results = const [];
      });
      _menuController.close();
      return;
    }

    final matches = _findMatches(query);
    setState(() {
      _query = query;
      _results = matches;
    });
    if (!_menuController.isOpen) {
      _menuController.open();
    }
  }

  List<ElementData> _findMatches(String rawQuery) {
    final query = rawQuery.toLowerCase();
    final number = int.tryParse(query);
    final matches = widget.elements
        .where((element) {
          return element.symbol.toLowerCase() == query ||
              element.symbol.toLowerCase().startsWith(query) ||
              element.nameZh.contains(rawQuery) ||
              element.nameEn.toLowerCase().contains(query) ||
              (number != null && element.atomicNumber == number);
        })
        .toList(growable: false);

    matches.sort((a, b) {
      final aExact = a.symbol.toLowerCase() == query ? 0 : 1;
      final bExact = b.symbol.toLowerCase() == query ? 0 : 1;
      final exactCompare = aExact.compareTo(bExact);
      if (exactCompare != 0) return exactCompare;
      final aStarts = a.symbol.toLowerCase().startsWith(query) ? 0 : 1;
      final bStarts = b.symbol.toLowerCase().startsWith(query) ? 0 : 1;
      final startsCompare = aStarts.compareTo(bStarts);
      if (startsCompare != 0) return startsCompare;
      return a.atomicNumber.compareTo(b.atomicNumber);
    });
    return matches.take(8).toList(growable: false);
  }

  void _select(ElementData element) {
    _controller.clear();
    _menuController.close();
    _focusNode.unfocus();
    widget.onLocate(element);
  }

  void _clear() {
    _controller.clear();
    _menuController.close();
    setState(() {
      _query = '';
      _results = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * 0.19)
        .clamp(170.0, 245.0)
        .toDouble();

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.panel),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(5)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
      menuChildren: [
        if (_query.isNotEmpty && _results.isEmpty)
          SizedBox(
            width: width,
            height: 42,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 7),
                Text('未找到匹配元素'),
              ],
            ),
          )
        else
          for (final element in _results)
            MenuItemButton(
              key: ValueKey('search-result-${element.atomicNumber}'),
              onPressed: () => _select(element),
              child: SizedBox(
                width: width - 16,
                child: _SearchResultRow(element: element),
              ),
            ),
      ],
      builder: (context, controller, child) {
        return SizedBox(
          width: width,
          height: 38,
          child: TextField(
            key: const ValueKey('element-search-field'),
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _handleChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: '搜索元素',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '清除搜索',
                      visualDensity: VisualDensity.compact,
                      onPressed: _clear,
                      icon: const Icon(Icons.close, size: 16),
                    ),
              filled: true,
              fillColor: AppColors.panelRaised,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({required this.element});

  final ElementData element;

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.categoryColors[element.category] ??
        AppColors.categoryColors[ElementCategory.unknown]!;
    return Row(
      children: [
        Container(
          width: 30,
          alignment: Alignment.center,
          child: Text(
            element.symbol,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            element.nameZh,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          'Z=${element.atomicNumber}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
