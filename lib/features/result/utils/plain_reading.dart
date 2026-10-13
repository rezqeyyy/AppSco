import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Penjelasan hasil screening dalam bahasa sehari-hari untuk orang awam.
/// Foto diambil dari belakang, jadi sisi kanan foto = sisi kanan badan.

enum FindingStatus { ok, watch, alert }

class PlainFinding {
  const PlainFinding(this.title, this.status, this.statusLabel, this.explanation);

  final String title; // apa yang dilihat, misalnya "Bentuk tulang belakang"
  final FindingStatus status;
  final String statusLabel; // misalnya "Tampak lurus"
  final String explanation; // satu kalimat penjelasan
}

Color findingColor(FindingStatus s) => switch (s) {
      FindingStatus.ok => AppColors.teal,
      FindingStatus.watch => AppColors.amber,
      FindingStatus.alert => AppColors.red,
    };

Color findingTint(FindingStatus s) => switch (s) {
      FindingStatus.ok => AppColors.tealTint,
      FindingStatus.watch => AppColors.amberTint,
      FindingStatus.alert => AppColors.redTint,
    };

IconData findingIcon(FindingStatus s) => switch (s) {
      FindingStatus.ok => Icons.check_circle_outline,
      FindingStatus.watch => Icons.error_outline,
      FindingStatus.alert => Icons.warning_amber_rounded,
    };

/// Kalimat utama hasil, sesuai tingkat risiko.
String riskHeadline(String? level) => switch (level) {
      'Rendah' => 'Tidak terlihat tanda skoliosis yang jelas',
      'Sedang' => 'Ada beberapa tanda yang perlu diperhatikan',
      'Tinggi' => 'Terlihat tanda skoliosis yang cukup jelas',
      _ => 'Hasil belum bisa disimpulkan',
    };

/// Arti angka skor, dengan bahasa sederhana.
String scoreMeaning(double? score) {
  if (score == null) return 'Skor tidak tersedia untuk foto ini.';
  final int n = (score * 100).round();
  return 'Skor $n dari 100. Makin besar angkanya, makin besar kemungkinan tulang belakang '
      'melengkung ke samping. Ini perkiraan dari foto, bukan diagnosis.';
}

/// Saran langkah berikutnya, sesuai tingkat risiko.
List<String> riskActions(String? level) => switch (level) {
      'Rendah' => <String>[
          'Belum perlu ke dokter karena hasil ini.',
          'Ulangi screening 3–6 bulan lagi, terutama pada anak dan remaja yang sedang tumbuh.',
          'Tetap periksa ke dokter kalau ada nyeri punggung atau bahu terlihat tidak sama tinggi.',
        ],
      'Sedang' => <String>[
          'Foto ulang dengan posisi tegak dan punggung terlihat jelas untuk memastikan.',
          'Kalau hasilnya tetap sedang atau tinggi, periksakan ke dokter.',
          'Perhatikan apakah bahu, tulang belikat, atau pinggang terlihat tidak sama.',
        ],
      'Tinggi' => <String>[
          'Periksakan ke dokter, sebaiknya dokter spesialis ortopedi (Sp.OT).',
          'Bawa atau tunjukkan hasil ini saat periksa.',
          'Jangan panik: banyak kasus ringan cukup dipantau, dan hanya pemeriksaan dokter yang bisa memastikan.',
        ],
      _ => <String>['Coba foto ulang sesuai panduan.'],
    };

/// Seberapa bisa dipercaya hasil ini, dari keyakinan model dan kualitas foto.
PlainFinding photoReliability(Map<String, dynamic> result) {
  final dynamic conf = result['confidence'];
  final bool review = result['needs_review'] == true;
  final bool bgFailed = result['background_removed'] == false;
  if (review || (conf is num && conf < 0.6)) {
    return const PlainFinding(
      'Ketepatan hasil',
      FindingStatus.watch,
      'Kurang yakin',
      'Sistem kurang yakin dengan foto ini. Sebaiknya foto ulang dengan posisi tegak, punggung '
          'terlihat jelas, dan latar polos.',
    );
  }
  if (bgFailed) {
    return const PlainFinding(
      'Ketepatan hasil',
      FindingStatus.watch,
      'Cukup',
      'Latar belakang foto tidak berhasil dipisahkan, jadi hasil bisa kurang tepat. Coba foto di depan dinding polos.',
    );
  }
  return const PlainFinding(
    'Ketepatan hasil',
    FindingStatus.ok,
    'Baik',
    'Foto cukup jelas untuk dianalisis.',
  );
}

