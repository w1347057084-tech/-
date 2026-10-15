# iOS 交付与 IPA 构建说明

## 一、为什么 Windows 上无法直接产出 IPA

IPA 里装的是为 iOS 编译的 Mach-O 可执行文件，只能用 Apple 的 iOS SDK
（`xcodebuild` / `clang`，仅随 macOS 版 Xcode 提供）编译链接。Flutter 也把这条限制
写死在工具链里（`BuildIOSCommand.supported => globals.platform.isMacOS`），
在 Windows 上 `ios` / `ipa` 子命令甚至不会被注册：

```text
$ flutter build ios --no-codesign
Could not find an option named "--no-codesign".
```

即使绕过子命令注册，工具链内部也只会抛出：

```text
Building for iOS is only supported on macOS.
```

因此本机（Windows）能交付的是：**完整可构建的 iOS 工程 + 一键打包脚本**，
真正产出 `.ipa` 的那一步必须在 macOS 上执行。Android 侧不受影响，
`app-debug.apk` / `app-profile.apk` 仍可正常构建和安装。

## 二、iOS 工程已完成的配置

- 用 Flutter 3.47.7 的官方模板补齐了 `ios/` 目录：`Runner.xcodeproj`、
  `Runner.xcworkspace`、`RunnerTests`、`Assets.xcassets`、启动页与主 storyboard。
- Bundle ID 与 Android 保持一致：`com.example.periodic_table_study`
  （测试目标为 `com.example.periodic_table_study.RunnerTests`）。
- `Info.plist` 采用当前模板的 Scene 生命周期（`SceneDelegate` + `UIApplicationSceneManifest`），
  `AppDelegate` 同步为 `FlutterImplicitEngineDelegate` 写法。
- 方向锁定为横屏：`UISupportedInterfaceOrientations` 只保留
  `LandscapeLeft` / `LandscapeRight`，iPad 同时设置 `UIRequiresFullScreen`。
- 保留 `CADisableMinimumFrameDurationOnPhone`，让 ProMotion 设备可以跑满 120 Hz，
  与本项目的动画性能目标一致。
- 显示名称为「元素周期表查询与背诵」，`CFBundleShortVersionString` / `CFBundleVersion`
  取自 `pubspec.yaml`（当前 `1.0.0+1`）。

## 三、在 macOS 上产出一个未签名 IPA

```bash
git clone <本工程> && cd "Periodic table of elements"
bash tool/build_unsigned_ipa.sh release      # 也可用 profile / debug
```

脚本会执行 `flutter build ios --release --no-codesign`，再把
`build/ios/iphoneos/Runner.app` 打成标准 `Payload/Runner.app` 结构：

```text
build/ios/ipa_unsigned/periodic_table_study-release.ipa
```

注意：`flutter build ipa --no-codesign` 只会产出 `.xcarchive`，会跳过 IPA 导出，
所以这里用 `flutter build ios` + 手工打包的方式拿到未签名 IPA。

## 四、没有 Mac 时：用 GitHub Actions 出包

仓库已包含 `.github/workflows/ios-unsigned-ipa.yml`：

1. 把工程推送到 GitHub 仓库；
2. 在 Actions 页面手动触发 `ios-unsigned-ipa`（或推送 `v*` tag）；
3. 运行结束后下载 Artifact `periodic-table-study-unsigned-ipa`，即为未签名 IPA。

该流程使用 `macos-latest` runner 和 Flutter 3.47.7，不需要本地 Mac，
也不需要任何 Apple 开发者证书。

## 五、未签名 IPA 怎么装到真机

未签名 IPA 不能直接双击安装，需要重新签名（用免费 Apple ID 即可）：

- Xcode：打开 `ios/Runner.xcworkspace`，在 Runner target 里选择自己的 Team，
  连接 iPhone 后直接 Run；
- Sideloadly / AltStore：把脚本产出的 IPA 拖进工具，登录 Apple ID 签名安装
  （免费账号签名的 App 有效期 7 天）。

## 六、iOS 侧仍需在 macOS / 真机确认的事项

- `flutter build ios` 全流程编译是否通过（本机无法执行，已做的是工程结构与配置校验）。
- 横屏方向、刘海/灵动岛安全区、系统返回手势与遮罩动画。
- iOS 上 Container Transform、模式切换、提示高亮的实际帧耗时
  （按 `docs/ANIMATION_AND_PERFORMANCE.md` 用 Profile 模式 DevTools 复核）。
- App 图标目前仍是 Flutter 模板图标：Android 侧也只用了默认图标，
  需要品牌图标时可再补齐两端的图标资源。
