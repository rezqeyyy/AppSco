import 'package:flutter/material.dart' hide Text;

import '../../core/i18n/tr_text.dart';
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

  // Warna ikon tiap topik: satu keluarga hijau-biru supaya serasi.
  static const List<(Color, Color)> _tones = <(Color, Color)>[
    (AppColors.tealTint, AppColors.teal),
    (AppColors.sky, Color(0xFF16708A)),
    (AppColors.lavender, Color(0xFF3C5F86)),
    (AppColors.amberTint, AppColors.amber),
  ];

  /// Perkiraan lama baca (200 kata per menit).
  static int _minutes(Article a) {
    final int words = a.body.join(' ').split(RegExp(r'\s+')).length;
    return (words / 200).ceil().clamp(1, 30);
  }

  @override
  Widget build(BuildContext context) {
    final Article featured = articles[0];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: <Widget>[
        Text('Edukasi', style: ts(26, weight: FontWeight.w800, height: 32, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(
          'Kenali skoliosis dan cara memeriksanya di rumah.',
          style: ts(14, color: AppColors.muted, height: 20),
        ),
        const SizedBox(height: 18),
        _buildFeatured(context, featured),
        const SizedBox(height: 26),
        Row(
          children: <Widget>[
            const Expanded(child: SectionTitle('Topik')),
            Text(
              '${articles.length - 1} artikel',
              translate: false,
              style: ts(13, color: AppColors.muted, height: 18),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (int i = 1; i < articles.length; i++) ...<Widget>[
          _buildTopic(context, articles[i], _tones[(i - 1) % _tones.length]),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildFeatured(BuildContext context, Article featured) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x330B4F4A), blurRadius: 28, offset: Offset(0, 14)),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: InkWell(
            onTap: () => openArticle(context, featured),
            child: Stack(
              children: <Widget>[
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
                  ),
                ),
                const Positioned(
                  right: 18,
                  top: 14,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(Color(0x99FFFFFF), BlendMode.srcIn),
                    child: CustomPaint(size: Size(72, 150), painter: SpineMotifPainter()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.star_rounded, size: 14, color: AppColors.mint),
                            const SizedBox(width: 5),
                            Text('Mulai dari sini', style: ts(12, weight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              featured.title,
                              style: ts(22, weight: FontWeight.w800, color: Colors.white, height: 28, letterSpacing: -0.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              featured.summary,
                              style: ts(14, color: Colors.white.withValues(alpha: 0.8), height: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 9, 10, 9),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text('Baca sekarang', style: ts(14, weight: FontWeight.w800, color: AppColors.teal)),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.teal),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.schedule_rounded, size: 15, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '${_minutes(featured)} ${tr('menit')}',
                            translate: false,
                            style: ts(12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopic(BuildContext context, Article article, (Color, Color) tone) {
    return AppCard(
      onTap: () => openArticle(context, article),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          IconTile(icon: article.icon, size: 52, background: tone.$1, foreground: tone.$2),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(article.title, style: ts(15, weight: FontWeight.w800, height: 20)),
                const SizedBox(height: 3),
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ts(13, color: AppColors.muted, height: 18),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    const Icon(Icons.schedule_rounded, size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${_minutes(article)} ${tr('menit')}',
                      translate: false,
                      style: ts(12, color: AppColors.muted, height: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: AppColors.ground, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded, size: 17, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}