double? _num(Map<dynamic, dynamic> f, String key) {
  final dynamic v = f[key];
  return v is num ? v.toDouble() : null;
}

/// Temuan dari ukuran postur, dalam bahasa sehari-hari.
/// Batas angka di sini hanya untuk memilih kata, bukan batas medis.
List<PlainFinding> postureFindings(dynamic raw) {
  if (raw is! Map) return const <PlainFinding>[];
  final List<PlainFinding> out = <PlainFinding>[];

  // 1. Bentuk tulang belakang: dari simpangan ke samping dan sudut lengkung.
  final double? dev = _num(raw, 'lateral_dev_max_abs');
  final double? curve = _num(raw, 'curve_angle_deg');
  if (dev != null || curve != null) {
    final double d = (dev ?? 0) * 100; // persen panjang tulang belakang
    final double c = curve ?? 0;
    if (d >= 6 || c >= 20) {
      out.add(const PlainFinding(
        'Bentuk tulang belakang',
        FindingStatus.alert,
        'Melengkung jelas',
        'Garis tulang belakang di foto tampak melengkung ke samping, tidak lurus dari leher ke pinggang.',
      ));
    } else if (d >= 3 || c >= 10) {
      out.add(const PlainFinding(
        'Bentuk tulang belakang',
        FindingStatus.watch,
        'Sedikit melengkung',
        'Garis tulang belakang sedikit menyimpang dari garis lurus. Bisa karena posisi berdiri, bisa juga tanda awal.',
      ));
    } else {
      out.add(const PlainFinding(
        'Bentuk tulang belakang',
        FindingStatus.ok,
        'Tampak lurus',
        'Garis tulang belakang di foto tampak lurus dari atas ke bawah.',
      ));
    }
  }

  // 2. Badan condong ke samping.
  final double? lean = _num(raw, 'trunk_lean_deg');
  if (lean != null) {
    final String side = lean > 0 ? 'kanan' : 'kiri';
    if (lean.abs() >= 5) {
      out.add(PlainFinding(
        'Posisi badan',
        FindingStatus.watch,
        'Condong ke $side',
        'Badan tampak condong ke sisi $side. Pastikan berdiri tegak saat difoto; kalau tetap condong, perlu diperhatikan.',
      ));
    } else if (lean.abs() >= 2) {
      out.add(PlainFinding(
        'Posisi badan',
        FindingStatus.ok,
        'Sedikit condong ke $side',
        'Badan sedikit condong ke sisi $side. Ini masih sering terjadi karena posisi berdiri.',
      ));
    } else {
      out.add(const PlainFinding(
        'Posisi badan',
        FindingStatus.ok,
        'Tegak',
        'Badan tampak tegak, tidak condong ke samping.',
      ));
    }
  }

  // 3. Kemiringan garis kiri-kanan (misalnya bahu atau pinggul), kalau model mengukurnya.
  raw.forEach((dynamic k, dynamic v) {
    final String key = k.toString();
    if (!key.startsWith('tilt_') || !key.endsWith('_deg') || key == 'tilt_diff_top_bottom_deg') return;
    if (v is! num) return;
    final String name = key.substring(5, key.length - 4).replaceAll('_', ' ');
    final double t = v.toDouble();
    final String lower = t > 0 ? 'kanan' : 'kiri';
    if (t.abs() >= 3) {
      out.add(PlainFinding(
        'Kesejajaran $name',
        FindingStatus.watch,
        'Sisi $lower lebih rendah',
        '$name kiri dan kanan tidak sama tinggi; sisi $lower tampak lebih rendah.',
      ));
    } else {
      out.add(PlainFinding(
        'Kesejajaran $name',
        FindingStatus.ok,
        'Sejajar',
        '$name kiri dan kanan tampak hampir sama tinggi.',
      ));
    }
  });
  return out;
}