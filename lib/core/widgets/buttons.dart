import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Tombol utama: pil teal penuh.
ButtonStyle primaryButtonStyle({double height = 56, bool fullWidth = true}) {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.teal,
    foregroundColor: Colors.white,
    disabledBackgroundColor: AppColors.tealPale,
    disabledForegroundColor: AppColors.teal,
    minimumSize: fullWidth ? Size.fromHeight(height) : Size(0, height),
    padding: const EdgeInsets.symmetric(horizontal: 22),
    elevation: 0,
    shape: const StadiumBorder(),
    textStyle: ts(15, weight: FontWeight.w700),
  );
}

/// Tombol putih dengan teks teal, dipakai di atas kartu teal (hero).
ButtonStyle accentButtonStyle({double height = 52, bool fullWidth = false}) {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.lime,
    foregroundColor: AppColors.tealDeep,
    minimumSize: fullWidth ? Size.fromHeight(height) : Size(0, height),
    padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
    elevation: 0,
    shape: const StadiumBorder(),
    textStyle: ts(15, weight: FontWeight.w800),
  );
}