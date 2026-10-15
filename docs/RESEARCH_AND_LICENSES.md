# 开源项目调研、数据来源与许可证

## 调研状态

调研日期：2026-10-15。GitHub 当前可访问，以下仓库均已通过 `git ls-remote` 和浅克隆实际检查当前 `main` 分支、顶层文件、README、许可证和最近提交。

| 项目 | 当前技术栈 | 最近提交 | 许可证 | 可复用结论 |
| --- | --- | --- | --- | --- |
| `vutils/interactive-periodic-table` | 原生 HTML/CSS/JavaScript PWA，元素数据与布局主要内嵌在 `app.js` | `dba73ad5`，2026-03-13 | Unlicense，明确公共领域 | 可合法参考或迁移数据/布局思路；本项目未复制其代码和图片 |
| `Nour-elhaq/Interactive-Periodic-Table` | 原生 HTML/CSS/JavaScript，`elements.js` 单独维护 118 元素数据 | `89962321`，2026-03-15 | README 声明 MIT，但仓库没有 LICENSE 文件 | 许可证状态需补充确认；本次未复制代码或数据 |
| `VVinCentZhang/EzPTable` | 单文件 HTML/CSS/JavaScript，Three.js CDN 用于 3D 轨道云 | `6a13eda3`，2026-10-06 | MIT | 可合法参考或复用；本次未复制代码或数据 |

三个项目都是 Web 技术栈，不适合嵌入 Flutter 核心周期表。本次调研确认了它们的数据组织、分类着色、详情面板和搜索/筛选思路，但实际 Flutter 数据、布局、状态管理和 UI 均由本项目独立实现。

## 元素数据

`assets/data/elements.json` 由 `tool/generate_elements.mjs` 生成，覆盖原子序数 1 至 118。基础数据采用通用化学参考体系中的标准元素名称、符号、原子量、周期表坐标、基态电子排布与常见物性；放射性人工元素采用代表性同位素质量数或保留缺失值。

数据使用原则：

- 不将网络 API 作为运行依赖。
- 不补造缺失值；`null` 表示暂无可靠、统一或适用数据。
- 电子排布包含 Cr、Cu、Pt、Au、La、Ce、Gd、Ac、Th、Pa、U、Np、Cm、Lr 等已知或具备能级竞争的情况。
- 应用启动时校验 118 条记录、原子序数连续性、符号唯一性、周期范围和显示坐标冲突。
- 电子层分布由基态电子排布字符串自动汇总，减少主表、详情和背诵功能之间的数据分叉。

正式科研、考试或出版使用前，建议用 IUPAC、NIST 和 PubChem 当前条目逐项复核。

## 第三方依赖

运行时仅使用 Flutter SDK 与 Material 3；开发测试使用 `flutter_test` 与 `flutter_lints`。未引入额外 Dart 包。
