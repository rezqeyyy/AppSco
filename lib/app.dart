import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/i18n/tr_text.dart' show LanguageScope;
import 'core/theme/app_colors.dart';
import 'features/splash/splash_screen.dart';

import 'features/chat/floating_ansco.dart';

class ScoliosisApp extends StatelessWidget {
  const ScoliosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.teal,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.ground,
    );
    final TextTheme text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
    final OutlineInputBorder field = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.line),
    );

    // LanguageScope membangun ulang semua layar saat bahasa diganti
    // atau terjemahan baru selesai, jadi teksnya ikut berubah.
    return LanguageScope(
      child: MaterialApp(
        title: 'AppSco',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        // Kepala AnSco mengambang di atas semua halaman.
        builder: (BuildContext context, Widget? child) => Stack(
          children: <Widget>[
            if (child != null) child,
            const FloatingAnSco(),
          ],
        ),
        theme: base.copyWith(
          textTheme: text,
          splashFactory: InkSparkle.splashFactory,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.ground,
            foregroundColor: AppColors.ink,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: field,
            enabledBorder: field,
            focusedBorder: field.copyWith(borderSide: const BorderSide(color: AppColors.teal, width: 1.6)),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(shape: const StadiumBorder(), elevation: 0),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.tealDeep,
            contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            showDragHandle: false,
          ),
          chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder()),
          dividerTheme: const DividerThemeData(color: AppColors.lineSoft, thickness: 1),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}