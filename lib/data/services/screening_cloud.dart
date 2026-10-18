import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/screening_record.dart';
import 'auth_service.dart';

/// Satu baris riwayat dari database akun.
class CloudScreening {
  const CloudScreening({
    required this.clientId,
    required this.date,
    required this.result,
    this.photoPath,
  });

  final String clientId;
  final DateTime date;
  final Map<String, dynamic> result;
  final String? photoPath; // lokasi foto di Supabase Storage
}

/// Riwayat screening di Supabase: tabel `screenings` + foto di bucket `screening-photos`.
/// Semua fungsi melempar error kalau gagal; pemanggil yang memutuskan (biasanya dicoba lagi nanti).
class ScreeningCloud {
  ScreeningCloud._();

  static const String bucket = 'screening-photos';
  static const Duration _timeout = Duration(seconds: 30);

  static SupabaseClient get _db => AuthService.instance.client;

  static String photoPathFor(String userId, String clientId) => '$userId/$clientId.jpg';

  /// Unggah foto (kalau ada) lalu simpan/perbarui barisnya. Aman diulang (upsert).
  static Future<void> upsert(String userId, ScreeningRecord record) async {
    String? photoPath;
    final File photo = File(record.imagePath);
    if (record.imagePath.isNotEmpty && await photo.exists()) {
      photoPath = photoPathFor(userId, record.id);
      await _db.storage
          .from(bucket)
          .upload(photoPath, photo, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'))
          .timeout(_timeout);
    }
    final dynamic score = record.result['risk_score'];
    final dynamic confidence = record.result['confidence'];
    await _db.from('screenings').upsert(<String, dynamic>{
      'user_id': userId,
      'client_id': record.id,
      'screened_at': record.date.toUtc().toIso8601String(),
      'risk_score': score is num ? score.toDouble() : null,
      'risk_level': record.result['risk_level']?.toString(),
      'label': record.result['label']?.toString(),
      'confidence': confidence is num ? confidence.toDouble() : null,
      'result': record.result,
      'photo_path': photoPath,
    }, onConflict: 'user_id,client_id').timeout(_timeout);
  }

  /// Riwayat milik akun, terbaru di depan.
  static Future<List<CloudScreening>> fetchAll(String userId) async {
    final List<Map<String, dynamic>> rows = await _db
        .from('screenings')
        .select('client_id, screened_at, result, photo_path')
        .eq('user_id', userId)
        .order('screened_at', ascending: false)
        .limit(300)
        .timeout(_timeout);
    final List<CloudScreening> out = <CloudScreening>[];
    for (final Map<String, dynamic> row in rows) {
      final DateTime? date = DateTime.tryParse(row['screened_at']?.toString() ?? '');
      final dynamic result = row['result'];
      if (date == null || result is! Map) continue;
      final String clientId = row['client_id']?.toString() ?? '';
      out.add(CloudScreening(
        // Baris lama (sebelum ada client_id) diberi id dari waktunya.
        clientId: clientId.isNotEmpty ? clientId : 'cloud_${date.millisecondsSinceEpoch}',
        date: date.toLocal(),
        result: result.map((dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v)),
        photoPath: row['photo_path']?.toString(),
      ));
    }
    return out;
  }

  static Future<Uint8List> downloadPhoto(String photoPath) {
    return _db.storage.from(bucket).download(photoPath).timeout(_timeout);
  }

  static Future<void> delete(String userId, String clientId) async {
    await _db.from('screenings').delete().eq('user_id', userId).eq('client_id', clientId).timeout(_timeout);
    try {
      await _db.storage.from(bucket).remove(<String>[photoPathFor(userId, clientId)]).timeout(_timeout);
    } catch (_) {
      // Foto memang tidak ada: abaikan.
    }
  }

  static Future<void> deleteAll(String userId) async {
    await _db.from('screenings').delete().eq('user_id', userId).timeout(_timeout);
    try {
      final List<FileObject> files = await _db.storage.from(bucket).list(path: userId).timeout(_timeout);
      if (files.isNotEmpty) {
        await _db.storage
            .from(bucket)
            .remove(files.map((FileObject f) => '$userId/${f.name}').toList())
            .timeout(_timeout);
      }
    } catch (_) {
      // Foto gagal dihapus: barisnya sudah terhapus, jadi tidak tampil lagi.
    }
  }
}