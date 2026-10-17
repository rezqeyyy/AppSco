import 'package:flutter/material.dart' hide Text;
import 'package:google_fonts/google_fonts.dart';

import 'core/i18n/tr_text.dart' show LanguageScope;
import 'core/theme/app_colors.dart';
import 'features/splash/splash_screen.dart';

class ScoliosisApp extends StatelessWidget {
  const ScoliosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.teal, primary: AppColors.teal),
      scaffoldBackgroundColor: AppColors.ground,
    );
    // LanguageScope membangun ulang semua layar saat bahasa diganti
    // atau terjemahan baru selesai, jadi teksnya ikut berubah.
    return LanguageScope(
      child: MaterialApp(
        title: 'SkolioCek',
        debugShowCheckedModeBanner: false,
        theme: base.copyWith(
          textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
              .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}