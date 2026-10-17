import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'languages.dart';

class LanguageFailure implements Exception {
  const LanguageFailure(this.message);

  final String message;
}

/// Bahasa tampilan aplikasi.
/// Semua teks ditulis dalam Bahasa Indonesia, lalu diterjemahkan otomatis di HP
/// (Google ML Kit, tanpa internet setelah paket bahasanya terunduh).
/// Hasil terjemahan disimpan, jadi tiap kalimat cukup diterjemahkan sekali.
class AppLanguage extends ChangeNotifier {
  static const String _keyCode = 'bahasa';
  static const String _keyCachePrefix = 'terjemahan_';

  String code = sourceLanguageCode;
  bool downloading = false; // sedang mengunduh paket bahasa

  SharedPreferences? _prefs;
  Map<String, String> _cache = <String, String>{};
  final Set<String> _pending = <String>{};
  final Set<String> _failed = <String>{};
  OnDeviceTranslator? _translator;
  bool _ready = false; // paket bahasa sudah ada dan penerjemah siap
  bool _flushing = false;
  Timer? _flushTimer;
  Timer? _saveTimer;

  bool get isSource => code == sourceLanguageCode;
  LanguageOption get current => languageByCode(code);

  /// Dipanggil sekali saat aplikasi dibuka.
  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final String saved = _prefs!.getString(_keyCode) ?? sourceLanguageCode;
      if (saved == sourceLanguageCode) return;
      code = saved;
      _cache = _readCache(saved);
      notifyListeners(); // teks yang sudah pernah diterjemahkan langsung tampil
      // Paket bahasa biasanya sudah ada; kalau terhapus, coba unduh lagi diam-diam.
      try {
        await _prepare(saved);
      } catch (_) {
        // Tidak ada internet: pakai terjemahan yang tersimpan saja dulu.
      }
    } catch (_) {
      code = sourceLanguageCode;
    }
  }

  /// Ganti bahasa. Paket bahasa (sekitar 30 MB) diunduh kalau belum ada.
  /// Kalau gagal, bahasa sebelumnya tetap dipakai.
  Future<void> setLanguage(String newCode) async {
    if (newCode == code && (_ready || isSource)) return;
    if (newCode == sourceLanguageCode) {
      await _switchTo(newCode);
      return;
    }
    downloading = true;
    notifyListeners();
    try {
      await _prepare(newCode);
    } on LanguageFailure {
      rethrow;
    } catch (e) {
      throw LanguageFailure('Paket bahasa gagal disiapkan: $e');
    } finally {
      downloading = false;
      notifyListeners();
    }
    await _switchTo(newCode);
  }

  Future<void> _switchTo(String newCode) async {
    if (newCode != code) {
      _pending.clear();
      _failed.clear();
      code = newCode;
      _cache = newCode == sourceLanguageCode ? <String, String>{} : _readCache(newCode);
      if (newCode == sourceLanguageCode) {
        await _closeTranslator();
      }
    }
    try {
      await (_prefs ??= await SharedPreferences.getInstance()).setString(_keyCode, newCode);
    } catch (_) {
      // Tidak tersimpan: bahasa kembali ke Indonesia saat aplikasi dibuka lagi.
    }
    notifyListeners();
  }

  /// Unduh paket bahasa sumber dan tujuan, lalu siapkan penerjemah.
  Future<void> _prepare(String target) async {
    final TranslateLanguage? targetLang = _toMlKit(target);
    final TranslateLanguage? sourceLang = _toMlKit(sourceLanguageCode);
    if (targetLang == null || sourceLang == null) {
      throw const LanguageFailure('Bahasa ini belum didukung.');
    }
    final OnDeviceTranslatorModelManager models = OnDeviceTranslatorModelManager();
    for (final String bcp in <String>{sourceLanguageCode, target}) {
      bool have = false;
      try {
        have = await models.isModelDownloaded(bcp);
      } catch (_) {
        have = false;
      }
      if (have) continue;
      final bool ok = await models.downloadModel(bcp, isWifiRequired: false);
      if (!ok) {
        throw const LanguageFailure(
          'Paket bahasa gagal diunduh. Pastikan ada koneksi internet lalu coba lagi.',
        );
      }
    }
    await _closeTranslator();
    _translator = OnDeviceTranslator(sourceLanguage: sourceLang, targetLanguage: targetLang);
    _ready = true;
    if (target == code) _scheduleFlush();
  }

  Future<void> _closeTranslator() async {
    final OnDeviceTranslator? old = _translator;
    _translator = null;
    _ready = false;
    if (old != null) {
      try {
        await old.close();
      } catch (_) {}
    }
  }

  static TranslateLanguage? _toMlKit(String bcp) {
    for (final TranslateLanguage l in TranslateLanguage.values) {
      if (l.bcpCode == bcp) return l;
    }
    return null;
  }

  /// Terjemahan [text] ke bahasa yang dipilih.
  /// Kalau belum ada, teks asli dikembalikan dulu dan terjemahannya menyusul
  /// (layar diperbarui otomatis begitu selesai).
  String translate(String text) {
    if (isSource || !_needsTranslation(text)) return text;
    final String? manual = _manual[text]?[code];
    if (manual != null) return manual;
    final String? cached = _cache[text];
    if (cached != null) return cached;
    if (!_failed.contains(text) && _pending.add(text)) _scheduleFlush();
    return text;
  }

  static final RegExp _letter = RegExp(r'[A-Za-zÀ-ÿ]');
  static final RegExp _skip = RegExp(r'@|https?://|www\.');

  static bool _needsTranslation(String text) {
    final String t = text.trim();
    return t.isNotEmpty && _letter.hasMatch(t) && !_skip.hasMatch(t);
  }

  void _scheduleFlush() {
    if (!_ready || _flushing) return;
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(milliseconds: 60), _flush);
  }

  Future<void> _flush() async {
    if (_flushing || !_ready) return;
    _flushing = true;
    final String forCode = code;
    try {
      while (_pending.isNotEmpty && _ready && code == forCode) {
        final List<String> batch = _pending.take(25).toList();
        _pending.removeAll(batch);
        bool changed = false;
        for (final String text in batch) {
          final OnDeviceTranslator? t = _translator;
          if (t == null || code != forCode) break;
          try {
            _cache[text] = await _translateKeepingLines(t, text);
            changed = true;
          } catch (_) {
            _failed.add(text); // jangan dicoba terus-menerus
          }
        }
        if (changed && code == forCode) {
          notifyListeners();
          _scheduleSave();
        }
      }
    } finally {
      _flushing = false;
    }
    // Teks baru yang masuk selama proses tadi.
    if (_pending.isNotEmpty && code == forCode) _scheduleFlush();
  }

  /// ML Kit kadang menghapus baris baru, jadi tiap baris diterjemahkan sendiri.
  static Future<String> _translateKeepingLines(OnDeviceTranslator t, String text) async {
    final List<String> lines = text.split('\n');
    final List<String> out = <String>[];
    for (final String line in lines) {
      out.add(_needsTranslation(line) ? await t.translateText(line) : line);
    }
    return out.join('\n');
  }

  Map<String, String> _readCache(String forCode) {
    try {
      final String? raw = _prefs?.getString('$_keyCachePrefix$forCode');
      if (raw == null) return <String, String>{};
      final dynamic decoded = json.decode(raw);
      if (decoded is Map) {
        return decoded.map((dynamic k, dynamic v) => MapEntry<String, String>('$k', '$v'));
      }
    } catch (_) {}
    return <String, String>{};
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    final String forCode = code;
    final Map<String, String> snapshot = Map<String, String>.of(_cache);
    _saveTimer = Timer(const Duration(seconds: 1), () async {
      try {
        await _prefs?.setString('$_keyCachePrefix$forCode', json.encode(snapshot));
      } catch (_) {}
    });
  }

  /// Hapus semua terjemahan tersimpan (misalnya kalau hasilnya aneh) lalu terjemahkan ulang.
  Future<void> clearTranslations() async {
    _cache = <String, String>{};
    _failed.clear();
    try {
      await _prefs?.remove('$_keyCachePrefix$code');
    } catch (_) {}
    notifyListeners();
  }

  /// Kata pendek yang sering salah diterjemahkan mesin karena tidak ada konteksnya.
  static const Map<String, Map<String, String>> _manual = <String, Map<String, String>>{
    'Rendah': <String, String>{'en': 'Low', 'ms': 'Rendah', 'zh': '低'},
    'Sedang': <String, String>{'en': 'Medium', 'ms': 'Sederhana', 'zh': '中'},
    'Tinggi': <String, String>{'en': 'High', 'ms': 'Tinggi', 'zh': '高'},
    'Risiko Rendah': <String, String>{'en': 'Low risk', 'ms': 'Risiko rendah', 'zh': '低风险'},
    'Risiko Sedang': <String, String>{'en': 'Medium risk', 'ms': 'Risiko sederhana', 'zh': '中风险'},
    'Risiko Tinggi': <String, String>{'en': 'High risk', 'ms': 'Risiko tinggi', 'zh': '高风险'},
    'Beranda': <String, String>{'en': 'Home', 'ms': 'Utama', 'zh': '首页'},
    'Riwayat': <String, String>{'en': 'History', 'ms': 'Sejarah', 'zh': '记录'},
    'Edukasi': <String, String>{'en': 'Learn', 'ms': 'Edukasi', 'zh': '科普'},
    'Profil': <String, String>{'en': 'Profile', 'ms': 'Profil', 'zh': '我的'},
    'Bahu': <String, String>{'en': 'Shoulders', 'ms': 'Bahu', 'zh': '肩膀'},
    'Pinggul': <String, String>{'en': 'Hips', 'ms': 'Pinggul', 'zh': '臀部'},
    'Batal': <String, String>{'en': 'Cancel', 'ms': 'Batal', 'zh': '取消'},
    'Kembali': <String, String>{'en': 'Back', 'ms': 'Kembali', 'zh': '返回'},
  };
}

final AppLanguage appLanguage = AppLanguage();

/// Terjemahkan teks ke bahasa pilihan pengguna. Pakai untuk teks yang tidak
/// lewat widget Text, misalnya labelText, hintText, tooltip, atau tulisan di CustomPainter.
String tr(String text) => appLanguage.translate(text);