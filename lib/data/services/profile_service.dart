import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/personal_data.dart';
import 'auth_service.dart';

class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  final String message;
}

/// Data diri di tabel `profiles` Supabase (satu baris per pengguna).
class ProfileService {
  ProfileService._();

  static const String _table = 'profiles';

  static Future<PersonalData?> fetch(String userId) async {
    final Map<String, dynamic>? row = await AuthService.instance.client
        .from(_table)
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    final DateTime? birth = DateTime.tryParse(row['birth_date']?.toString() ?? '');
    final dynamic name = row['full_name'];
    final dynamic gender = row['gender'];
    if (birth == null || name is! String || gender is! String) return null;
    return PersonalData(
      fullName: name,
      birthDate: birth,
      gender: gender,
      phone: row['phone']?.toString() ?? '',
    );
  }

  static Future<void> save(String userId, PersonalData data) async {
    try {
      await AuthService.instance.client.from(_table).upsert(<String, dynamic>{
        'id': userId,
        'full_name': data.fullName,
        'birth_date': data.birthDate.toIso8601String().substring(0, 10),
        'gender': data.gender,
        'phone': data.phone,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw ProfileFailure('Data diri gagal disimpan ke server: ${e.message}');
    } on AuthFailure catch (e) {
      throw ProfileFailure(e.message);
    } catch (_) {
      throw const ProfileFailure('Data diri gagal disimpan. Periksa koneksi internet lalu coba lagi.');
    }
  }
}