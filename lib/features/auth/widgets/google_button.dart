import 'package:flutter/material.dart' hide Text;
import '../../../core/i18n/tr_text.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Tombol putih "Masuk dengan Google".
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, required this.label});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.line),
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        textStyle: ts(15, weight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'G',
            style: ts(20, weight: FontWeight.w800, color: const Color(0xFF4285F4), height: 22),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}