# Web 版构建与发布

## 一、本地构建与预览

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
dart run tool/serve_web.dart 8080
```

打开 `http://localhost:8080/`。脚本会同时打印局域网地址
（形如 `http://10.79.107.7:8080/`），同一 Wi-Fi 下的手机或平板可以直接访问，
这样在平板上验证时不需要签名，也不需要 Apple ID。

注意：不要直接双击 `build/web/index.html`，Flutter Web 的产物需要通过 HTTP 提供，
用 `file://` 打开会因为模块加载限制而白屏。

## 二、GitHub Pages 自动发布

`.github/workflows/web-pages.yml` 在推送到 `main` 且改动涉及 `lib/`、`web/`、
`assets/`、`test/` 或 `pubspec.yaml` 时触发：

1. `ubuntu-latest` 上跑 `flutter analyze` 与 `flutter test`；
2. `flutter build web --release --base-href "/<仓库名>/"`；
3. 通过 `actions/upload-pages-artifact` + `actions/deploy-pages` 发布。

访问地址：

```text
https://w1347057084-tech.github.io/-/
```

首次运行时 `actions/configure-pages` 会尝试自动启用 Pages（`enablement: true`）。
如果仓库策略不允许工作流自行开启，需要在仓库 `Settings → Pages` 里把
Source 选择为 `GitHub Actions`，然后重新运行一次工作流。

## 三、在 iPad 上当作 App 使用

1. Safari 打开上面的地址；
2. 点「分享」→「添加到主屏幕」；
3. 从主屏幕图标启动，会以独立窗口全屏运行（`manifest.json` 已设置
   `display: standalone`、`orientation: landscape`，启动背景色与 App 深色主题一致）。

Web 版本没有 7 天有效期限制，也不需要任何证书；更新方式就是重新推送代码。

## 四、平台差异说明

- 屏幕方向：浏览器无法像原生那样强制锁定方向，`OrientationHelper` 在 Web 上直接跳过；
  主屏幕方式启动时由 `manifest.json` 的 `orientation: landscape` 生效。
- 系统 UI：Web 没有全屏沉浸式系统栏，`SystemChrome` 调用在 Web 上被跳过。
- 交互：双指双击切回查表模式、拖拽放置元素等手势在触摸设备的浏览器中可用；
  桌面浏览器用鼠标操作时，双指手势不可用，可直接点击模式切换控件。
