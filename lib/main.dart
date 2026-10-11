import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'state/app_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Semua layar dirancang untuk posisi tegak.
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[DeviceOrientation.portraitUp]);
  appData.load();
  runApp(const ScoliosisApp());
}