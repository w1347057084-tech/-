import 'package:flutter/services.dart';

class OrientationHelper {
  const OrientationHelper._();

  static Future<void> applyPreferredOrientations() async {
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
