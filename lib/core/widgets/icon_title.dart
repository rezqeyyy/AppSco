import 'package:flutter/material.dart' hide Text;

import '../theme/app_colors.dart';

class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.background = AppColors.tealTint,
    this.foreground = AppColors.teal,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 22, color: foreground),
    );
  }
}