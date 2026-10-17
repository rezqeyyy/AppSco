import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/i18n/app_language.dart';
import 'state/app_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Semua layar dirancang untuk posisi tegak.
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[DeviceOrientation.portraitUp]);
  appData.load();
  appLanguage.load(); // bahasa pilihan pengguna dan terjemahan yang tersimpan
  runApp(const ScoliosisApp());
}