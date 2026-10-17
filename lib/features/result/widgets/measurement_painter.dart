import 'package:flutter/material.dart' hide Text;
import '../../../core/i18n/tr_text.dart';

import '../../../data/models/measured_point.dart';

class MeasurementPainter extends CustomPainter {
  MeasurementPainter({
    required this.points,
    required this.pairs,
    required this.axis,
    this.showNumbers = false,
  });

  final List<MeasuredPoint> points;
  final List<List<int>> pairs;
  final List<Offset> axis;
  final bool showNumbers; // nomor titik: berguna untuk pengembang, membingungkan untuk orang awam

  /// Sama dengan kpt_conf di server: di bawah ini titik dianggap kurang yakin.
  static const double minConf = 0.5;

  static const Color pointColor = Color(0xFF00E676);
  static const Color weakColor = Color(0xFFBDBDBD);
  static const Color pairColor = Color(0xFFFFA726);
  static const Color axisColor = Color(0xFF00E5FF);

  @override
  void paint(Canvas canvas, Size size) {
    Offset px(Offset p) => Offset(p.dx * size.width, p.dy * size.height);

    // Tiap garis digambar dua kali (bayangan gelap lalu warna) supaya terlihat
    // di foto terang maupun gelap.
    void line(Offset a, Offset b, Color color, double width) {
      final Paint shadow = Paint()
        ..color = Colors.black54
        ..strokeWidth = width + 2
        ..strokeCap = StrokeCap.round;
      final Paint paint = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, shadow);
      canvas.drawLine(a, b, paint);
    }

    // 1. Garis pasangan kiri-kanan (misalnya bahu kiri ke bahu kanan)
    for (final List<int> pair in pairs) {
      final MeasuredPoint a = points[pair[0]];
      final MeasuredPoint b = points[pair[1]];
      final bool sure = a.conf > minConf && b.conf > minConf;
      line(px(a.pos), px(b.pos), sure ? pairColor : weakColor, 2);
    }

    // 2. Garis tegak acuan dan sumbu tubuh
    if (axis.length >= 2) {
      final Offset top = px(axis.first);
      final Offset bottom = px(axis.last);
      final Paint dashShadow = Paint()
        ..color = Colors.black54
        ..strokeWidth = 3;
      final Paint dash = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5;
      final double yStart = top.dy < bottom.dy ? top.dy : bottom.dy;
      final double yEnd = top.dy < bottom.dy ? bottom.dy : top.dy;
      for (double y = yStart; y < yEnd; y += 12) {
        final double y2 = y + 6 < yEnd ? y + 6 : yEnd;
        canvas.drawLine(Offset(top.dx, y), Offset(top.dx, y2), dashShadow);
        canvas.drawLine(Offset(top.dx, y), Offset(top.dx, y2), dash);
      }

      for (int i = 0; i < axis.length - 1; i++) {
        line(px(axis[i]), px(axis[i + 1]), axisColor, 3);
      }
      final Paint node = Paint()..color = axisColor;
      final Paint nodeEdge = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (final Offset p in axis) {
        canvas.drawCircle(px(p), 3.5, node);
        canvas.drawCircle(px(p), 3.5, nodeEdge);
      }
    }

    // 3. Titik tubuh (dan nomornya kalau showNumbers)
    final Paint ring = Paint()..color = Colors.white;
    final Paint edge = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < points.length; i++) {
      final Offset c = px(points[i].pos);
      final Paint fill = Paint()
        ..color = points[i].conf > minConf ? pointColor : weakColor;
      canvas.drawCircle(c, 6, ring);
      canvas.drawCircle(c, 6, edge);
      canvas.drawCircle(c, 4, fill);
      if (!showNumbers) continue;

      final TextPainter label = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: <Shadow>[
              Shadow(color: Colors.black, blurRadius: 3),
              Shadow(color: Colors.black, blurRadius: 3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Nomor di kanan-atas titik; digeser ke kiri kalau mentok tepi kanan foto.
      double dx = c.dx + 7;
      if (dx + label.width > size.width) dx = c.dx - 7 - label.width;
      double dy = c.dy - 7 - label.height;
      if (dy < 0) dy = c.dy + 7;
      label.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant MeasurementPainter oldDelegate) => true;
}