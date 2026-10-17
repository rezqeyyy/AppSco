import 'package:flutter/material.dart' hide Text;
import '../../../core/i18n/tr_text.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'silhouette_guide_painter.dart';

/// Lembar panduan yang muncul setiap kali halaman kamera dibuka.
/// [onReadMore] membuka artikel panduan lengkap.
Future<void> showPhotoGuideSheet(BuildContext context, {VoidCallback? onReadMore}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext sheetContext) => _PhotoGuideSheet(onReadMore: onReadMore),
  );
}

class _PhotoGuideSheet extends StatelessWidget {
  const _PhotoGuideSheet({this.onReadMore});

  final VoidCallback? onReadMore;

  static const List<(IconData, String, String)> _tips = <(IconData, String, String)>[
    (
      Icons.accessibility_new,
      'Leher sampai pinggul saja',
      'Kepala tidak perlu masuk. Bahu menyentuh garis "Bahu", pinggul di garis "Pinggul".',
    ),
    (
      Icons.checkroom_outlined,
      'Punggung terlihat jelas',
      'Tanpa baju atau pakai kaos tipis yang ketat. Rambut panjang diikat ke atas.',
    ),
    (
      Icons.straighten,
      'Berdiri tegak, rileks',
      'Kaki sejajar selebar pinggul, tangan lurus di samping badan, pandangan ke depan.',
    ),
    (
      Icons.photo_camera_back_outlined,
      'Difoto orang lain dari belakang',
      'Jarak sekitar 1 meter. HP tegak, setinggi tengah punggung, tidak miring.',
    ),
    (
      Icons.wb_sunny_outlined,
      'Latar polos dan terang',
      'Berdiri di depan dinding polos. Flash menyala otomatis saat memotret.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Sebelum memotret', style: ts(20, weight: FontWeight.w800, height: 26)),
          const SizedBox(height: 4),
          Text(
            'Foto yang sesuai panduan membuat hasil screening lebih akurat.',
            style: ts(14, color: AppColors.muted, height: 20),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Contoh bingkai: hanya badan, tanpa kepala.
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 96,
                  height: 128,
                  color: AppColors.darkSurface,
                  child: const CustomPaint(
                    painter: SilhouetteGuidePainter(showLabels: false, compact: true),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Isi bingkai', style: ts(14, weight: FontWeight.w700, height: 20)),
                    const SizedBox(height: 4),
                    Text(
                      'Badan dari pangkal leher sampai pinggul memenuhi bingkai. '
                      'Tulang belakang lurus di garis tengah putus-putus.',
                      style: ts(13, color: AppColors.inkSoft, height: 19),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final (IconData, String, String) tip in _tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.tealTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(tip.$1, size: 20, color: AppColors.teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(tip.$2, style: ts(14, weight: FontWeight.w700, height: 20)),
                        const SizedBox(height: 2),
                        Text(tip.$3, style: ts(13, color: AppColors.muted, height: 18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
              textStyle: ts(15, weight: FontWeight.w700),
            ),
            child: const Text('Mengerti, mulai foto'),
          ),
          if (onReadMore != null) ...<Widget>[
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onReadMore!();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.teal,
                textStyle: ts(14, weight: FontWeight.w700),
              ),
              child: const Text('Baca panduan lengkap'),
            ),
          ],
        ],
      ),
    );
  }
}