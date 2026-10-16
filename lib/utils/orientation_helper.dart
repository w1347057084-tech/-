import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class OrientationHelper {
  const OrientationHelper._();

  static Future<void> applyPreferredOrientations() async {
    // Web 上既不能锁定屏幕方向，也没有系统 UI 需要隐藏，
    // 浏览器会按窗口尺寸直接布局。
    if (kIsWeb) {
      return;
    }

    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }
}
