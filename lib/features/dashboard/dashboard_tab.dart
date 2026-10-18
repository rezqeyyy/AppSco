import 'package:flutter/material.dart' hide Text;

import '../../core/constants/app_config.dart';
import '../../core/i18n/tr_text.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/risk_style.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/risk_chip.dart';
import '../../core/widgets/score_ring.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/content/articles.dart';
import '../../data/models/article.dart';
import '../../data/models/screening_record.dart';
import '../../state/app_data.dart';
import '../tour/tour_keys.dart';
import 'widgets/language_sheet.dart';

class BerandaTab extends StatelessWidget {
  const BerandaTab({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  static String _greeting() {
    final int h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (BuildContext context, Widget? child) {
        final ScreeningRecord? last = appData.records.isEmpty ? null : appData.records.first;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: <Widget>[
            _buildHeader(),
            const SizedBox(height: 22),
            _buildHero(context),
            const SizedBox(height: 26),
            Row(
              children: <Widget>[
                const Expanded(child: SectionTitle('Hasil terakhir')),
                if (last != null)
                  TextButton(
                    onPressed: () => onOpenTab(1),
                    style: TextButton.styleFrom(foregroundColor: AppColors.teal),
                    child: Text('Lihat riwayat', style: ts(13, weight: FontWeight.w700, color: AppColors.teal)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: TourKeys.lastResult,
              child: last == null ? _buildEmptyResult() : _buildLastResult(context, last),
            ),
            if (appData.records.length >= 2) ...<Widget>[
              const SizedBox(height: 12),
              _buildStats(),
            ],
            const SizedBox(height: 26),
            Row(
              children: <Widget>[
                const Expanded(child: SectionTitle('Pelajari')),
                TextButton(
                  onPressed: () => onOpenTab(2),
                  style: TextButton.styleFrom(foregroundColor: AppColors.teal),
                  child: Text('Semua artikel', style: ts(13, weight: FontWeight.w700, color: AppColors.teal)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: TourKeys.learn,
              child: SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: articles.length,
                  separatorBuilder: (BuildContext context, int i) => const SizedBox(width: 12),
                  itemBuilder: (BuildContext context, int i) => _buildLearnCard(context, articles[i], i),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alat screening awal, bukan pengganti pemeriksaan dokter.',
                    style: ts(12, color: AppColors.muted, height: 17),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Avatar + sapaan + tombol bahasa.
  Widget _buildHeader() {
    final String name = appData.name.trim();
    return Row(
      children: <Widget>[
        Tooltip(
          message: tr('Buka profil'),
          child: GestureDetector(
            onTap: () => onOpenTab(3),
            child: const UserAvatar(size: 50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(_greeting(), style: ts(13, color: AppColors.muted, height: 18)),
              Text(
                name.isEmpty ? appName : name,
                translate: false,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(22, weight: FontWeight.w800, height: 28, letterSpacing: -0.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const LanguageButton(),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x330B4F4A), blurRadius: 28, offset: Offset(0, 14)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          // Dua lingkaran samar di pojok kanan bawah sebagai hiasan.
          Positioned(
            right: -60,
            bottom: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
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
                          const Icon(Icons.auto_awesome, size: 14, color: AppColors.mint),
                          const SizedBox(width: 6),
                          Text('Screening AI', style: ts(12, weight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Cek postur punggungmu',
                  style: ts(24, weight: FontWeight.w800, color: Colors.white, height: 30, letterSpacing: -0.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cukup satu foto punggung dari belakang. Hasilnya keluar dalam hitungan detik.',
                  style: ts(14, color: Colors.white.withValues(alpha: 0.8), height: 20),
                ),
                const SizedBox(height: 20),
                KeyedSubtree(
                  key: TourKeys.startScreening,
                  child: FilledButton(
                    onPressed: () => openGuide(context),
                    style: accentButtonStyle(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('Mulai screening'),
                        const SizedBox(width: 12),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResult() {
    return AppCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.limeTint, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.accessibility_new_rounded, color: AppColors.teal, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Belum ada screening', style: ts(15, weight: FontWeight.w800, height: 20)),
                const SizedBox(height: 2),
                Text(
                  'Hasil yang disimpan akan muncul di sini.',
                  style: ts(13, color: AppColors.muted, height: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastResult(BuildContext context, ScreeningRecord last) {
    final String? level = last.riskLevel;
    return AppCard(
      onTap: () => openRecord(context, last),
      child: Row(
        children: <Widget>[
          ScoreRing(score: last.riskScore, color: riskColor(level), size: 78, caption: '/100'),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RiskChip(level: level, prefix: 'Risiko '),
                const SizedBox(height: 8),
                Text(
                  riskSummary(level),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ts(13, color: AppColors.inkSoft, height: 18),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.muted),
                    const SizedBox(width: 5),
                    Text(formatDate(last.date), style: ts(12, color: AppColors.muted, height: 16)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }

  // Ringkasan kecil: jumlah screening dan perubahan skor dari sebelumnya.
  Widget _buildStats() {
    final List<ScreeningRecord> r = appData.records;
    final double? now = r[0].riskScore;
    final double? before = r[1].riskScore;
    String change = '-';
    IconData icon = Icons.trending_flat_rounded;
    Color color = AppColors.muted;
    if (now != null && before != null) {
      final int diff = ((now - before) * 100).round();
      change = diff == 0 ? 'Sama' : '${diff > 0 ? '+' : ''}$diff';
      icon = diff > 0 ? Icons.trending_up_rounded : (diff < 0 ? Icons.trending_down_rounded : Icons.trending_flat_rounded);
      color = diff > 0 ? AppColors.red : (diff < 0 ? AppColors.teal : AppColors.muted);
    }
    return Row(
      children: <Widget>[
        Expanded(child: _statTile(Icons.fact_check_outlined, '${r.length}', 'Total screening', AppColors.teal, AppColors.tealTint)),
        const SizedBox(width: 12),
        Expanded(child: _statTile(icon, change, 'Dibanding sebelumnya', color, AppColors.limeTint)),
      ],
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color color, Color tint) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => onOpenTab(1),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(value, translate: false, style: ts(18, weight: FontWeight.w800, height: 22)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, color: AppColors.muted, height: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const List<Color> _cardTints = <Color>[
    AppColors.limeTint,
    AppColors.lavender,
    AppColors.sky,
    AppColors.peach,
    AppColors.tealTint,
  ];

  Widget _buildLearnCard(BuildContext context, Article article, int i) {
    return SizedBox(
      width: 150,
      child: Material(
        color: _cardTints[i % _cardTints.length],
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openArticle(context, article),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(article.icon, size: 18, color: AppColors.tealDark),
                ),
                const SizedBox(height: 10),
                // Tempat judul selalu 2 baris, jadi semua kartu rata dan tidak meluber.
                SizedBox(
                  height: 38,
                  child: Text(
                    article.shortTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ts(14, weight: FontWeight.w800, height: 19),
                  ),
                ),
                const Spacer(),
                Row(
                  children: <Widget>[
                    Text('Baca', style: ts(12, weight: FontWeight.w700, color: AppColors.tealDark)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.tealDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}