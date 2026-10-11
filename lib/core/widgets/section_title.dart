import 'package:flutter/material.dart';

import '../theme/app_text.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: ts(15, weight: FontWeight.w700, height: 20));
  }
}