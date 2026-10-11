import 'package:flutter/material.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/icon_title.dart';
import '../../core/widgets/section_title.dart';
import '../../data/content/articles.dart';
import '../../data/models/article.dart';
import 'widgets/spine_motif_painter.dart';

class EdukasiTab extends StatelessWidget {
  const EdukasiTab({super.key});

  @override
  Widget build(BuildContext context) {
    final Article featured = articles[0];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('Edukasi', style: ts(24, weight: FontWeight.w800, height: 30)),
        const SizedBox(height: 20),
        Material(
          color: AppColors.tealTint,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openArticle(context, featured),
            child: Stack(
              children: <Widget>[
                const Positioned(
                  right: 16,
                  top: 8,
                  child: CustomPaint(size: Size(72, 150), painter: SpineMotifPainter()),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Mulai dari sini',
                          style: ts(
                            12,
                            weight: FontWeight.w700,
                            color: AppColors.tealDark,
                            height: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 230),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              featured.title,
                              style: ts(20, weight: FontWeight.w800, height: 26),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              featured.summary,
                              style: ts(14, color: AppColors.inkSoft, height: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Baca',
                            style: ts(14, weight: FontWeight.w700, color: AppColors.tealDark),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.tealDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Topik'),
        const SizedBox(height: 10),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (int i = 1; i < articles.length; i++)
                _buildTopic(context, articles[i], i == articles.length - 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopic(BuildContext context, Article article, bool isLast) {
    return InkWell(
      onTap: () => openArticle(context, article),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.lineSoft)),
        ),
        child: Row(
          children: <Widget>[
            IconTile(
              icon: article.icon,
              background: isLast ? AppColors.amberTint : AppColors.tealTint,
              foreground: isLast ? AppColors.amber : AppColors.teal,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(article.title, style: ts(14, weight: FontWeight.w700, height: 20)),
                  const SizedBox(height: 2),
                  Text(article.summary, style: ts(13, color: AppColors.muted, height: 18)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}