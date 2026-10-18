import 'package:flutter/material.dart';

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

  /// Titik-titik garis tengah tubuh, urut dari atas ke bawah. Titik yang jauh ke samping
  /// (misalnya bahu atau titik yang salah tempat) tidak ikut, supaya garisnya mengikuti tulang belakang.
  static List<Offset> spinePath(List<MeasuredPoint> points, {double minConfidence = 0.25}) {
    final List<MeasuredPoint> candidates =
        points.where((MeasuredPoint p) => p.conf > minConfidence).toList();
    if (candidates.length < 2) return const <Offset>[];
    final List<double> xs = candidates.map((MeasuredPoint p) => p.pos.dx).toList()..sort();
    final double medianX = xs[xs.length ~/ 2];
    final List<double> ys = candidates.map((MeasuredPoint p) => p.pos.dy).toList()..sort();
    final double height = (ys.last - ys.first).abs();
    // Toleransi ke samping: 15% dari panjang tulang belakang (minimal 4% lebar foto).
    final double maxDx = (height * 0.15).clamp(0.04, 0.2).toDouble();
    final List<Offset> spine = candidates
        .where((MeasuredPoint p) => (p.pos.dx - medianX).abs() <= maxDx)
        .map((MeasuredPoint p) => p.pos)
        .toList()
      ..sort((Offset a, Offset b) => a.dy.compareTo(b.dy));
    return spine;
  }

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

    // 2. Garis tulang belakang: menyambung SEMUA titik di garis tengah tubuh dari atas ke bawah.
    //    (Sumbu dari server hanya memakai beberapa titik, jadi garisnya berhenti di tengah.)
    final List<Offset> spine = spinePath(points);
    final List<Offset> path = spine.length >= 2 ? spine : axis;
    if (path.length >= 2) {
      // Garis lurus pembanding (putus-putus) dari titik paling atas ke paling bawah.
      final Offset top = px(path.first);
      final Offset bottom = px(path.last);
      final Paint dashShadow = Paint()
        ..color = Colors.black54
        ..strokeWidth = 3;
      final Paint dash = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5;
      final double length = (bottom - top).distance;
      if (length > 0) {
        final Offset dir = (bottom - top) / length;
        for (double d = 0; d < length; d += 12) {
          final Offset a = top + dir * d;
          final Offset b = top + dir * (d + 6 < length ? d + 6 : length);
          canvas.drawLine(a, b, dashShadow);
          canvas.drawLine(a, b, dash);
        }
      }

      for (int i = 0; i < path.length - 1; i++) {
        line(px(path[i]), px(path[i + 1]), axisColor, 3);
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