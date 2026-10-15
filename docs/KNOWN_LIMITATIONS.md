# Known Limitations

- Redmi Note 10T Pro 真机已完成基础交互验收，但 MIUI 后台冻结导致 Flutter DevTools 逐动画 UI/Raster timeline 尚未稳定导出；120 Hz 的 8.3 ms 帧预算不能据此认定已经达标。
- iOS 工程（`Runner.xcodeproj`、`Runner.xcworkspace`、Info.plist、横屏锁定）已按 Flutter 3.47.7 模板补齐，但本机是 Windows，无法执行 `xcodebuild`，所以 IPA 尚未真正编译，也未在 iPhone/iPad 真机验证；需要在 macOS 或 GitHub Actions 的 macOS runner 上出包，见 `docs/IOS_BUILD.md`。
- `Nour-elhaq/Interactive-Periodic-Table` 的 README 声明 MIT，但仓库缺少 LICENSE 文件；本项目未复制其代码或数据，后续若需要复用应先向作者确认。
- 未加入参考图中的 NIST 可见光谱图，因为本地没有经过核验的逐元素谱线数据，避免用装饰性颜色伪造科学数据。
- 放射性元素的性质可能随测量条件、同位素和预测模型变化；缺失值保持为 `null`。
- 正式科研或教学出版前，应使用 IUPAC、NIST、PubChem 当前条目复核数值。
