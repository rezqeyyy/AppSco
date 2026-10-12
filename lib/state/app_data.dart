import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/screening_record.dart';

class AppData extends ChangeNotifier {
  static const String _keyName = 'nama';
  static const String _keyHistory = 'riwayat_v1';
  static const String _keyOnboarding = 'tutorial_selesai';

  bool loaded = false;
  String name = '';
  bool onboardingDone = false; // tutorial sudah pernah diselesaikan atau dilewati
  List<ScreeningRecord> records = <ScreeningRecord>[]; // terbaru di depan

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      name = prefs.getString(_keyName) ?? '';
      onboardingDone = prefs.getBool(_keyOnboarding) ?? false;
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