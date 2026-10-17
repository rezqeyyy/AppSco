import 'package:flutter/material.dart' hide Text;
import '../../../core/i18n/tr_text.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Skala Rendah | Sedang | Tinggi dengan penanda di posisi skor.
class RiskScale extends StatelessWidget {
  const RiskScale({super.key, required this.score});

  final double? score;

  Widget _bar(Color color) {
    return Container(
      height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int lowFlex = (riskLowMax * 100).round();
    final int midFlex = ((riskMidMax - riskLowMax) * 100).round();
    final int highFlex = 100 - lowFlex - midFlex;
    final double? value = score;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double markerLeft =
                value == null ? 0.0 : width * value.clamp(0.0, 1.0).toDouble() - 10;
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
                        Expanded(flex: lowFlex, child: _bar(AppColors.teal)),
                        const SizedBox(width: 3),
                        Expanded(flex: midFlex, child: _bar(AppColors.amberBar)),
                        const SizedBox(width: 3),
                        Expanded(flex: highFlex, child: _bar(AppColors.red)),
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
              flex: lowFlex,
              child: Text('Rendah', style: ts(12, color: AppColors.muted, height: 16)),
            ),
            Expanded(
              flex: midFlex,
              child: Text(
                'Sedang',
                textAlign: TextAlign.center,
                style: ts(12, color: AppColors.muted, height: 16),
              ),
            ),
            Expanded(
              flex: highFlex,
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