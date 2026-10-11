import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../utils/risk_style.dart';

class RiskChip extends StatelessWidget {
  const RiskChip({super.key, required this.level, this.prefix = ''});

  final String? level;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final String text = level == null ? '-' : '$prefix$level';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: riskTint(level),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: ts(13, weight: FontWeight.w700, color: riskColor(level), height: 18),
      ),
    );
  }
}