import 'package:flutter/material.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dashed_path.dart';

/// Kerangka bantu foto punggung: badan dari pangkal leher sampai pinggul
/// (tanpa kepala), garis tengah tegak, garis acuan bahu dan pinggul, dan sudut bingkai.
/// Semua posisi relatif terhadap ukuran bingkai, jadi bentuknya sama di semua HP.
class SilhouetteGuidePainter extends CustomPainter {
  const SilhouetteGuidePainter({this.showLabels = true, this.compact = false});

  final bool showLabels; // tulisan "Bahu" dan "Pinggul"
  final bool compact; // versi kecil untuk gambar contoh di lembar panduan

  // Tinggi garis acuan (pecahan dari tinggi bingkai).
  static const double neckY = 0.05;
  static const double shoulderY = 0.19;
  static const double hipY = 0.84;

  /// Garis luar badan dilihat dari belakang. x dan y dalam pecahan 0-1.
  static Path torso(Size s) {
    Offset p(double x, double y) => Offset(x * s.width, y * s.height);
    final Path path = Path();
    for (final double side in <double>[-1, 1]) {
      double x(double fromCenter) => 0.5 + side * fromCenter;
      // leher
      path.moveTo(p(x(0.07), neckY).dx, p(x(0.07), neckY).dy);
      path.lineTo(p(x(0.07), 0.10).dx, p(x(0.07), 0.10).dy);
      // bahu: dari leher melengkung ke ujung bahu
      final Offset c1 = p(x(0.16), 0.12);
      final Offset shoulder = p(x(0.38), shoulderY);
      path.quadraticBezierTo(c1.dx, c1.dy, shoulder.dx, shoulder.dy);
      // lengan atas / sisi badan turun ke ketiak
      final Offset c2 = p(x(0.43), 0.24);
      final Offset armpit = p(x(0.34), 0.40);
      path.quadraticBezierTo(c2.dx, c2.dy, armpit.dx, armpit.dy);
      // pinggang (lekuk ke dalam)
      final Offset c3 = p(x(0.27), 0.55);
      final Offset waist = p(x(0.28), 0.66);
      path.quadraticBezierTo(c3.dx, c3.dy, waist.dx, waist.dy);
      // pinggul (melebar lagi), lalu turun ke bawah bingkai
      final Offset c4 = p(x(0.33), hipY - 0.04);
      final Offset hip = p(x(0.34), hipY + 0.04);
      path.quadraticBezierTo(c4.dx, c4.dy, hip.dx, hip.dy);
      path.lineTo(p(x(0.33), 0.97).dx, p(x(0.33), 0.97).dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final double w = size.width;
    final double h = size.height;
    final double stroke = compact ? 1.5 : 2.5;

    // Garis tengah tegak: posisi tulang belakang yang lurus.
    final Paint centerLine = Paint()
      ..color = const Color(0x73FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1 : 1.5;
    drawDashedPath(
      canvas,
      Path()
        ..moveTo(w / 2, h * 0.02)
        ..lineTo(w / 2, h * 0.98),
      centerLine,
      compact ? 4 : 6,
      compact ? 5 : 8,
    );

    // Garis acuan bahu dan pinggul.
    final Paint guide = Paint()
      ..color = const Color(0x99FFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1 : 1.5;
    for (final double y in <double>[shoulderY, hipY]) {
      drawDashedPath(
        canvas,
        Path()
          ..moveTo(w * 0.06, h * y)
          ..lineTo(w * 0.94, h * y),
        guide,
        compact ? 3 : 5,
        compact ? 4 : 6,
      );
    }

    // Garis luar badan.
    final Paint outline = Paint()
      ..color = AppColors.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    drawDashedPath(canvas, torso(size), outline, compact ? 6 : 10, compact ? 5 : 8);

    if (showLabels && !compact) {
      _label(canvas, tr('Bahu'), Offset(w * 0.06, h * shoulderY - 18));
      _label(canvas, tr('Pinggul'), Offset(w * 0.06, h * hipY + 4));
    }
    canvas.restore();

    if (compact) return;
    // Sudut bingkai.
    final Paint corner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const double m = 16;
    const double len = 24;
    canvas.drawLine(const Offset(m, m), const Offset(m + len, m), corner);
    canvas.drawLine(const Offset(m, m), const Offset(m, m + len), corner);
    canvas.drawLine(Offset(w - m, m), Offset(w - m - len, m), corner);
    canvas.drawLine(Offset(w - m, m), Offset(w - m, m + len), corner);
    canvas.drawLine(Offset(m, h - m), Offset(m + len, h - m), corner);
    canvas.drawLine(Offset(m, h - m), Offset(m, h - m - len), corner);
    canvas.drawLine(Offset(w - m, h - m), Offset(w - m - len, h - m), corner);
    canvas.drawLine(Offset(w - m, h - m), Offset(w - m, h - m - len), corner);
  }

  void _label(Canvas canvas, String text, Offset at) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFFFE082),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          shadows: <Shadow>[Shadow(color: Color(0xAA000000), blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant SilhouetteGuidePainter oldDelegate) =>
      oldDelegate.showLabels != showLabels || oldDelegate.compact != compact;
}