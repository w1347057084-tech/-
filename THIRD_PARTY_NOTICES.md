# Third-Party Notices

本项目的 Flutter 应用源码和本地元素 JSON 数据由本项目维护。

打包进应用的第三方资源：

- 字体 `assets/fonts/RareCJK-Subset.ttf`（约 18 KB）：104–118 号元素简体中文名
  所需的 15 个汉字（如 𬬻 U+2CB3B、鿫 U+9FEB）。两套字形均为 SIL Open Font
  License 1.1 授权，仅在系统字体缺少这些字形时兜底显示：
  - Noto Sans SC，https://fonts.google.com/noto/specimen/Noto+Sans+SC
    （BMP 区字形：鿏、鿔、鿭、镆、鿬、鿫）
  - 遍黑体 Plangothic，https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project
    （CJK 扩展 B/C/D/E 区字形：𬬻、𬭊、𬭳、𬭛、𬭶、𫟼、𬬭、𫓧、𫟷）
    子集由 `tool/subset_rare_cjk_font.mjs` 生成，按 OFL 保留名称条款不使用「遍黑」名称。

开发依赖：

- Flutter SDK，BSD 3-Clause License，https://github.com/flutter/flutter
- `animations`，BSD 3-Clause License，https://pub.dev/packages/animations
- `flutter_lints`，BSD 3-Clause License，https://pub.dev/packages/flutter_lints

构建时依赖由其各自包管理器解析。正式发布前应保留 Flutter 与依赖包的许可证文本。
