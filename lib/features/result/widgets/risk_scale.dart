import 'package:flutter/material.dart' hide Text;

import '../../../core/constants/app_config.dart';
import '../../../core/i18n/tr_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Skala Rendah | Sedang | Tinggi dengan penanda di posisi skor.
///
/// Ketiga bagian digambar sama lebar supaya mudah dibaca. Penanda ditempatkan
/// di dalam bagian yang sesuai dengan tingkat risiko dari server, memakai batas
/// risiko yang dikirim server ([thresholds]). Jadi tulisan dan penanda selalu cocok.
class RiskScale extends StatelessWidget {
  const RiskScale({super.key, required this.score, this.level, this.thresholds});

  final double? score;
  final String? level; // 'Rendah' | 'Sedang' | 'Tinggi' dari server
  final dynamic thresholds; // [batas Rendah|Sedang, batas Sedang|Tinggi] dari server

  static const List<String> _levels = <String>['Rendah', 'Sedang', 'Tinggi'];

  Widget _bar(Color color) {
    return Container(
      height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
    );
  }

  /// Batas risiko: dari server kalau ada, kalau tidak dari app_config.
  (double, double) _limits() {
    final dynamic t = thresholds;
    if (t is List && t.length == 2 && t[0] is num && t[1] is num) {
      final double lo = (t[0] as num).toDouble();
      final double hi = (t[1] as num).toDouble();
      if (lo > 0 && lo < hi && hi < 1) return (lo, hi);
    }
    return (riskLowMax, riskMidMax);
  }

  /// Posisi penanda 0-1 pada skala yang tiap bagiannya selebar 1/3.
  double _position(double s) {
    final (double lo, double hi) = _limits();
    final double v = s.clamp(0.0, 1.0).toDouble();
    int band = v < lo ? 0 : (v < hi ? 1 : 2);
    final int fromServer = _levels.indexOf(level ?? '');
    if (fromServer >= 0) band = fromServer; // tingkat dari server yang menentukan bagiannya
    final List<double> edges = <double>[0, lo, hi, 1];
    final double start = edges[band];
    final double end = edges[band + 1];
    final double frac = end > start ? ((v - start) / (end - start)).clamp(0.0, 1.0).toDouble() : 0.5;
    // Jangan menempel ke ujung bagian supaya jelas berada di bagian mana.
    return (band + 0.1 + frac * 0.8) / 3;
  }

  @override
  Widget build(BuildContext context) {
    final double? value = score;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double markerLeft = value == null ? 0.0 : width * _position(value) - 10;
            return SizedBox(
              height: 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 5,
                    child: Row(
                      children: <Widget>[
                        Expanded(child: _bar(AppColors.teal)),
                        const SizedBox(width: 3),
                        Expanded(child: _bar(AppColors.amberBar)),
                        const SizedBox(width: 3),
                        Expanded(child: _bar(AppColors.red)),
                      ],
                    ),
                  ),
                  if (value != null)
                    Positioned(
                      left: markerLeft,
                      top: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(color: AppColors.ink, spreadRadius: 1),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: Text('Rendah', style: ts(12, color: AppColors.muted, height: 16)),
            ),
            Expanded(
              child: Text(
                'Sedang',
                textAlign: TextAlign.center,
                style: ts(12, color: AppColors.muted, height: 16),
              ),
            ),
            Expanded(
              child: Text(
                'Tinggi',
                textAlign: TextAlign.right,
                style: ts(12, color: AppColors.muted, height: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }
}