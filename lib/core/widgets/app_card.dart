import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Kartu putih bersudut bulat dengan bayangan lembut.
/// [bordered] true: garis tepi tipis tanpa bayangan (untuk kartu di dalam kartu).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
    this.radius = 24,
    this.bordered = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final BorderRadius r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: bordered || color != Colors.white ? null : AppColors.softShadow,
      ),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: r,
          side: bordered ? const BorderSide(color: AppColors.line) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}