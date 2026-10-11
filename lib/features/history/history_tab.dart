import 'package:flutter/material.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/icon_title.dart';
import '../../core/widgets/risk_chip.dart';
import '../../core/widgets/section_title.dart';
import '../../data/models/screening_record.dart';
import '../../state/app_data.dart';
import 'widgets/risk_chart_painter.dart';

class RiwayatTab extends StatelessWidget {
  const RiwayatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (BuildContext context, Widget? child) {
        final List<ScreeningRecord> records = appData.records;
        // Grafik: paling banyak 6 screening terakhir, urut dari yang lama ke yang baru.
        final List<ScreeningRecord> chart = records.take(6).toList().reversed.toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text('Riwayat', style: ts(24, weight: FontWeight.w800, height: 30)),
            const SizedBox(height: 20),
            if (records.isEmpty)
              _buildEmpty(context)
            else ...<Widget>[
              AppCard(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Expanded(child: SectionTitle('Skor risiko')),
                        Text(
                          '${chart.length} screening terakhir',
                          style: ts(13, color: AppColors.muted, height: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 152,
                      child: CustomPaint(painter: RiskChartPainter(records: chart)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Semua screening'),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < records.length; i++)
                      _buildRow(context, records[i], i == records.length - 1),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IconTile(icon: Icons.history),
          const SizedBox(height: 12),
          Text('Belum ada riwayat', style: ts(16, weight: FontWeight.w800, height: 22)),
          const SizedBox(height: 4),
          Text(
            'Setelah screening, tekan "Simpan ke riwayat" supaya hasilnya tercatat di sini dan perubahannya bisa dipantau.',
            style: ts(14, color: AppColors.muted, height: 20),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => openGuide(context),
            style: primaryButtonStyle(height: 48, fullWidth: false),
            child: const Text('Mulai screening'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, ScreeningRecord record, bool isLast) {
    return InkWell(
      onTap: () => openRecord(context, record),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.lineSoft)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                formatDate(record.date),
                style: ts(14, weight: FontWeight.w700, height: 20),
              ),
            ),
            RiskChip(level: record.riskLevel),
            const SizedBox(width: 10),
            SizedBox(
              width: 44,
              child: Text(
                formatPercent(record.riskScore),
                textAlign: TextAlign.right,
                style: ts(15, weight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}