import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dashed_path.dart';

/// Garis bantu: siluet punggung putus-putus, garis tengah tegak, dan sudut bingkai.
class SilhouetteGuidePainter extends CustomPainter {
  const SilhouetteGuidePainter();

  static Path buildSilhouette() {
    final Path p = Path();
    p.addOval(Rect.fromCircle(center: const Offset(171, 62), radius: 34));
    p.moveTo(157, 96);
    p.lineTo(157, 112);
    p.cubicTo(140, 120, 105, 122, 88, 134);
    p.cubicTo(72, 146, 66, 170, 64, 200);
    p.lineTo(58, 420);
    p.moveTo(92, 420);
    p.lineTo(98, 230);
    p.cubicTo(100, 215, 106, 205, 110, 200);
    p.lineTo(118, 290);
    p.cubicTo(116, 320, 108, 345, 106, 420);
    p.moveTo(236, 420);
    p.cubicTo(234, 345, 226, 320, 224, 290);
    p.lineTo(232, 200);
    p.cubicTo(236, 205, 242, 215, 244, 230);
    p.lineTo(250, 420);
    p.moveTo(284, 420);
    p.lineTo(278, 200);
    p.cubicTo(276, 170, 270, 146, 254, 134);
    p.cubicTo(237, 122, 202, 120, 185, 112);
    p.lineTo(185, 96);
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Gambar dibuat untuk bidang 342 x 440, lalu diskalakan ke ukuran layar.
    final double sx = size.width / 342;
    final double sy = size.height / 440;
    final double scale = sx < sy ? sx : sy;
    canvas.translate((size.width - 342 * scale) / 2, (size.height - 440 * scale) / 2);
    canvas.scale(scale);

    final Paint centerLine = Paint()
      ..color = const Color(0x73FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Path center = Path();
    center.moveTo(171, 24);
    center.lineTo(171, 424);
    drawDashedPath(canvas, center, centerLine, 6, 8);

    canvas.translate(0, 44);
    final Paint outline = Paint()
      ..color = AppColors.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    drawDashedPath(canvas, buildSilhouette(), outline, 10, 8);
    canvas.restore();

    // Sudut bingkai mengikuti ukuran layar yang sebenarnya.
    final Paint corner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const double m = 16;
    const double len = 24;
    final double w = size.width;
    final double h = size.height;
    canvas.drawLine(const Offset(m, m), const Offset(m + len, m), corner);
    canvas.drawLine(const Offset(m, m), const Offset(m, m + len), corner);
    canvas.drawLine(Offset(w - m, m), Offset(w - m - len, m), corner);
    canvas.drawLine(Offset(w - m, m), Offset(w - m, m + len), corner);
    canvas.drawLine(Offset(m, h - m), Offset(m + len, h - m), corner);
    canvas.drawLine(Offset(m, h - m), Offset(m, h - m - len), corner);
    canvas.drawLine(Offset(w - m, h - m), Offset(w - m - len, h - m), corner);
    canvas.drawLine(Offset(w - m, h - m), Offset(w - m, h - m - len), corner);
  }

  @override
  bool shouldRepaint(covariant SilhouetteGuidePainter oldDelegate) => false;
}