import 'auth_service.dart';

/// Menyimpan ringkasan hasil screening ke tabel `screenings` Supabase.
/// Foto tidak diunggah; foto tetap hanya ada di HP.
class ScreeningCloud {
  ScreeningCloud._();

  /// Gagal pun tidak apa-apa: riwayat tetap tersimpan di HP.
  static Future<void> upload(String userId, Map<String, dynamic> result, DateTime date) async {
    try {
      final dynamic score = result['risk_score'];
      final dynamic confidence = result['confidence'];
      await AuthService.instance.client.from('screenings').insert(<String, dynamic>{
        'user_id': userId,
        'screened_at': date.toUtc().toIso8601String(),
        'risk_score': score is num ? score.toDouble() : null,
        'risk_level': result['risk_level']?.toString(),
        'label': result['label']?.toString(),
        'confidence': confidence is num ? confidence.toDouble() : null,
        'result': result,
      });
    } catch (_) {
      // Offline atau server bermasalah: lewati.
    }
  }
}