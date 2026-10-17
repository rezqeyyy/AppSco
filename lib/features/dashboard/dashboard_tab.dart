import 'package:flutter/material.dart' hide Text;

import '../../core/constants/app_config.dart';
import '../../core/i18n/tr_text.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/risk_chip.dart';
import '../../core/widgets/section_title.dart';
import '../../data/content/articles.dart';
import '../../data/models/article.dart';
import '../../data/models/screening_record.dart';
import '../../state/app_data.dart';
import '../tour/tour_keys.dart';
import 'widgets/hero_motif_painter.dart';
import 'widgets/language_sheet.dart';

class BerandaTab extends StatelessWidget {
  const BerandaTab({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (BuildContext context, Widget? child) {
        final ScreeningRecord? last = appData.records.isEmpty ? null : appData.records.first;
        final String greeting = appData.name.isEmpty ? 'Halo!' : 'Halo, ${appData.name}';
        return ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        appName,
                        translate: false, // nama aplikasi tidak diterjemahkan
                        style: ts(
                          13,
                          weight: FontWeight.w800,
                          color: AppColors.teal,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        greeting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(24, weight: FontWeight.w800, height: 30),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const LanguageButton(),
                const SizedBox(width: 8),
                CircleIconButton(
                  icon: Icons.person_outline,
                  label: 'Buka profil',
                  onTap: () => onOpenTab(3),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildHero(context),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                const Expanded(child: SectionTitle('Hasil terakhir')),
                TextButton(
                  onPressed: () => onOpenTab(1),
                  child: Text(
                    'Lihat riwayat',
                    style: ts(13, weight: FontWeight.w700, color: AppColors.teal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            KeyedSubtree(
              key: TourKeys.lastResult,
              child: last == null
                  ? AppCard(
                      child: Text(
                        'Belum ada screening. Hasil yang disimpan akan muncul di sini.',
                        style: ts(14, color: AppColors.muted, height: 20),
                      ),
                    )
                  : _buildLastResult(context, last),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Pelajari'),
            const SizedBox(height: 10),
            KeyedSubtree(
              key: TourKeys.learn,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _buildLearnCard(context, articles[0])),
                  const SizedBox(width: 12),
                  Expanded(child: _buildLearnCard(context, articles[2])),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Alat screening awal, bukan pengganti pemeriksaan dokter.',
              textAlign: TextAlign.center,
              style: ts(12, color: AppColors.muted, height: 17),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHero(BuildContext context) {
    return Material(
      color: AppColors.teal,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          const Positioned(
            right: 12,
            top: 0,
            child: CustomPaint(size: Size(96, 200), painter: HeroMotifPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Screening baru',
                        style: ts(20, weight: FontWeight.w800, color: Colors.white, height: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Satu foto punggung dari belakang. Aplikasi menandai titik tubuh dan menghitung tingkat risikonya.',
                        style: ts(14, color: AppColors.tealPale, height: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: TourKeys.startScreening,
                  child: FilledButton.icon(
                    onPressed: () => openGuide(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.teal,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: const StadiumBorder(),
                      textStyle: ts(15, weight: FontWeight.w700),
                    ),
                    icon: const Icon(Icons.photo_camera_outlined, size: 22),
                    label: const Text('Mulai screening'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastResult(BuildContext context, ScreeningRecord last) {
    return AppCard(
      onTap: () => openRecord(context, last),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(formatDate(last.date), style: ts(13, color: AppColors.muted, height: 18)),
                const SizedBox(height: 8),
                RiskChip(level: last.riskLevel, prefix: 'Risiko '),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                formatPercent(last.riskScore),
                style: ts(28, weight: FontWeight.w800, height: 32),
              ),
              Text('skor risiko', style: ts(12, color: AppColors.muted, height: 16)),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
        ],
      ),
    );
  }

  Widget _buildLearnCard(BuildContext context, Article article) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => openArticle(context, article),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(article.icon, size: 22, color: AppColors.teal),
          const SizedBox(height: 8),
          Text(article.shortTitle, style: ts(14, weight: FontWeight.w700, height: 19)),
        ],
      ),
    );
  }
}