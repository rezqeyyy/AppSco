import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' hide Text;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/personal_data.dart';
import '../data/models/screening_record.dart';
import '../data/models/user_account.dart';
import '../data/services/auth_service.dart';
import '../data/services/profile_service.dart';
import '../data/services/screening_cloud.dart';

class AppData extends ChangeNotifier {
  static const String _keyName = 'nama';
  static const String _keyHistory = 'riwayat_v1';
  static const String _keyOnboarding = 'tutorial_selesai';
  static const String _keyAuthMode = 'mode_masuk';
  static const String _keyPersonal = 'data_diri'; // salinan data diri di HP

  bool loaded = false;
  String name = '';
  bool onboardingDone = false; // tutorial sudah pernah diselesaikan atau dilewati
  List<ScreeningRecord> records = <ScreeningRecord>[]; // terbaru di depan

  // null = belum pernah memilih di layar login, 'user' (sudah login) atau 'guest'
  String? authMode;
  UserAccount? account; // akun Supabase yang sedang masuk
  PersonalData? personal;

  bool get isSignedIn => account != null;

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      name = prefs.getString(_keyName) ?? '';
      onboardingDone = prefs.getBool(_keyOnboarding) ?? false;
      authMode = prefs.getString(_keyAuthMode);
      try {
        await AuthService.instance.init();
      } catch (_) {
        // Supabase gagal disiapkan: aplikasi tetap jalan sebagai tamu.
      }
      account = AuthService.instance.currentAccount();
      if (account != null) {
        authMode = 'user';
        personal = PersonalData.fromJson(_decode(prefs.getString(_keyPersonal)));
      } else if (authMode == 'user') {
        authMode = 'guest'; // sesi sudah habis
      }
      final String? raw = prefs.getString(_keyHistory);
      if (raw != null) {
        final dynamic decoded = json.decode(raw);
        if (decoded is List) {
          final List<ScreeningRecord> list = <ScreeningRecord>[];
          for (final dynamic item in decoded) {
            final ScreeningRecord? record = ScreeningRecord.fromJson(item);
            if (record != null) list.add(record);
          }
          list.sort((ScreeningRecord a, ScreeningRecord b) => b.date.compareTo(a.date));
          records = list;
        }
      }
    } catch (_) {
      // Data lama rusak atau penyimpanan tidak tersedia: mulai dari kosong.
    }
    loaded = true;
    notifyListeners();
  }

  static dynamic _decode(String? raw) {
    if (raw == null) return null;
    try {
      return json.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveString(String key, String? value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    } catch (_) {
      // Gagal menyimpan: data tetap dipakai sampai aplikasi ditutup.
    }
  }

  Future<void> continueAsGuest() async {
    authMode = 'guest';
    notifyListeners();
    await _saveString(_keyAuthMode, 'guest');
  }

  /// Dipanggil setelah login/daftar berhasil. Data diri diambil dari server.
  Future<void> onSignedIn(UserAccount value) async {
    authMode = 'user';
    account = value;
    personal = null;
    if (name.isEmpty && value.name.isNotEmpty) {
      await setName(value.name.split(' ').first);
    }
    notifyListeners();
    await _saveString(_keyAuthMode, 'user');
    await _saveString(_keyPersonal, null);
    await refreshPersonalData();
  }

  /// Ambil data diri terbaru dari Supabase. Kalau offline, pakai salinan di HP.
  Future<void> refreshPersonalData() async {
    final UserAccount? current = account;
    if (current == null) return;
    try {
      final PersonalData? remote = await ProfileService.fetch(current.id);
      if (account?.id != current.id) return; // sudah ganti akun
      personal = remote;
      notifyListeners();
      await _saveString(_keyPersonal, remote == null ? null : json.encode(remote.toJson()));
    } catch (_) {
      // Offline: tetap pakai salinan lokal.
    }
  }

  /// Keluar dari akun. Salinan data diri di HP dihapus; data di server tetap ada.
  Future<void> signOut() async {
    await AuthService.instance.signOut();
    authMode = 'guest';
    account = null;
    personal = null;
    notifyListeners();
    await _saveString(_keyAuthMode, 'guest');
    await _saveString(_keyPersonal, null);
  }

  /// Simpan ke Supabase dulu; kalau gagal, lempar ProfileFailure.
  Future<void> savePersonalData(PersonalData value) async {
    final UserAccount? current = account;
    if (current == null) {
      throw const ProfileFailure('Masuk ke akun dulu untuk menyimpan data diri.');
    }
    await ProfileService.save(current.id, value);
    personal = value;
    notifyListeners();
    await _saveString(_keyPersonal, json.encode(value.toJson()));
  }

  Future<void> _saveHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
      for (final ScreeningRecord record in records) {
        list.add(record.toJson());
      }
      await prefs.setString(_keyHistory, json.encode(list));
    } catch (_) {
      // Gagal menyimpan: riwayat tetap ada sampai aplikasi ditutup.
    }
  }

  Future<void> setName(String value) async {
    name = value;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyName, value);
    } catch (_) {
      // Gagal menyimpan: nama tetap dipakai sampai aplikasi ditutup.
    }
  }

  Future<void> completeOnboarding() async {
    onboardingDone = true;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOnboarding, true);
    } catch (_) {
      // Gagal menyimpan: tutorial muncul lagi saat aplikasi dibuka berikutnya.
    }
  }

  /// Menyalin foto ke folder aplikasi (supaya tidak hilang saat cache dibersihkan)
  /// lalu mencatat hasilnya di riwayat.
  Future<ScreeningRecord> addRecord(File image, Map<String, dynamic> result) async {
    final DateTime now = DateTime.now();
    final String id = now.millisecondsSinceEpoch.toString();
    String path = image.path;
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final int dot = image.path.lastIndexOf('.');
      final String ext =
          (dot >= 0 && image.path.length - dot <= 6) ? image.path.substring(dot) : '.jpg';
      final File copy = await image.copy('${dir.path}/screening_$id$ext');
      path = copy.path;
    } catch (_) {
      // Tidak bisa menyalin: pakai lokasi foto aslinya.
    }
    final ScreeningRecord record =
        ScreeningRecord(id: id, date: now, imagePath: path, result: result);
    records.insert(0, record);
    notifyListeners();
    await _saveHistory();
    final UserAccount? current = account;
    if (current != null) {
      // Ringkasan hasil (tanpa foto) ikut disimpan ke akun.
      await ScreeningCloud.upload(current.id, result, now);
    }
    return record;
  }

  Future<void> _deleteImage(ScreeningRecord record) async {
    try {
      final File file = File(record.imagePath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Foto sudah tidak ada atau tidak bisa dihapus: abaikan.
    }
  }

  Future<void> deleteRecord(ScreeningRecord record) async {
    records.remove(record);
    notifyListeners();
    await _deleteImage(record);
    await _saveHistory();
  }

  Future<void> clearAll() async {
    final List<ScreeningRecord> old = records;
    records = <ScreeningRecord>[];
    notifyListeners();
    for (final ScreeningRecord record in old) {
      await _deleteImage(record);
    }
    await _saveHistory();
  }
}

final AppData appData = AppData();