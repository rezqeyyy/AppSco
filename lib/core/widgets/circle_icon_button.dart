import 'package:flutter/material.dart';

import '../i18n/app_language.dart';
import '../theme/app_colors.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.background = Colors.white,
    this.foreground = AppColors.ink,
    this.bordered = true,
    this.size = 48,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final bool bordered; // true: bayangan lembut (tombol di atas latar terang)
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tr(label),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: bordered && background == Colors.white ? AppColors.softShadow : null,
        ),
        child: Material(
          color: background,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: 22, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}