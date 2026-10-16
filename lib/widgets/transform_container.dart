import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// 把元素格子（[closedBuilder]）以容器变换的方式展开为浮层卡片（[openBuilder]）。
///
/// 为什么不用 `animations` 包里的 `OpenContainer`：它推入的路由是
/// `opaque => true`（见 `_OpenContainerRoute`），动画结束后 Flutter 不再绘制下层的
/// 周期表，只能得到"整屏替换"的效果。这里改用 `showGeneralDialog` 的
/// `PopupRoute`（`opaque => false`），卡片下方始终是同一个周期表实例，
/// 只是被半透明遮罩压暗——也就是"模态卡片浮在周期表上"。
///
/// 关闭的所有权仍在调用方：点遮罩、点关闭按钮都会走 [openBuilder] 传入的 `close`
/// 回调，由它 pop 路由，动画自动反向播放回原始格子。
class TransformContainer extends StatefulWidget {
  const TransformContainer({
    super.key,
    required this.routeName,
    required this.closedBuilder,
    required this.openBuilder,
    required this.openMaxWidth,
    required this.openMaxHeight,
    this.transitionDuration = AppMotion.detailDuration,
  });

  final String routeName;
  final Widget Function(VoidCallback open) closedBuilder;
  final Widget Function(VoidCallback close) openBuilder;

  /// 展开后卡片的最大尺寸，由调用方按屏幕可用空间算出。
  final double openMaxWidth;
  final double openMaxHeight;

  final Duration transitionDuration;

  @override
  State<TransformContainer> createState() => _TransformContainerState();
}

class _TransformContainerState extends State<TransformContainer> {
  /// 只用来量取"源格子"的实际屏幕矩形，本身不产生绘制层。
  final GlobalKey _anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return MetaData(key: _anchorKey, child: widget.closedBuilder(_open));
  }

  Future<void> _open() {
    Rect? sourceRect;
    final renderObject = _anchorKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      sourceRect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    }

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭详情',
      // 近乎透明的 barrier：真正可见的遮罩在 _ModalCardTransition 里，
      // 这样遮罩浓度能和卡片动画同步；alpha 不为 0 才能保留"点空白关闭"。
      barrierColor: const Color(0x01000000),
      transitionDuration: widget.transitionDuration,
      routeSettings: RouteSettings(name: widget.routeName),
      pageBuilder: (dialogContext, _, _) =>
          widget.openBuilder(() => Navigator.of(dialogContext).pop()),
      transitionBuilder: (_, animation, _, child) => _ModalCardTransition(
        animation: animation,
        sourceRect: sourceRect,
        maxWidth: widget.openMaxWidth,
        maxHeight: widget.openMaxHeight,
        child: child,
      ),
    );
  }
}

class _ModalCardTransition extends StatelessWidget {
  const _ModalCardTransition({
    required this.animation,
    required this.sourceRect,
    required this.maxWidth,
    required this.maxHeight,
    required this.child,
  });

  static const int _scrimAlpha = 214;
  static const double _edgeInset = 12;

  final Animation<double> animation;
  final Rect? sourceRect;
  final double maxWidth;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = Curves.easeOutCubic.transform(animation.value);
        return LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.biggest;
            final target = Rect.fromCenter(
              center: available.center(Offset.zero),
              width: math.max(
                160,
                math.min(maxWidth, available.width - _edgeInset * 2),
              ),
              height: math.max(
                120,
                math.min(maxHeight, available.height - _edgeInset * 2),
              ),
            );
            final rect = sourceRect == null
                ? target
                : Rect.lerp(sourceRect, target, progress)!;

            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: AppColors.backgroundDeep.withAlpha(
                        (_scrimAlpha * progress).round(),
                      ),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: rect,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: target.width,
                      height: target.height,
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
