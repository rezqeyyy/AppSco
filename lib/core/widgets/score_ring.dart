import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import '../i18n/tr_text.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Cincin skor 0-100 dengan angka di tengah.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, required this.color, this.size = 76, this.caption});

  final double? score; // 0-1
  final Color color;
  final double size;
  final String? caption; // tulisan kecil di bawah angka

  @override
  Widget build(BuildContext context) {
    final double? s = score;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(s == null ? 0 : s.clamp(0.0, 1.0).toDouble(), color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                s == null ? '-' : '${(s * 100).round()}',
                translate: false,
                style: ts(size * 0.3, weight: FontWeight.w800, color: AppColors.ink, height: size * 0.34),
              ),
              if (caption != null)
                Text(caption!, translate: false, style: ts(size * 0.12, color: AppColors.muted, height: size * 0.15)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color);

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke = size.width * 0.1;
    final Rect rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final Paint track = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final Paint arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (value > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value || old.color != color;
}