import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Logo yang sama dengan ikon aplikasi, digambar bertahap sesuai [progress] (0-1):
/// sumbu tubuh muncul dari atas ke bawah, lalu tiga garis kiri-kanan memanjang
/// dari tengah, lalu titik di ujungnya muncul memantul.
class SplashLogoPainter extends CustomPainter {
  SplashLogoPainter({required this.progress});

  final double progress;

  static const Color _lineColor = Color(0xFF7FD6CE);
  static const List<List<Offset>> _pairs = <List<Offset>>[
    <Offset>[Offset(0.13, 0.20), Offset(0.87, 0.25)],
    <Offset>[Offset(0.23, 0.51), Offset(0.77, 0.49)],
    <Offset>[Offset(0.17, 0.77), Offset(0.83, 0.80)],
  ];

  double _phase(double start, double end, Curve curve) {
    final double t = ((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble();
    return curve.transform(t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    Offset at(double x, double y) => Offset(x * w, y * h);

    // 1. Sumbu tubuh: 15 titik dari atas ke bawah
    final Paint axisPaint = Paint()..color = _lineColor;
    final double axisProgress = _phase(0.0, 0.35, Curves.easeOut);
    for (int i = 0; i < 15; i++) {
      final double t = 0.03 + i * (0.94 / 14);
      if (t > 0.03 + axisProgress * 0.94 + 1e-6) break;
      final double x = 0.5 + 0.045 * math.sin(2 * math.pi * t);
      canvas.drawCircle(at(x, t), 0.017 * w, axisPaint);
    }

    // 2. Tiga garis kiri-kanan, berurutan dari atas
    final Paint linePaint = Paint()
      ..color = _lineColor
      ..strokeWidth = 0.034 * w
      ..strokeCap = StrokeCap.round;
    final Paint dotPaint = Paint()..color = Colors.white;
    for (int i = 0; i < _pairs.length; i++) {
      final double start = 0.25 + i * 0.08;
      final double grow = _phase(start, start + 0.22, Curves.easeOutCubic);
      if (grow <= 0) continue;
      final Offset a = _pairs[i][0];
      final Offset b = _pairs[i][1];
      final double mx = (a.dx + b.dx) / 2;
      final double my = (a.dy + b.dy) / 2;
      canvas.drawLine(
        at(mx + (a.dx - mx) * grow, my + (a.dy - my) * grow),
        at(mx + (b.dx - mx) * grow, my + (b.dy - my) * grow),
        linePaint,
      );

      // 3. Titik di kedua ujung muncul setelah garisnya hampir penuh
      final double pop = _phase(start + 0.18, start + 0.36, Curves.elasticOut);
      if (pop > 0) {
        final double r = 0.058 * w * pop;
        canvas.drawCircle(at(a.dx, a.dy), r, dotPaint);
        canvas.drawCircle(at(b.dx, b.dy), r, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SplashLogoPainter oldDelegate) => oldDelegate.progress != progress;
}