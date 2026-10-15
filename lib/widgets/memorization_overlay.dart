import 'package:flutter/material.dart';

import '../models/element_data.dart';
import '../state/memorization_state.dart';
import '../theme/app_theme.dart';
import 'progress_indicator.dart';

class CategoryLegend extends StatelessWidget {
  const CategoryLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ElementCategory.values
            .where((category) => category != ElementCategory.unknown)
            .map(
              (category) => Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.categoryColors[category],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _categoryLabel(category),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  static String _categoryLabel(ElementCategory category) {
    switch (category) {
      case ElementCategory.alkaliMetal:
        return '碱金属';
      case ElementCategory.alkalineEarthMetal:
        return '碱土金属';
      case ElementCategory.transitionMetal:
        return '过渡金属';
      case ElementCategory.postTransitionMetal:
        return '后过渡金属';
      case ElementCategory.metalloid:
        return '类金属';
      case ElementCategory.reactiveNonmetal:
        return '非金属';
      case ElementCategory.halogen:
        return '卤素';
      case ElementCategory.nobleGas:
        return '稀有气体';
      case ElementCategory.lanthanide:
        return '镧系';
      case ElementCategory.actinide:
        return '锕系';
      case ElementCategory.unknown:
        return '未知';
    }
  }
}

class PracticePanel extends StatelessWidget {
  const PracticePanel({
    super.key,
    required this.state,
    required this.onRestart,
    required this.onExit,
    required this.onHint,
  });

  final MemorizationState state;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final current = state.currentElement;
    return Row(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 210),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.border),
          ),
          child: current == null
              ? const Center(child: Text('本轮已完成'))
              : Row(
                  children: [
                    Text(
                      current.symbol,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '待放置元素',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          current.nameZh,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          current.nameEn,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StudyProgressIndicator(
            completed: state.completedCount,
            total: state.totalCount,
            progress: state.progress,
          ),
        ),
        const SizedBox(width: 14),
        FilledButton.tonalIcon(
          onPressed: onHint,
          icon: const Icon(Icons.lightbulb_outline, size: 18),
          label: const Text('提示'),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onRestart,
          tooltip: '重新开始',
          icon: const Icon(Icons.restart_alt),
        ),
        const SizedBox(width: 7),
        IconButton(
          onPressed: onExit,
          tooltip: '退出背诵模式',
          icon: const Icon(Icons.close_fullscreen),
        ),
      ],
    );
  }
}

class CompletionDialog extends StatelessWidget {
  const CompletionDialog({
    super.key,
    required this.completed,
    required this.total,
    required this.onRestart,
    required this.onExit,
  });

  final int completed;
  final int total;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  static Future<void> show(
    BuildContext context, {
    required int completed,
    required int total,
    required VoidCallback onRestart,
    required VoidCallback onExit,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CompletionDialog(
        completed: completed,
        total: total,
        onRestart: () {
          Navigator.of(dialogContext).pop();
          onRestart();
        },
        onExit: () {
          Navigator.of(dialogContext).pop();
          onExit();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0 : (completed / total * 100).round();
    return AlertDialog(
      backgroundColor: AppColors.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      icon: const Icon(
        Icons.check_circle_outline,
        size: 42,
        color: AppColors.success,
      ),
      title: const Text('本轮背诵完成', textAlign: TextAlign.center),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$completed / $total · $percentage%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text('全部待练习元素均已放入正确位置。', textAlign: TextAlign.center),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.restart_alt),
          label: const Text('再练一轮'),
        ),
        FilledButton.icon(
          onPressed: onExit,
          icon: const Icon(Icons.grid_view),
          label: const Text('返回查询'),
        ),
      ],
    );
  }
}
