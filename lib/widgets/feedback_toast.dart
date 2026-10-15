import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

enum FeedbackKind { success, error }

class FeedbackToast extends StatefulWidget {
  const FeedbackToast({
    super.key,
    required this.message,
    required this.kind,
    required this.onDismissed,
  });

  final String message;
  final FeedbackKind kind;
  final VoidCallback onDismissed;

  @override
  State<FeedbackToast> createState() => _FeedbackToastState();
}

class _FeedbackToastState extends State<FeedbackToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.feedbackDuration,
  );

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 16,
    ),
    TweenSequenceItem(tween: ConstantTween(1), weight: 68),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 16,
    ),
  ]).animate(_controller);

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.86,
        end: 1.035,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 24,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.035,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 12,
    ),
    TweenSequenceItem(tween: ConstantTween(1), weight: 64),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener(_handleStatus)
      ..forward();
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onDismissed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.kind == FeedbackKind.success
        ? AppColors.success
        : const Color(0xFFFF8D98);
    final icon = widget.kind == FeedbackKind.success
        ? Icons.check_circle_outline
        : Icons.error_outline;
    final maxWidth = (MediaQuery.sizeOf(context).width * 0.72)
        .clamp(220.0, 440.0)
        .toDouble();

    return IgnorePointer(
      child: SafeArea(
        minimum: const EdgeInsets.only(top: 8),
        child: Align(
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 170, maxWidth: maxWidth),
                child: IntrinsicWidth(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent, width: 1.1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 19, color: accent),
                          const SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
