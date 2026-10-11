import 'package:flutter/material.dart';

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
  final bool bordered;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: background,
        shape: CircleBorder(
          side: bordered ? const BorderSide(color: AppColors.line) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 24, color: foreground),
          ),
        ),
      ),
    );
  }
}