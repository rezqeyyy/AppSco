import '../../../core/utils/formatters.dart';
import '../../../data/models/feature_info.dart';

/// Mengubah nama fitur dari server (misalnya "tilt_shoulder_deg") menjadi
/// judul, penjelasan, dan nilai yang mudah dibaca.
/// Tanda nilai mengikuti notebook: kemiringan positif = sisi kanan foto lebih rendah,
/// condong positif = ke kanan foto.
FeatureInfo describeFeature(String key, dynamic raw) {
  final double? v = raw is num ? raw.toDouble() : null;
  final String degrees = v == null ? '-' : '${formatNumber(v.abs(), 1)}°';
  final String percent = v == null ? '-' : '${formatNumber(v * 100, 1)}%';

  if (key == 'tilt_diff_top_bottom_deg') {
    return FeatureInfo(
      'Selisih kemiringan atas dan bawah',
      'Beda kemiringan garis kiri-kanan teratas dan terbawah',
      degrees,
    );
  }
  if (key.startsWith('tilt_') && key.endsWith('_deg') && key.length > 9) {
    final String name = key.substring(5, key.length - 4).replaceAll('_', ' ');
    String description = 'Hampir sejajar';
    if (v != null && v.abs() >= 0.5) {
      description = v > 0 ? 'Sisi kanan foto lebih rendah' : 'Sisi kiri foto lebih rendah';
    }
    return FeatureInfo('Kemiringan $name', description, degrees);
  }
  if (key == 'trunk_lean_deg') {
    String description = 'Hampir tegak';
    if (v != null && v.abs() >= 0.5) {
      description =
          v > 0 ? 'Sumbu tubuh condong ke kanan foto' : 'Sumbu tubuh condong ke kiri foto';
    }
    return FeatureInfo('Kemiringan sumbu tubuh', description, degrees);
  }
  if (key == 'curve_angle_deg') {
    return FeatureInfo(
      'Sudut lengkung sumbu tubuh',
      'Beda arah terbesar antarbagian sumbu tubuh',
      degrees,
    );
  }
  if (key == 'lateral_dev_max_abs') {
    return FeatureInfo(
      'Simpangan samping terbesar',
      'Jarak terjauh sumbu tubuh dari garis lurus, dibanding panjang sumbu',
      percent,
    );
  }
  if (key == 'lateral_dev_range') {
    return FeatureInfo(
      'Rentang simpangan samping',
      'Besar kalau sumbu tubuh melengkung ke dua arah',
      percent,
    );
  }
  return FeatureInfo(
    key.replaceAll('_', ' '),
    'Nilai dari model',
    v == null ? raw.toString() : formatNumber(v, 2),
  );
}