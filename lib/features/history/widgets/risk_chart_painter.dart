import 'package:flutter/material.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/dashed_path.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/screening_record.dart';

/// Grafik garis skor risiko dengan dua garis batas tingkat risiko.
class RiskChartPainter extends CustomPainter {
  RiskChartPainter({required this.records});

  final List<ScreeningRecord> records; // urut dari yang lama ke yang baru

  // alignX: 0 = teks mulai di titik, 0.5 = teks di tengah titik, 1 = teks berakhir di titik
  void _text(Canvas canvas, String text, Offset anchor, TextStyle style, double alignX) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(anchor.dx - painter.width * alignX, anchor.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double chartTop = 10;
    final double chartBottom = size.height - 22;
    const double chartLeft = 20;
    final double chartRight = size.width - 62;

    double yOf(double score) {
      return chartBottom - score.clamp(0.0, 1.0).toDouble() * (chartBottom - chartTop);
    }

    final TextStyle small = ts(11, weight: FontWeight.w600, color: AppColors.muted);

    // Garis dasar dan garis batas tingkat risiko
    final Paint baseLine = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, chartBottom), Offset(size.width, chartBottom), baseLine);

    final Paint threshold = Paint()
      ..color = const Color(0xFFB9C6C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final double limit in <double>[riskLowMax, riskMidMax]) {
      final Path dashLine = Path();
      dashLine.moveTo(0, yOf(limit));
      dashLine.lineTo(size.width, yOf(limit));
      drawDashedPath(canvas, dashLine, threshold, 4, 5);
    }
    _text(canvas, tr('Tinggi'), Offset(size.width, yOf((1 + riskMidMax) / 2) - 7), small, 1);
    _text(canvas, tr('Sedang'), Offset(size.width, yOf((riskLowMax + riskMidMax) / 2) - 7), small, 1);
    _text(canvas, tr('Rendah'), Offset(size.width, yOf(riskLowMax / 2) - 7), small, 1);

    // Titik data
    final List<Offset> dots = <Offset>[];
    double? lastScore;
    for (int i = 0; i < records.length; i++) {
      final double x = records.length == 1
          ? (chartLeft + chartRight) / 2
          : chartLeft + (chartRight - chartLeft) * i / (records.length - 1);
      _text(canvas, tr(formatDayMonth(records[i].date)), Offset(x, chartBottom + 6), small, 0.5);
      final double? score = records[i].riskScore;
      if (score == null) continue;
      dots.add(Offset(x, yOf(score)));
      lastScore = score;
    }
    if (dots.isEmpty) return;

    final Paint linePaint = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path dataLine = Path();
    dataLine.moveTo(dots.first.dx, dots.first.dy);
    for (int i = 1; i < dots.length; i++) {
      dataLine.lineTo(dots[i].dx, dots[i].dy);
    }
    canvas.drawPath(dataLine, linePaint);

    final Paint white = Paint()..color = Colors.white;
    final Paint tealFill = Paint()..color = AppColors.teal;
    for (int i = 0; i < dots.length; i++) {
      if (i == dots.length - 1) {
        canvas.drawCircle(dots[i], 7, white);
        canvas.drawCircle(dots[i], 5.5, tealFill);
      } else {
        canvas.drawCircle(dots[i], 5.5, tealFill);
        canvas.drawCircle(dots[i], 3, white);
      }
    }

    // Nilai screening terbaru ditulis di dekat titiknya
    final Offset lastDot = dots.last;
    final double labelY = lastDot.dy - 26 > 0 ? lastDot.dy - 26 : lastDot.dy + 10;
    _text(
      canvas,
      formatPercent(lastScore),
      Offset(lastDot.dx, labelY),
      ts(12, weight: FontWeight.w800),
      0.5,
    );
  }

  @override
  bool shouldRepaint(covariant RiskChartPainter oldDelegate) => true;
}