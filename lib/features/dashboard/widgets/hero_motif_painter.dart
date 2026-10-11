import 'package:flutter/material.dart';

import '../../../core/utils/dashed_path.dart';

/// Hiasan di kartu "Screening baru": sumbu tubuh putus-putus dan tiga garis kiri-kanan.
class HeroMotifPainter extends CustomPainter {
  const HeroMotifPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const Color mint = Color(0xFF7FD6CE);
    final Paint dashed = Paint()
      ..color = mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final Path axis = Path();
    axis.moveTo(48, 8);
    axis.cubicTo(44, 50, 54, 92, 48, 132);
    axis.cubicTo(44, 160, 50, 180, 48, 196);
    drawDashedPath(canvas, axis, dashed, 2, 10);

    final Paint stroke = Paint()
      ..color = mint
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final Paint dot = Paint()..color = Colors.white;
    const List<List<Offset>> pairs = <List<Offset>>[
      <Offset>[Offset(14, 44), Offset(82, 50)],
      <Offset>[Offset(22, 96), Offset(78, 94)],
      <Offset>[Offset(18, 150), Offset(80, 153)],
    ];
    for (final List<Offset> pair in pairs) {
      canvas.drawLine(pair[0], pair[1], stroke);
      canvas.drawCircle(pair[0], 5, dot);
      canvas.drawCircle(pair[1], 5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant HeroMotifPainter oldDelegate) => false;
}