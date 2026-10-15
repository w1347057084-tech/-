# Test Report

执行日期：2026-10-15。

## 工具链

- Flutter 3.47.7 stable
- Dart 3.13.5
- Android SDK 36 / Build Tools 36.0.0
- OpenJDK 17.0.20.1
- Gradle 9.3.1 / Android Gradle Plugin 9.1.0 / Kotlin 2.4.0
- `animations` 3.0.0

## 已执行

| 检查 | 命令/方式 | 结果 |
| --- | --- | --- |
| 依赖解析 | `flutter pub get` | 通过 |
| 静态分析 | `flutter analyze` | 通过，0 issues |
| 自动化测试 | `flutter test` | 通过，34 tests |
| 布局快照 | `flutter test tool/visual_snapshot_test.dart` | 通过，生成 3 张 1366×768 PNG |
| Debug 构建 | `flutter build apk --debug` | 通过 |
| Profile 构建 | `flutter build apk --profile` | 通过，Font 图标已 tree-shake |
| APK 签名 | `apksigner verify` | 通过，APK Signature Scheme v2 |
| APK 元数据 | `aapt dump badging` | `compileSdk 36`、`targetSdk 36`、`minSdk 24` |
| Android 工具链 | `flutter doctor -v` | Android toolchain 通过，licenses 已接受 |

## APK

```text
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-profile.apk
```

- Debug 大小：174,720,292 bytes
- Debug SHA-256：`C21E0FCEFB97EF6EB81F059365CE2AF2A1B71D25C0581E196908442904182534`
- Profile 大小：79,443,690 bytes
- Profile SHA-256：`38CBC58A71CA9F0EAB78B703C23DF18F2EC4743DF0EE5BA63C5810FB2E4C9EA0`

## 自动化覆盖

- 118 个元素的数据连续性、坐标唯一性和电子层总数。
- 周期/族标注、元素格子四项核心信息和英文名移除。
- Container Transform 详情打开与关闭。
- 镧系入口展开全部 15 个元素并继续打开单元素详情。
- 500 ms 模式渐出/渐入的双阶段状态同步。
- 背诵模式下双指双击返回查表模式。
- 正误反馈浮层出现、自动退出且不阻塞主界面。
- 中文名称、符号、原子序数搜索，前后空格处理、无匹配提示和周期表定位。
- 镧系搜索结果定位至独立系列行。
- 背诵提示只高亮真实目标格子，不改变进度；答错清提示，答对后切换下一题。
- 结构化电子排布与规范字符串一致，电子总数等于原子序数，轨道容量和重复轨道会被拒绝。
- 标准原子量与代表性同位素质量数分开保存和校验。
- `H₂O`、`SO₄²⁻`、离子电荷和同位素左上/左下角标的后处理结构测试。
- 镧系/锕系隐藏范围、随机队列、位置判定、重开和退出恢复。

## 真机验收

Redmi Note 10T Pro / Android 17 / 120 Hz 真机已完成启动横屏、完整周期表、搜索定位、详情上标、提示和背诵模式基础验收，详情见 `docs/DEVICE_TEST_REPORT.md`。

由于 MIUI 后台冻结，Flutter DevTools 的逐动画 UI/Raster timeline 尚未稳定导出，因此不能声称 120 Hz 的 8.3 ms 帧预算已经达标。

## iOS 交付（本轮新增）

- 使用 Flutter 3.47.7 官方模板补齐 iOS 工程：`Runner.xcodeproj`、`Runner.xcworkspace`、`RunnerTests`、`Assets.xcassets`、启动页与 Main storyboard，共写入 44 个模板文件。
- Bundle ID 与 Android 对齐为 `com.example.periodic_table_study`，pbxproj 中 6 处标识符已逐条核对（含 RunnerTests 目标）。
- `Info.plist` 通过 XML 解析校验：包含 Scene 生命周期与 `SceneDelegate`、`CADisableMinimumFrameDurationOnPhone`、`UIApplicationSupportsIndirectInputEvents`；方向仅保留 `LandscapeLeft` / `LandscapeRight`，iPad 额外设置 `UIRequiresFullScreen`。
- `AppDelegate.swift` 更新为与当前模板一致的 `FlutterImplicitEngineDelegate` 写法，插件注册改到隐式引擎回调。
- 新增 `tool/build_unsigned_ipa.sh`：在 macOS 上执行 `flutter build ios --<mode> --no-codesign`，再把 `Runner.app` 打成 `Payload/Runner.app` 结构的未签名 IPA。脚本已通过 `sh -n` 语法校验，并实测非 macOS 环境下会给出明确提示并以 exit 1 退出。
- 新增 `.github/workflows/ios-unsigned-ipa.yml` 与 `.gitattributes`，可在没有 Mac 的情况下用 GitHub Actions 的 macOS runner 出包，并保证 shell 脚本以 LF 行尾提交。
- **未执行**：`xcodebuild` 编译、IPA 实际产出、iPhone/iPad 真机运行。本机为 Windows，Flutter 在非 macOS 主机上不注册 `ios` / `ipa` 子命令，实测 `flutter build ios --no-codesign` 输出 `Could not find an option named "--no-codesign".`。
- iOS 改动不涉及 Dart 代码：`flutter analyze` 仍为 0 issues，`flutter test` 仍为 34 passed。
