import 'dart:math' as math;
import '../../../core/i18n/tr_text.dart';

import 'package:flutter/material.dart' hide Text;

/// Menggelapkan seluruh layar kecuali [hole], menggambar cincin berdenyut di
/// sekeliling bagian yang disorot, dan panah dari kartu penjelasan ke bagian itu.
class SpotlightPainter extends CustomPainter {
  SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.pulse,
    required this.cardAbove,
    required this.gap,
  });

  final Rect? hole;
  final double radius;
  final double pulse; // 0-1, berulang
  final bool cardAbove; // kartu di atas bagian yang disorot
  final double gap; // ruang antara kartu dan sorotan, tempat panah

  @override
  void paint(Canvas canvas, Size size) {
    final Rect? spot = hole;
    final Path dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (spot != null) {
      dim.addRRect(RRect.fromRectAndRadius(spot, Radius.circular(radius)));
    }
    canvas.drawPath(dim, Paint()..color = const Color(0xB8000000));
    if (spot == null) return;

    // Cincin yang membesar lalu memudar
    final double grow = 2 + 8 * pulse;
    canvas.drawRRect(
      RRect.fromRectAndRadius(spot.inflate(grow), Radius.circular(radius + grow)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color.fromRGBO(255, 255, 255, 0.85 * (1 - pulse)),
    );

    // Panah melengkung dari kartu ke sorotan, ujungnya bergerak maju-mundur sedikit
    final double w = size.width;
    final double endX = spot.center.dx.clamp(24.0, w - 24).toDouble();
    final double startX =
        (endX + (endX < w / 2 ? 44 : -44)).clamp(32.0, w - 32).toDouble();
    final double nudge = 3 * math.sin(pulse * 2 * math.pi);
    final double startY = cardAbove ? spot.top - gap + 8 : spot.bottom + gap - 8;
    final double endY = cardAbove ? spot.top - 10 + nudge : spot.bottom + 10 - nudge;
    final Offset start = Offset(startX, startY);
    final Offset end = Offset(endX, endY);
    final Offset control = Offset(startX, (startY + endY) / 2);

    final Paint arrow = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path line = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    canvas.drawPath(line, arrow);

    final double angle = math.atan2(end.dy - control.dy, end.dx - control.dx);
    final Path head = Path()
      ..moveTo(end.dx, end.dy)
      ..relativeLineTo(
        Offset.fromDirection(angle + math.pi - 0.5, 12).dx,
        Offset.fromDirection(angle + math.pi - 0.5, 12).dy,
      )
      ..moveTo(end.dx, end.dy)
      ..relativeLineTo(
        Offset.fromDirection(angle + math.pi + 0.5, 12).dx,
        Offset.fromDirection(angle + math.pi + 0.5, 12).dy,
      );
    canvas.drawPath(head, arrow);
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) => true;
}