import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/risk_style.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/section_title.dart';
import '../../data/models/feature_info.dart';
import '../../data/models/measured_point.dart';
import '../../data/models/screening_record.dart';
import '../../state/app_data.dart';
import '../guide/guide_screen.dart';
import '../reference/referral_flow.dart';
import 'utils/feature_describer.dart';
import 'utils/overlay_parser.dart';
import 'widgets/measurement_painter.dart';
import 'widgets/referral_card.dart';
import 'widgets/risk_scale.dart';

class HasilScreen extends StatefulWidget {
  const HasilScreen({super.key, required this.image, required this.result, this.record});

  final File image;
  final Map<String, dynamic> result;
  final ScreeningRecord? record; // terisi kalau dibuka dari riwayat

  @override
  State<HasilScreen> createState() => _HasilScreenState();
}

class _HasilScreenState extends State<HasilScreen> {
  bool _showOverlay = true;
  bool _saving = false;
  bool _saved = false;

    bool get _needsReferral {
    final dynamic score = widget.result['risk_score'];
    return score is num && score > referralThreshold;
  }

  @override
  void initState() {
    super.initState();
    // Hasil baru dengan skor di atas 60%: langsung tawarkan alur rujukan.
    if (widget.record == null && _needsReferral) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) => _promptReferral());
    }
  }

  Future<void> _promptReferral() async {
    if (!mounted) return;
    final bool ok = await confirmDialog(
      context,
      title: 'Skor risiko di atas 60%',
      message: appData.isSignedIn
          ? 'Sebaiknya periksakan ke dokter. Lihat rumah sakit terdekat dari lokasi Anda?'
          : 'Sebaiknya periksakan ke dokter. Untuk melihat rumah sakit terdekat, '
              'Anda perlu masuk ke akun dan mengisi data diri.',
      confirmLabel: 'Lanjutkan',
    );
    if (!ok || !mounted) return;
    await _openReferral();
  }

  Future<void> _openReferral() {
    return startReferral(context, widget.result, date: widget.record?.date);
  }

  Future<void> _save() async {
    if (_saved || _saving) return;
    setState(() {
      _saving = true;
    });
    await appData.addRecord(widget.image, widget.result);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tersimpan di riwayat.')));
  }

  Future<void> _delete() async {
    final ScreeningRecord? record = widget.record;
    if (record == null) return;
    final bool ok = await confirmDialog(
      context,
      title: 'Hapus hasil ini?',
      message: 'Hasil dan fotonya dihapus dari HP ini.',
      confirmLabel: 'Hapus',
    );
    if (!ok) return;
    await appData.deleteRecord(record);
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _retake() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (BuildContext context) => const PanduanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> result = widget.result;
    final ScreeningRecord? record = widget.record;
    final List<MeasuredPoint> points = parseKeypoints(result['keypoints']);
    final String disclaimer = result['disclaimer']?.toString() ??
        'Hasil ini screening awal, bukan diagnosis. Hanya pemeriksaan dokter yang bisa memastikan skoliosis.';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleIconButton(
                  icon: Icons.arrow_back,
                  label: 'Kembali',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    'Hasil screening',
                    textAlign: TextAlign.center,
                    style: ts(16, weight: FontWeight.w800, height: 22),
                  ),
                ),
                if (record != null)
                  CircleIconButton(
                    icon: Icons.delete_outline,
                    label: 'Hapus dari riwayat',
                    onTap: _delete,
                  )
                else
                  const SizedBox(width: 48, height: 48),
              ],
            ),
            if (record != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                formatDate(record.date),
                textAlign: TextAlign.center,
                style: ts(13, color: AppColors.muted, height: 18),
              ),
            ],
            const SizedBox(height: 16),
            _buildPhoto(points),
            if (points.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Tampilkan titik pengukuran',
                      style: ts(14, weight: FontWeight.w700, height: 20),
                    ),
                  ),
                  Switch(
                    value: _showOverlay,
                    onChanged: (bool value) {
                      setState(() {
                        _showOverlay = value;
                      });
                    },
                  ),
                ],
              ),
              if (_showOverlay) _buildLegend(),
            ],
            const SizedBox(height: 16),
            _buildRiskCard(result),
            if (_needsReferral) ...<Widget>[
              const SizedBox(height: 12),
              ReferralCard(onPressed: _openReferral),
            ],
            ..._buildNotes(result),
            ..._buildMeasurements(result),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lineSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.info_outline, size: 20, color: AppColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(disclaimer, style: ts(13, color: AppColors.inkSoft, height: 19)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (record == null) ...<Widget>[
              FilledButton(
                onPressed: (_saved || _saving) ? null : _save,
                style: primaryButtonStyle(),
                child: Text(_saved ? 'Tersimpan di riwayat' : 'Simpan ke riwayat'),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: _retake,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.teal),
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
                textStyle: ts(14, weight: FontWeight.w700),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(record == null ? 'Foto ulang' : 'Screening baru'),
            ),
          ],
        ),
      ),
    );
  }

  // Foto ditampilkan utuh (tidak dipotong) supaya posisi titik dari server,
  // yang berupa pecahan 0-1 dari lebar dan tinggi foto, jatuh tepat di tempatnya.
  Widget _buildPhoto(List<MeasuredPoint> points) {
    final dynamic overlay = widget.result['overlay'];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 460),
      child: Center(
        heightFactor: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: <Widget>[
              Image.file(
                widget.image,
                fit: BoxFit.contain,
                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                  return Container(
                    height: 200,
                    color: AppColors.lineSoft,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Foto tidak tersedia lagi di HP ini.',
                      textAlign: TextAlign.center,
                      style: ts(14, color: AppColors.muted, height: 20),
                    ),
                  );
                },
              ),
              if (_showOverlay && points.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(
                    painter: MeasurementPainter(
                      points: points,
                      pairs: overlay is Map
                          ? parsePairs(overlay['pairs'], points.length)
                          : const <List<int>>[],
                      axis: overlay is Map ? parseAxis(overlay['axis']) : const <Offset>[],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Widget marker, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        marker,
        const SizedBox(width: 6),
        Text(text, style: ts(12, color: AppColors.muted, height: 18)),
      ],
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink),
      ),
    );
  }

  Widget _legendBar(Color color) {
    return Container(
      width: 18,
      height: 4,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: <Widget>[
        _legendItem(_legendDot(const Color(0xFF00C766)), 'Titik tubuh'),
        _legendItem(_legendDot(MeasurementPainter.weakColor), 'Titik kurang yakin'),
        _legendItem(_legendBar(const Color(0xFFE08A00)), 'Garis kiri-kanan'),
        _legendItem(_legendBar(const Color(0xFF00A9C2)), 'Sumbu tubuh'),
        _legendItem(_legendBar(AppColors.muted), 'Garis tegak acuan (putus-putus)'),
      ],
    );
  }

  Widget _buildRiskCard(Map<String, dynamic> result) {
    final String? level = result['risk_level']?.toString();
    final dynamic rawScore = result['risk_score'];
    final double? score = rawScore is num ? rawScore.toDouble() : null;

    return AppCard(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Tingkat risiko', style: ts(13, color: AppColors.muted, height: 18)),
                    const SizedBox(height: 2),
                    Text(
                      level ?? '-',
                      style: ts(32, weight: FontWeight.w800, color: riskColor(level), height: 38),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('Skor risiko', style: ts(13, color: AppColors.muted, height: 18)),
                  const SizedBox(height: 2),
                  Text(formatPercent(score), style: ts(32, weight: FontWeight.w800, height: 38)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          RiskScale(score: score),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: riskTint(level),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(riskSummary(level), style: ts(14, height: 21)),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Hasil model', style: ts(13, color: AppColors.muted, height: 18)),
              ),
              Text(
                result['label']?.toString() ?? '-',
                style: ts(13, weight: FontWeight.w700, height: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Keyakinan model', style: ts(13, color: AppColors.muted, height: 18)),
              ),
              Text(
                formatPercent(result['confidence']),
                style: ts(13, weight: FontWeight.w700, height: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNotes(Map<String, dynamic> result) {
    final List<String> notes = <String>[];
    if (result['needs_review'] == true) {
      notes.add('Keyakinan model rendah. Sebaiknya ulangi dengan foto yang lebih jelas.');
    }
    if (result['background_removed'] == false) {
      notes.add(
        'Latar belakang foto tidak berhasil dihapus, jadi hasil bisa kurang akurat. '
        'Coba foto dengan latar polos dan seluruh punggung terlihat.',
      );
    }
    final List<Widget> widgets = <Widget>[];
    for (final String note in notes) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.amberTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            note,
            style: ts(13, weight: FontWeight.w600, color: AppColors.amber, height: 19),
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildMeasurements(Map<String, dynamic> result) {
    final dynamic raw = result['posture_features'];
    final List<FeatureInfo> items = <FeatureInfo>[];
    if (raw is Map) {
      raw.forEach((dynamic key, dynamic value) {
        items.add(describeFeature(key.toString(), value));
      });
    }
    if (items.isEmpty) return <Widget>[];

    return <Widget>[
      const SizedBox(height: 20),
      const SectionTitle('Yang terukur'),
      const SizedBox(height: 10),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < items.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: i == items.length - 1
                      ? null
                      : const Border(bottom: BorderSide(color: AppColors.lineSoft)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            items[i].title,
                            style: ts(14, weight: FontWeight.w700, height: 20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].description,
                            style: ts(13, color: AppColors.muted, height: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(items[i].value, style: ts(18, weight: FontWeight.w800, height: 24)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }
}