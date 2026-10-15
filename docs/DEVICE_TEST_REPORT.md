# 真机测试报告

执行日期：2026-10-15。

## 测试设备

- 型号：Xiaomi M2104K10AC（Redmi Note 10T Pro）
- 代号：`chopin`
- Android：17 / API 37
- 屏幕：1080 × 2400，455 dpi
- 刷新率：支持 120 Hz，当前渲染模式也报告 120 Hz
- 测试构建：Profile APK

## 已通过

| 检查 | 结果 |
| --- | --- |
| 应用安装 | 通过 |
| 冷启动 | 通过，`am start -W` 报告约 0.82 秒 |
| 自动横屏 | 通过，显示尺寸切换为 2400 × 1080 |
| 完整周期表 | 通过，118 个元素均渲染 |
| 传统族编号 | 通过，设备上显示 IA、IIA、IIIB-VIII、IB、IIB、IIIA-VIIIA |
| VIII 跨列 | 通过，覆盖第 8-10 列 |
| 搜索 | 输入 `O` 后显示 O、Os、Og 等候选 |
| 搜索定位 | 点击 O 后设备上的氧元素格子出现高亮描边 |
| 元素详情 | 通过，点击 H 后显示完整详情卡片 |
| 化学上标 | 通过，设备实际显示 `1s¹`，不是 `1s1` |
| 详情关闭 | 通过，系统返回可关闭详情 |
| 背诵模式 | 通过，显示当前元素、`进度 0 / 86` 和“提示”按钮 |
| 提示功能 | 对当前元素 Re，目标高亮落在第 6 周期第 7 列的隐藏格子上，没有自动完成答题 |
| Dart 致命异常 | 未发现 |
| Android ANR | 未发现 |

设备截图位于：

```text
build/visuals/device-start.png
build/visuals/device-search2.png
build/visuals/device-search-highlight.png
build/visuals/device-detail.png
build/visuals/device-mode.png
build/visuals/device-hint.png
```

## 性能记录

设备在模式切换与提示操作后的累计 `dumpsys gfxinfo` 快照：

```text
Total frames rendered: 59
Janky frames: 1 (1.69%)
50th percentile: 17ms
90th percentile: 23ms
95th percentile: 25ms
```

同时采集了约 8.5 MB 的 `atrace` 真机 trace，确认 SurfaceFlinger 使用 120 Hz `NextFrameInterval`。

需要注意：这台 MIUI/Android 17 设备对 Flutter SurfaceView 没有稳定提供每次动画独立的 gfxinfo 增量；`flutter drive` 的 integration timeline 也会被 MIUI 后台冻结机制中断。因此上面的累计统计只能作为设备记录，不能替代 Flutter DevTools 在 Profile 模式下的逐动画 UI/Raster 帧预算结论，尤其不能据此认定 120 Hz 的 8.3 ms 帧预算已经达标。

## 待继续

- 在解除 MIUI 后台冻结限制后，用 Flutter DevTools Performance 录制并导出详情、搜索、模式切换和提示的单次动画时间线。
- 执行多分辨率适配：800×360、960×540、1280×720、1920×1080。
- 测试系统返回、横竖屏切换、刘海/挖孔区域以及 60 Hz / 120 Hz 不同刷新率。
