# 开发环境配置

本机已配置以下用户级环境变量：

```text
JAVA_HOME=D:\android-build\jdk\jdk-17.0.20.1+1
ANDROID_HOME=D:\android-build\sdk
ANDROID_SDK_ROOT=D:\android-build\sdk
PUB_CACHE=D:\pub-cache
FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
PUB_HOSTED_URL=https://pub.flutter-io.cn
Path 前置：D:\flutter\bin
```

工具链：

- Flutter 3.47.7 stable：`D:\flutter`
- Dart 3.13.5：随 Flutter 提供
- Android SDK：`D:\android-build\sdk`
- Android Platform：API 36
- Android Build Tools：36.0.0
- JDK：17.0.20.1 LTS

新终端中可直接执行：

```bash
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

如果已有终端未刷新环境变量，请重新打开终端，或在当前终端手动设置上述变量。
