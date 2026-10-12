import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return MaterialApp(
      title: 'SkolioCek',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
            .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      ),
      home: const SplashScreen(),
    );
  }
}