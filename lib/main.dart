import 'package:flutter/material.dart';

import 'app.dart';
import 'utils/orientation_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OrientationHelper.applyPreferredOrientations();
  runApp(const PeriodicTableStudyApp());
}
