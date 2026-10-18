import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/measured_point.dart';
import '../widgets/measurement_painter.dart';

/// Penjelasan hasil screening dalam bahasa sehari-hari untuk orang awam.
/// Foto diambil dari belakang, jadi sisi kanan foto = sisi kanan badan orang yang difoto.
///
/// Dua hal yang sering tertukar:
/// - "Condong": seluruh badan bagian atas miring ke satu sisi (garis dari leher ke pinggul tidak tegak).
/// - "Melengkung": bagian tengah tulang belakang menonjol ke satu sisi, walaupun leher dan pinggul
///   sejajar. Arah lengkung = sisi tempat bagian tengahnya menonjol.

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

/// Ukuran bentuk tulang belakang, dihitung di aplikasi dari SEMUA titik garis tengah tubuh
/// (sama dengan garis biru di foto). Ukuran dari server hanya memakai beberapa titik sumbu,
/// jadi bisa terlihat "lurus" padahal garis di foto jelas melengkung.
class SpineMetrics {
  const SpineMetrics({
    required this.maxDeviation,
    required this.bulgeSide,
    required this.deviationRange,
    required this.curveDeg,
    required this.leanDeg,
  });

  final double maxDeviation; // simpangan terjauh dari garis lurus leher-pinggul, pecahan panjang tulang belakang
  final String? bulgeSide; // 'kanan' / 'kiri' (menurut foto) sisi tonjolan terbesar
  final double deviationRange; // simpangan ke kanan + ke kiri (besar kalau bentuk S)
  final double curveDeg; // beda arah terbesar antarbagian tulang belakang
  final double leanDeg; // > 0: pinggul di kanan leher = badan atas miring ke KIRI
}

/// [aspect] = lebar / tinggi foto, supaya sudut dihitung dalam ukuran sebenarnya.
SpineMetrics? spineMetrics(List<MeasuredPoint> points, {double aspect = 0.75}) {
  final List<Offset> raw = MeasurementPainter.spinePath(points);
  if (raw.length < 3) return null;
  final List<Offset> spine = raw.map((Offset p) => Offset(p.dx * aspect, p.dy)).toList();
  final Offset top = spine.first;
  final Offset bottom = spine.last;
  final Offset axis = bottom - top;
  final double length = axis.distance;
  if (length <= 0) return null;

  // Simpangan tegak lurus dari garis leher -> pinggul (positif = ke kanan foto).
  double maxDev = 0;
  double minDev = 0;
  for (final Offset p in spine) {
    final Offset v = p - top;
    final double dev = -(axis.dx * v.dy - axis.dy * v.dx) / length;
    maxDev = math.max(maxDev, dev);
    minDev = math.min(minDev, dev);
  }
  final double biggest = maxDev.abs() >= minDev.abs() ? maxDev : minDev;

  // Sudut tiap bagian, dari titik yang jaraknya minimal 12% panjang tulang belakang (supaya
  // titik yang berdempetan tidak membuat sudut palsu).
  final List<Offset> coarse = <Offset>[top];
  for (final Offset p in spine.skip(1)) {
    if ((p - coarse.last).distance >= length * 0.12) coarse.add(p);
  }
  if (coarse.last != bottom) {
    if (coarse.length > 1 && (bottom - coarse.last).distance < length * 0.06) coarse.removeLast();
    coarse.add(bottom);
  }
  double curve = 0;
  if (coarse.length >= 3) {
    double lo = double.infinity;
    double hi = -double.infinity;
    for (int i = 0; i < coarse.length - 1; i++) {
      final Offset d = coarse[i + 1] - coarse[i];
      final double ang = math.atan2(d.dx, d.dy.abs() + 1e-9) * 180 / math.pi;
      lo = math.min(lo, ang);
      hi = math.max(hi, ang);
    }
    curve = hi - lo;
  }

  return SpineMetrics(
    maxDeviation: biggest.abs() / length,
    bulgeSide: biggest.abs() < 1e-6 ? null : (biggest > 0 ? 'kanan' : 'kiri'),
    deviationRange: (maxDev - minDev) / length,
    curveDeg: curve,
    leanDeg: math.atan2(axis.dx, axis.dy.abs() + 1e-9) * 180 / math.pi,
  );
}

/// Temuan dari ukuran postur, dalam bahasa sehari-hari.
/// Batas angka di sini hanya untuk memilih kata, bukan batas medis.
/// [metrics] dari [spineMetrics] (garis di foto) dipakai kalau ada; kalau tidak, ukuran dari server.
List<PlainFinding> postureFindings(dynamic raw, {SpineMetrics? metrics}) {
  if (raw is! Map && metrics == null) return const <PlainFinding>[];
  final Map<dynamic, dynamic> f = raw is Map ? raw : const <dynamic, dynamic>{};
  final List<PlainFinding> out = <PlainFinding>[];

  // 1. Bentuk tulang belakang: dari simpangan ke samping dan sudut lengkung.
  final double? dev = metrics?.maxDeviation ?? _num(f, 'lateral_dev_max_abs');
  final double? curve = metrics?.curveDeg ?? _num(f, 'curve_angle_deg');
  if (dev != null || curve != null) {
    final double d = (dev ?? 0) * 100; // persen panjang tulang belakang
    final double c = curve ?? 0;
    final String? bulgeSide = metrics?.bulgeSide;
    final String toSide = bulgeSide == null ? '' : ' ke $bulgeSide';
    final String sideNote = bulgeSide == null
        ? ''
        : ' Bagian tengahnya menonjol ke sisi $bulgeSide (sisi $bulgeSide foto = sisi $bulgeSide badan).';
    if (d >= 6 || c >= 20) {
      out.add(PlainFinding(
        'Bentuk tulang belakang',
        FindingStatus.alert,
        'Melengkung jelas$toSide',
        'Garis tulang belakang di foto tampak melengkung ke samping, tidak lurus dari leher ke pinggang.$sideNote',
      ));
    } else if (d >= 3 || c >= 10) {
      out.add(PlainFinding(
        'Bentuk tulang belakang',
        FindingStatus.watch,
        'Sedikit melengkung$toSide',
        'Garis tulang belakang sedikit menyimpang dari garis lurus. Bisa karena posisi berdiri, bisa juga tanda awal.$sideNote',
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
  final double? lean = metrics?.leanDeg ?? _num(f, 'trunk_lean_deg');
  if (lean != null) {
    // trunk_lean_deg > 0: pinggul berada di kanan leher, artinya badan atas miring ke KIRI.
    final String side = lean > 0 ? 'kiri' : 'kanan';
    if (lean.abs() >= 5) {
      out.add(PlainFinding(
        'Posisi badan',
        FindingStatus.watch,
        'Badan atas condong ke $side',
        'Dari pinggul ke leher, badan tampak miring ke sisi $side (sisi $side foto = sisi $side badan). '
            'Pastikan berdiri tegak saat difoto; kalau tetap miring, perlu diperhatikan.',
      ));
    } else if (lean.abs() >= 2) {
      out.add(PlainFinding(
        'Posisi badan',
        FindingStatus.ok,
        'Sedikit condong ke $side',
        'Badan atas sedikit miring ke sisi $side. Ini masih sering terjadi karena posisi berdiri.',
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
  f.forEach((dynamic k, dynamic v) {
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