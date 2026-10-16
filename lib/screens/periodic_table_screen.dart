import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/element_repository.dart';
import '../models/element_data.dart';
import '../services/gesture_service.dart';
import '../state/memorization_state.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/element_detail_panel.dart';
import '../widgets/element_search_field.dart';
import '../widgets/element_tile.dart';
import '../widgets/feedback_toast.dart';
import '../widgets/memorization_overlay.dart';
import '../widgets/series_panel.dart';
import '../widgets/transform_container.dart';

class PeriodicTableScreen extends StatefulWidget {
  const PeriodicTableScreen({super.key, required this.repository});

  final ElementRepository repository;

  @override
  State<PeriodicTableScreen> createState() => _PeriodicTableScreenState();
}

class _PeriodicTableScreenState extends State<PeriodicTableScreen>
    with SingleTickerProviderStateMixin {
  late final MemorizationState _memorization = MemorizationState(
    elements: widget.repository.elements,
  );
  late final List<ElementData> _lanthanides = widget.repository.elements
      .where((element) => element.category == ElementCategory.lanthanide)
      .toList(growable: false);
  late final List<ElementData> _actinides = widget.repository.elements
      .where((element) => element.category == ElementCategory.actinide)
      .toList(growable: false);
  final GestureService _gestureService = GestureService();

  late final AnimationController _modeController = AnimationController(
    vsync: this,
    duration: AppMotion.modeDuration,
  );
  late final Animation<double> _modeOpacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeInCubic)),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 50,
    ),
  ]).animate(_modeController);

  Timer? _wrongTimer;
  Timer? _gestureTapTimer;
  Timer? _highlightTimer;
  OverlayEntry? _feedbackEntry;
  int? _wrongAtomicNumber;
  int? _highlightedAtomicNumber;
  int? _lastCurrentAtomicNumber;
  int _highlightSequence = 0;
  bool? _pendingPractice;
  bool _modeCommitted = false;
  bool _ignoreTapsAfterGesture = false;
  bool _completionDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _memorization.addListener(_handleMemorizationChanged);
    _modeController.addListener(_handleModeAnimation);
  }

  @override
  void dispose() {
    _wrongTimer?.cancel();
    _gestureTapTimer?.cancel();
    _highlightTimer?.cancel();
    _removeFeedback();
    _modeController
      ..removeListener(_handleModeAnimation)
      ..dispose();
    _memorization
      ..removeListener(_handleMemorizationChanged)
      ..dispose();
    super.dispose();
  }

  void _handleModeAnimation() {
    if (!_modeCommitted &&
        _modeController.value >= 0.5 &&
        _pendingPractice != null) {
      _modeCommitted = true;
      if (_pendingPractice!) {
        _memorization.start();
      } else {
        _memorization.exit();
      }
    }
  }

  void _requestMode(bool practice) {
    final currentPractice =
        _memorization.isPracticing || _memorization.isComplete;
    if (_modeController.isAnimating || currentPractice == practice) return;
    _clearHighlight();
    _pendingPractice = practice;
    _modeCommitted = false;
    _modeController.forward(from: 0);
  }

  void _handleMemorizationChanged() {
    if (!mounted) return;
    final currentAtomicNumber = _memorization.currentElement?.atomicNumber;
    if (currentAtomicNumber != _lastCurrentAtomicNumber) {
      _lastCurrentAtomicNumber = currentAtomicNumber;
      _highlightTimer?.cancel();
      _highlightedAtomicNumber = null;
    }
    setState(() {});
    if (_memorization.isComplete && !_completionDialogOpen) {
      _completionDialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        CompletionDialog.show(
          context,
          completed: _memorization.completedCount,
          total: _memorization.totalCount,
          onRestart: _restartMemorization,
          onExit: () {
            _completionDialogOpen = false;
            _requestMode(false);
          },
        ).whenComplete(() {
          if (_memorization.isComplete) {
            _requestMode(false);
          }
          _completionDialogOpen = false;
        });
      });
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_gestureService.handlePointerDown(event)) {
      _ignoreTapsAfterGesture = true;
      _gestureTapTimer?.cancel();
      _gestureTapTimer = Timer(const Duration(milliseconds: 350), () {
        _ignoreTapsAfterGesture = false;
      });
      final practice = _memorization.isPracticing || _memorization.isComplete;
      _requestMode(!practice);
    }
  }

  void _handleElementTap(ElementData element) {
    if (_ignoreTapsAfterGesture || !_memorization.isPracticing) return;

    _clearHighlight();
    final result = _memorization.submit(element);
    if (result == AttemptResult.correct) {
      _showFeedback('放置正确', FeedbackKind.success);
    } else if (result == AttemptResult.wrong) {
      _wrongTimer?.cancel();
      setState(() => _wrongAtomicNumber = element.atomicNumber);
      _wrongTimer = Timer(const Duration(milliseconds: 420), () {
        if (mounted) setState(() => _wrongAtomicNumber = null);
      });
      _showFeedback('位置不对，请继续尝试', FeedbackKind.error);
    }
  }

  void _showFeedback(String message, FeedbackKind kind) {
    _removeFeedback();
    final entry = OverlayEntry(
      builder: (context) => FeedbackToast(
        key: UniqueKey(),
        message: message,
        kind: kind,
        onDismissed: _removeFeedback,
      ),
    );
    _feedbackEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _removeFeedback() {
    final entry = _feedbackEntry;
    _feedbackEntry = null;
    if (entry != null && entry.mounted) {
      entry.remove();
    }
  }

  void _locateElement(ElementData element) {
    _highlightElement(element, const Duration(milliseconds: 1500));
  }

  void _showHint() {
    final current = _memorization.currentElement;
    if (current == null) return;
    _highlightElement(current, const Duration(milliseconds: 1800));
  }

  void _highlightElement(ElementData element, Duration duration) {
    _highlightTimer?.cancel();
    setState(() {
      _highlightedAtomicNumber = element.atomicNumber;
      _highlightSequence++;
    });
    _highlightTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() => _highlightedAtomicNumber = null);
    });
  }

  void _clearHighlight() {
    _highlightTimer?.cancel();
    if (_highlightedAtomicNumber != null) {
      setState(() => _highlightedAtomicNumber = null);
    }
  }

  void _restartMemorization() {
    _clearHighlight();
    _memorization.restart();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerUp: _gestureService.handlePointerUp,
      onPointerCancel: _gestureService.handlePointerCancel,
      child: Scaffold(
        body: SafeArea(
          minimum: const EdgeInsets.fromLTRB(7, 6, 7, 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final practice =
                  _memorization.isPracticing || _memorization.isComplete;
              final headerHeight = (constraints.maxHeight * 0.20)
                  .clamp(76.0, 110.0)
                  .toDouble();
              final content = Column(
                children: [
                  SizedBox(
                    height: headerHeight,
                    child: practice
                        ? PracticePanel(
                            state: _memorization,
                            onRestart: _restartMemorization,
                            onExit: () => _requestMode(false),
                            onHint: _showHint,
                          )
                        : _NormalPanel(
                            elements: widget.repository.elements,
                            onStart: () => _requestMode(true),
                            onLocate: _locateElement,
                          ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: _PeriodicTableGrid(
                      elements: widget.repository.elements,
                      lanthanides: _lanthanides,
                      actinides: _actinides,
                      queryMode: !practice,
                      hiddenPredicate: _memorization.isHidden,
                      completedPredicate: _memorization.isCompleted,
                      wrongAtomicNumber: _wrongAtomicNumber,
                      highlightedAtomicNumber: _highlightedAtomicNumber,
                      highlightSequence: _highlightSequence,
                      practiceMode: practice,
                      onElementTap: _handleElementTap,
                    ),
                  ),
                ],
              );

              return AnimatedBuilder(
                animation: _modeOpacity,
                child: content,
                builder: (context, child) {
                  return IgnorePointer(
                    ignoring: _modeController.isAnimating,
                    child: FadeTransition(opacity: _modeOpacity, child: child),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NormalPanel extends StatelessWidget {
  const _NormalPanel({
    required this.elements,
    required this.onStart,
    required this.onLocate,
  });

  final List<ElementData> elements;
  final VoidCallback onStart;
  final ValueChanged<ElementData> onLocate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 5,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '元素周期表',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'CHEMISTRY · 118 ELEMENTS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 22),
              const Expanded(child: CategoryLegend()),
              const SizedBox(width: 10),
              ElementSearchField(elements: elements, onLocate: onLocate),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                onPressed: onStart,
                icon: const Icon(Icons.fitness_center, size: 18),
                label: const Text('背诵模式'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '双指双击可快速切换',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _PeriodicTableGrid extends StatelessWidget {
  const _PeriodicTableGrid({
    required this.elements,
    required this.lanthanides,
    required this.actinides,
    required this.queryMode,
    required this.hiddenPredicate,
    required this.completedPredicate,
    required this.wrongAtomicNumber,
    required this.highlightedAtomicNumber,
    required this.highlightSequence,
    required this.practiceMode,
    required this.onElementTap,
  });

  final List<ElementData> elements;
  final List<ElementData> lanthanides;
  final List<ElementData> actinides;
  final bool queryMode;
  final bool Function(ElementData) hiddenPredicate;
  final bool Function(ElementData) completedPredicate;
  final int? wrongAtomicNumber;
  final int? highlightedAtomicNumber;
  final int highlightSequence;
  final bool practiceMode;
  final ValueChanged<ElementData> onElementTap;

  static const Map<int, String> _traditionalGroups = {
    1: 'IA',
    2: 'IIA',
    3: 'IIIB',
    4: 'IVB',
    5: 'VB',
    6: 'VIB',
    7: 'VIIB',
    11: 'IB',
    12: 'IIB',
    13: 'IIIA',
    14: 'IVA',
    15: 'VA',
    16: 'VIA',
    17: 'VIIA',
    18: 'VIIIA',
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = (constraints.maxWidth * 0.0035).clamp(2.0, 5.5).toDouble();
        final screen = MediaQuery.sizeOf(context);
        final metrics = _GridMetrics(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          gap: gap,
        );
        final highlightedElement = highlightedAtomicNumber == null
            ? null
            : _elementByNumber(highlightedAtomicNumber!);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(left: 0, top: 0, child: _AxisCornerLabel()),
            for (final group in _traditionalGroups.entries)
              Positioned.fromRect(
                rect: metrics.groupLabelRect(group.key),
                child: _AxisLabel(
                  key: ValueKey('group-label-${group.key}'),
                  text: group.value,
                  emphasized: true,
                ),
              ),
            Positioned.fromRect(
              rect: metrics.groupSpanRect(8, 10),
              child: const _AxisLabel(
                key: ValueKey('group-label-8-10'),
                text: 'VIII',
                emphasized: true,
              ),
            ),
            for (var row = 1; row <= 7; row++)
              Positioned.fromRect(
                rect: metrics.periodLabelRect(row),
                child: _AxisLabel(
                  key: ValueKey('period-label-$row'),
                  text: '$row',
                ),
              ),
            Positioned.fromRect(
              rect: metrics.periodLabelRect(9),
              child: _AxisLabel(
                key: const ValueKey('series-axis-lanthanide'),
                text: '镧',
                color: AppColors.categoryColors[ElementCategory.lanthanide]!,
              ),
            ),
            Positioned.fromRect(
              rect: metrics.periodLabelRect(10),
              child: _AxisLabel(
                key: const ValueKey('series-axis-actinide'),
                text: '锕',
                color: AppColors.categoryColors[ElementCategory.actinide]!,
              ),
            ),
            for (final element in elements)
              Positioned.fromRect(
                rect: metrics.rect(element.displayRow, element.displayColumn),
                child: RepaintBoundary(child: _buildElement(context, element)),
              ),
            if (highlightedElement != null)
              Positioned.fromRect(
                rect: metrics.rect(
                  highlightedElement.displayRow,
                  highlightedElement.displayColumn,
                ),
                child: IgnorePointer(
                  child: _HighlightMarker(
                    key: ValueKey('highlight-overlay-$highlightedAtomicNumber'),
                    sequence: highlightSequence,
                    element: highlightedElement,
                  ),
                ),
              ),
            if (!practiceMode) ...[
              Positioned.fromRect(
                rect: metrics.rect(6, 3),
                child: TransformContainer(
                  key: const ValueKey('series-container-lanthanide'),
                  routeName: '/series/lanthanide',
                  openMaxWidth: 1220,
                  openMaxHeight: (screen.height - 20).clamp(250.0, 360.0),
                  transitionDuration: AppMotion.seriesDuration,
                  closedBuilder: (openContainer) {
                    return SeriesMarkerTile(
                      label: '镧系',
                      range: '57-71',
                      color:
                          AppColors.categoryColors[ElementCategory.lanthanide]!,
                      onTap: openContainer,
                    );
                  },
                  openBuilder: (closeContainer) {
                    return SeriesPanel(
                      category: ElementCategory.lanthanide,
                      elements: lanthanides,
                      onClose: closeContainer,
                    );
                  },
                ),
              ),
              Positioned.fromRect(
                rect: metrics.rect(7, 3),
                child: TransformContainer(
                  key: const ValueKey('series-container-actinide'),
                  routeName: '/series/actinide',
                  openMaxWidth: 1220,
                  openMaxHeight: (screen.height - 20).clamp(250.0, 360.0),
                  transitionDuration: AppMotion.seriesDuration,
                  closedBuilder: (openContainer) {
                    return SeriesMarkerTile(
                      label: '锕系',
                      range: '89-103',
                      color:
                          AppColors.categoryColors[ElementCategory.actinide]!,
                      onTap: openContainer,
                    );
                  },
                  openBuilder: (closeContainer) {
                    return SeriesPanel(
                      category: ElementCategory.actinide,
                      elements: actinides,
                      onClose: closeContainer,
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildElement(BuildContext context, ElementData element) {
    Widget tileBuilder(VoidCallback onTap) {
      return ElementTile(
        element: element,
        hidden: hiddenPredicate(element),
        completed: completedPredicate(element),
        isWrong: wrongAtomicNumber == element.atomicNumber,
        onTap: onTap,
      );
    }

    if (!queryMode) {
      return tileBuilder(() => onElementTap(element));
    }

    final screen = MediaQuery.sizeOf(context);
    return TransformContainer(
      key: ValueKey('element-container-${element.atomicNumber}'),
      routeName: '/elements/${element.atomicNumber}',
      openMaxWidth: 1120,
      openMaxHeight: (screen.height - 20).clamp(260.0, 460.0),
      closedBuilder: (openContainer) => tileBuilder(openContainer),
      openBuilder: (closeContainer) {
        return ElementDetailPanel(element: element, onClose: closeContainer);
      },
    );
  }

  ElementData _elementByNumber(int atomicNumber) {
    return elements.firstWhere(
      (element) => element.atomicNumber == atomicNumber,
    );
  }
}

class _HighlightMarker extends StatelessWidget {
  const _HighlightMarker({
    super.key,
    required this.sequence,
    required this.element,
  });

  final int sequence;
  final ElementData element;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('highlight-pulse-$sequence'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      builder: (context, value, child) {
        final pulse = math.sin(math.pi * value);
        return Stack(
          fit: StackFit.expand,
          children: [
            // 提示时直接把元素填进目标格子：半透明显示，既指出位置也不当成答题结果。
            Opacity(
              opacity: 0.85,
              child: ExcludeSemantics(
                child: ElementTile(
                  key: ValueKey('hint-fill-${element.atomicNumber}'),
                  element: element,
                  hidden: false,
                  completed: false,
                  onTap: () {},
                ),
              ),
            ),
            Transform.scale(
              scale: 1 + 0.04 * pulse,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppColors.warning, width: 2.4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withAlpha(
                        (90 + 80 * pulse).round(),
                      ),
                      blurRadius: 8 + 5 * pulse,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AxisCornerLabel extends StatelessWidget {
  const _AxisCornerLabel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 18,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '族\n周期',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary.withAlpha(190),
            fontSize: 7,
            height: 1.05,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel({
    super.key,
    required this.text,
    this.color,
    this.emphasized = false,
  });

  final String text;
  final Color? color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: DecoratedBox(
        decoration: emphasized
            ? BoxDecoration(
                color: AppColors.panel.withAlpha(120),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppColors.border.withAlpha(145)),
              )
            : const BoxDecoration(),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                color:
                    color ??
                    (emphasized
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withAlpha(190)),
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridMetrics {
  _GridMetrics({required this.width, required this.height, required this.gap})
    : gutterLeft = (width * 0.023).clamp(17.0, 28.0).toDouble(),
      gutterTop = (height * 0.04).clamp(14.0, 22.0).toDouble();

  final double width;
  final double height;
  final double gap;
  final double gutterLeft;
  final double gutterTop;

  double get gridWidth => width - gutterLeft;
  double get gridHeight => height - gutterTop;
  double get cellWidth => (gridWidth - gap * 17) / 18;
  double get cellHeight => (gridHeight - gap * 9) / 10;

  Rect rect(int row, int column) {
    return Rect.fromLTWH(
      gutterLeft + (column - 1) * (cellWidth + gap),
      gutterTop + (row - 1) * (cellHeight + gap),
      cellWidth,
      cellHeight,
    );
  }

  Rect groupLabelRect(int column) {
    return Rect.fromLTWH(
      gutterLeft + (column - 1) * (cellWidth + gap),
      0,
      cellWidth,
      gutterTop,
    );
  }

  Rect groupSpanRect(int firstColumn, int lastColumn) {
    final left = gutterLeft + (firstColumn - 1) * (cellWidth + gap);
    final right = gutterLeft + (lastColumn - 1) * (cellWidth + gap) + cellWidth;
    return Rect.fromLTWH(left, 0, right - left, gutterTop);
  }

  Rect periodLabelRect(int row) {
    return Rect.fromLTWH(
      0,
      gutterTop + (row - 1) * (cellHeight + gap),
      gutterLeft,
      cellHeight,
    );
  }
}
