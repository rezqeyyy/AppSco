import 'package:flutter/material.dart' hide Text;
import '../../../core/i18n/tr_text.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dashed_path.dart';

/// Hiasan kartu edukasi: ruas tulang belakang yang sedikit melengkung.
class SpineMotifPainter extends CustomPainter {
  const SpineMotifPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dashed = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final Path axis = Path();
    axis.moveTo(36, 6);
    axis.cubicTo(28, 34, 46, 58, 38, 84);
    axis.cubicTo(32, 104, 40, 124, 36, 146);
    drawDashedPath(canvas, axis, dashed, 2, 9);

    final Paint bone = Paint()
      ..color = AppColors.teal
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    const List<List<double>> bones = <List<double>>[
      <double>[24, 44, 18],
      <double>[27, 49, 38],
      <double>[30, 52, 58],
      <double>[28, 48, 78],
      <double>[24, 44, 98],
      <double>[26, 46, 118],
      <double>[26, 46, 138],
    ];
    for (final List<double> b in bones) {
      canvas.drawLine(Offset(b[0], b[2]), Offset(b[1], b[2]), bone);
    }
  }

  @override
  bool shouldRepaint(covariant SpineMotifPainter oldDelegate) => false;
}