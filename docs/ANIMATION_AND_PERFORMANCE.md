# 动画与性能实现说明

## Container Transform

- 使用 Flutter 官方 `animations` 3.0.0 的 `OpenContainer`。
- 已核对官方包元数据：`animations 3.0.0` 要求 Flutter `>=3.44.0`、Dart `^3.12.0`，当前 Flutter 3.47.7 / Dart 3.13.5 满足要求。
- 已检查官方 `open_container.dart` 源码中的 `closedBuilder`、`openBuilder`、反向路由和 `routeSettings` 行为，关闭按钮与系统返回都会复用同一 route。
- 元素格子、镧系/锕系入口和系列内元素均使用稳定的原子序数路由标识。
- 关闭按钮和系统返回都由 `OpenContainer` 的路由反向动画处理。
- 详情与系列面板使用独立 `Material` 边界，避免 transition 过程中出现透明层叠和闪烁。

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
- `flutter test`：34 tests 全部通过。
- 500 ms 模式动画由 Widget 测试检查双阶段状态提交。
- `flutter build apk --profile`：通过，用于后续 DevTools 真机测量。
- 1366×768 测试渲染快照：周期表、详情面板、镧系面板均无重叠或溢出。

## 尚未测量

当前没有 Android 真机或模拟器，因此尚未得到真实设备上的 UI/Raster 帧耗时和 jank 数据。目标设备上应在 Profile 模式使用 DevTools Performance 录制以下路径：

1. 元素格子打开和关闭详情。
2. 镧系/锕系入口展开、关闭和内部详情切换。
3. 查表/背诵模式连续往返切换。
4. 快速连续触发正确和错误反馈。
