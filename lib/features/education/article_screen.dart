import 'package:flutter/material.dart' hide Text;
import '../../core/i18n/tr_text.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/icon_title.dart';
import '../../data/models/article.dart';

class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key, required this.article});

  final Article article;

  Widget _buildLine(String line) {
    if (!line.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(line, style: ts(15, height: 23)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 9, left: 4, right: 12),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
            ),
          ),
          Expanded(child: Text(line.substring(2), style: ts(15, height: 23))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: CircleIconButton(
                icon: Icons.arrow_back,
                label: 'Kembali',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: IconTile(icon: article.icon),
            ),
            const SizedBox(height: 12),
            Text(article.title, style: ts(24, weight: FontWeight.w800, height: 30)),
            const SizedBox(height: 16),
            for (final String line in article.body) _buildLine(line),
            const SizedBox(height: 8),
            Text(
              'Informasi umum, bukan nasihat medis.',
              style: ts(12, color: AppColors.muted, height: 17),
            ),
          ],
        ),
      ),
    );
  }
}