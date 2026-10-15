# 元素周期表查询与背诵

面向化学专业学生的 Flutter 横屏应用：完整展示 118 个元素，点击查看详情，并通过双指双击进入随机背诵模式。

查表模式支持按中文名称、元素符号或原子序数搜索定位；背诵模式提供不改变答题状态的“提示”按钮。

## 环境要求

- Flutter `>=3.44.0` stable，Dart SDK `^3.12.0`
- Android 推荐 JDK 17、Android SDK 36、Build Tools 36.0.0
- iOS 使用当前 Flutter stable 对应的 Xcode 与 CocoaPods

## 运行与构建

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

APK 输出：`build/app/outputs/flutter-apk/app-debug.apk`。

当前已验证的 Debug APK SHA-256：
`C21E0FCEFB97EF6EB81F059365CE2AF2A1B71D25C0581E196908442904182534`。

Profile APK 输出：`build/app/outputs/flutter-apk/app-profile.apk`。

iOS 的 `.ipa` 只能在 macOS 上产出（Xcode 限制），本机已补齐完整 iOS 工程与打包脚本：

```bash
bash tool/build_unsigned_ipa.sh release
# 输出：build/ios/ipa_unsigned/periodic_table_study-release.ipa
```

没有 Mac 时可用仓库内的 GitHub Actions 流程 `ios-unsigned-ipa` 出包，
细节见 `docs/IOS_BUILD.md`。

## 目录

```text
lib/
├── models/          元素数据模型
├── data/            数据仓库与周期表坐标
├── services/        双指双击识别
├── state/           背诵队列与判定状态
├── screens/         主界面
├── widgets/         元素方框、Container Transform 面板、反馈浮层
├── theme/           Material 3 暗色主题
└── utils/           横屏与系统 UI 配置
assets/data/elements.json
```

## 数据与缺失值

元素数据位于 `assets/data/elements.json`。数据模型将缺失、不适用或尚无公认值的属性保存为 `null`，界面统一显示“暂无数据”，不会填零或伪造精度。人工放射性元素质量采用代表性同位素质量数的方括号形式。

数据生成与基础校验脚本位于 `tool/generate_elements.mjs`。
统一数据字段与角标规范见 `docs/DATA_AND_NOTATION.md`。

## 动画实现

元素详情与镧系/锕系面板使用 Flutter 官方 `animations` 包中的 `OpenContainer` 实现 Container Transform；查表/背诵模式使用单一 500 ms 控制器完成渐出和渐入；正误反馈使用独立 Overlay 浮层，不阻塞元素放置。

依赖版本：`animations ^3.0.0`，要求 Flutter `>=3.44.0`，当前项目使用 Flutter 3.47.7。

## 调研与复用

参考仓库、访问状态、许可证判断和可复用范围见 `docs/RESEARCH_AND_LICENSES.md`。

本次实际执行和未执行的验证见 `docs/TEST_REPORT.md`。
真机验证记录见 `docs/DEVICE_TEST_REPORT.md`。
环境路径与变量见 `docs/ENVIRONMENT_SETUP.md`。
已知限制见 `docs/KNOWN_LIMITATIONS.md`。
动画设计和性能优化记录见 `docs/ANIMATION_AND_PERFORMANCE.md`。
