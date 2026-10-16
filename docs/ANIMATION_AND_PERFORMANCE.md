# 动画与性能实现说明

## 卡片展开（Container Transform，模态形态）

- 元素详情、镧系/锕系面板、系列内元素详情都是**模态卡片**：周期表保留在下方并被压暗，
  卡片在上层展开；点遮罩、点关闭按钮、系统返回都会反向收回原始格子。
- 实现没有沿用 `animations` 包的 `OpenContainer`：它推入的路由是 `opaque => true`
  （见官方 `open_container.dart` 的 `_OpenContainerRoute`），动画结束后 Flutter 不再绘制
  下层周期表，只能得到"整屏替换"，无法满足模态形态。改用 `showGeneralDialog`
  （`PopupRoute`，`opaque => false`）配合自定义容器变换：
  - 点击时用 `MetaData` + `GlobalKey` 量取源格子的屏幕矩形（不额外引入绘制层）；
  - `_ModalCardTransition` 用 `Rect.lerp` + `FittedBox` 把卡片从源格子形变到居中目标矩形，
    反向播放即回到原格子的位置与尺寸；
  - 遮罩浓度与动画进度同步（`easeOutCubic`，终值 alpha 214/255），随开合渐入渐出；
  - 路由设置 `barrierDismissible: true`，barrierColor 近乎透明，由框架负责"点空白关闭"。
- 面板组件（`ElementDetailPanel`、`SeriesPanel`）只渲染卡片本身，尺寸与遮罩由
  `TransformContainer` 的浮层统一决定，避免整屏 `Material` 把周期表盖住。
- 元素格子、镧系/锕系入口和系列内元素都使用稳定的原子序数路由标识。
- `animations ^3.0.0` 仍在依赖中（模式切换等其他动画使用），当前 Flutter 3.47.7 / Dart 3.13.5 满足其要求。

## 模式切换

- 使用一个 `AnimationController`，总时长为 500 ms。
- 0-250 ms 将旧模式内容渐出，250-500 ms 将新模式内容渐入。
- 在动画中点提交 `MemorizationState.start()` 或 `exit()`，确保显示状态和业务状态同步切换。
- 动画期间使用 `IgnorePointer` 阻止重复操作；双指双击在查表模式进入背诵，在背诵模式返回查表。

## 反馈提示

- 正误提示使用独立 `OverlayEntry` 和单一 `AnimationController`。
- 显示、停留、退出包含在一个 1120 ms 动画周期内。
- 新提示出现前会移除旧提示，避免快速答题时多条提示叠加。
- 浮层使用 `IgnorePointer`，不会阻塞后续元素放置。

## Widget 重建与绘制

- 模式动画通过 `AnimatedBuilder` 的缓存 `child` 复用整个周期表子树，只在切换中点重建一次。
- 118 个元素格子位于 `RepaintBoundary` 中，减少局部动画对整表重绘的影响。
- Container Transform 只涉及当前打开的元素或系列入口。
- 动画路径未使用模糊、BackdropFilter 或大面积裁剪。

## 当前验证

- `flutter analyze`：0 issues。
- `flutter test`：35 tests 全部通过，其中新增用例断言浮层路由为非不透明（周期表继续绘制）、
  遮罩实际绘制（alpha > 0.5）且点空白处可以关闭。
- 500 ms 模式动画由 Widget 测试检查双阶段状态提交。
- `flutter build apk --profile`：通过，用于后续 DevTools 真机测量。
- 1366×768 测试渲染快照：周期表、详情面板、镧系面板均无重叠或溢出。

## 尚未测量

当前没有 Android 真机或模拟器，因此尚未得到真实设备上的 UI/Raster 帧耗时和 jank 数据。目标设备上应在 Profile 模式使用 DevTools Performance 录制以下路径：

1. 元素格子打开和关闭详情。
2. 镧系/锕系入口展开、关闭和内部详情切换。
3. 查表/背诵模式连续往返切换。
4. 快速连续触发正确和错误反馈。
