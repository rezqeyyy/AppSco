import 'package:flutter/material.dart' hide Text;

import '../i18n/tr_text.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: ts(17, weight: FontWeight.w800, color: AppColors.ink, height: 22, letterSpacing: -0.2),
    );
  }
}