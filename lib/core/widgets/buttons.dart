import 'package:flutter/material.dart' hide Text;

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

ButtonStyle primaryButtonStyle({double height = 52, bool fullWidth = true}) {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.teal,
    foregroundColor: Colors.white,
    minimumSize: fullWidth ? Size.fromHeight(height) : Size(0, height),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    shape: const StadiumBorder(),
    textStyle: ts(15, weight: FontWeight.w700),
  );
}