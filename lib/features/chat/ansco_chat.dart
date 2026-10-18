import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/i18n/app_language.dart';
import '../../core/i18n/languages.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_config.dart';
import '../../data/models/personal_data.dart';
import '../../data/models/screening_record.dart';
import '../../data/services/chat_service.dart';
import '../../state/app_data.dart';

class ChatMessage {
  const ChatMessage({required this.fromUser, required this.text, required this.time});

  final bool fromUser;
  final String text;
  final DateTime time;

  Map<String, dynamic> toJson() => <String, dynamic>{'u': fromUser, 't': text, 'd': time.toIso8601String()};

  static ChatMessage? fromJson(dynamic raw) {
    if (raw is! Map || raw['t'] is! String) return null;
    return ChatMessage(
      fromUser: raw['u'] == true,
      text: raw['t'] as String,
      time: DateTime.tryParse('${raw['d']}') ?? DateTime.now(),
    );
  }
}

/// Isi percakapan dengan AnSco. Disimpan di HP per akun (tamu punya simpanan sendiri).
class AnScoChat extends ChangeNotifier {
  static const int _keep = 60; // pesan yang disimpan di HP

  final List<ChatMessage> messages = <ChatMessage>[];
  bool sending = false;
  String? error; // pesan gagal terakhir; pesan pengguna tetap ada dan bisa dikirim ulang
  String? _loadedFor;

  String get _owner => appData.account?.id ?? 'tamu';
  String get _key => 'ansco_chat_$_owner';

  /// Muat percakapan milik akun yang sedang masuk (dipanggil saat layar chat dibuka).
  Future<void> ensureLoaded() async {
    if (_loadedFor == _owner) return;
    _loadedFor = _owner;
    messages.clear();
    error = null;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw != null) {
        for (final dynamic m in json.decode(raw) as List<dynamic>) {
          final ChatMessage? msg = ChatMessage.fromJson(m);
          if (msg != null) messages.add(msg);
        }
      }
    } catch (_) {
      // Simpanan rusak: mulai dari kosong.
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<ChatMessage> keep =
          messages.length > _keep ? messages.sublist(messages.length - _keep) : messages;
      await prefs.setString(_key, json.encode(keep.map((ChatMessage m) => m.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> send(String text) async {
    final String t = text.trim();
    if (t.isEmpty || sending) return;
    messages.add(ChatMessage(fromUser: true, text: t, time: DateTime.now()));
    await _ask();
  }

  /// Kirim ulang setelah gagal (pesan terakhir pengguna masih ada).
  Future<void> retry() => _ask();

  Future<void> _ask() async {
    sending = true;
    error = null;
    notifyListeners();
    try {
      final List<ChatMessage> recent =
          messages.length > 16 ? messages.sublist(messages.length - 16) : messages;
      final String reply = await ChatService.send(
        messages: recent
            .map((ChatMessage m) => <String, String>{'role': m.fromUser ? 'user' : 'assistant', 'content': m.text})
            .toList(),
        context: buildUserContext(),
        language: languageByCode(appLanguage.code).englishName,
      );
      messages.add(ChatMessage(fromUser: false, text: reply, time: DateTime.now()));
      _save();
    } on ChatFailure catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Terjadi kesalahan: $e';
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  Future<void> clear() async {
    messages.clear();
    error = null;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}

final AnScoChat anscoChat = AnScoChat();

/// Ringkasan data pengguna yang dibaca AnSco. Nomor telepon tidak ikut dikirim.
String buildUserContext() {
  final StringBuffer b = StringBuffer();
  final String nick = appData.name.trim();
  b.writeln('Tanggal hari ini: ${formatDate(DateTime.now())}');
  b.writeln('Status: ${appData.isSignedIn ? 'masuk dengan akun' : 'tamu (belum login)'}');
  if (nick.isNotEmpty) b.writeln('Nama panggilan: $nick');
  final PersonalData? personal = appData.personal;
  if (personal != null) {
    b.writeln('Nama lengkap: ${personal.fullName}');
    b.writeln('Umur: ${personal.age} tahun, jenis kelamin: ${personal.gender}');
  }

  final List<ScreeningRecord> r = appData.records;
  b.writeln('Jumlah screening tersimpan: ${r.length}');
  if (r.isEmpty) {
    b.writeln('Belum pernah screening.');
    return b.toString();
  }
  b.writeln('Riwayat screening (terbaru di atas, maksimal 8):');
  for (final ScreeningRecord rec in r.take(8)) {
    final double? s = rec.riskScore;
    final dynamic conf = rec.result['confidence'];
    b.write('- ${formatDate(rec.date)}: skor risiko ${s == null ? '-' : (s * 100).round()}/100');
    b.write(', tingkat ${rec.riskLevel ?? '-'}');
    final dynamic label = rec.result['label'];
    if (label != null) b.write(', label model "$label"');
    if (conf is num) b.write(', keyakinan ${(conf * 100).round()}%');
    if (rec.result['needs_review'] == true) b.write(', foto perlu dicek ulang');
    b.writeln();
  }

  // Detail postur hasil terakhir (angka dari model, dibulatkan).
  final dynamic feats = r.first.result['posture_features'];
  if (feats is Map && feats.isNotEmpty) {
    b.writeln('Detail postur hasil terakhir:');
    int n = 0;
    for (final MapEntry<dynamic, dynamic> e in feats.entries) {
      if (e.value is! num || n >= 12) continue;
      b.writeln('  ${e.key}: ${(e.value as num).toStringAsFixed(3)}');
      n++;
    }
  }
  b.writeln('Batas tingkat risiko (skala 0-100): rendah < ${(riskLowMax * 100).round()}, '
      'sedang ${(riskLowMax * 100).round()}-${(riskMidMax * 100).round()}, tinggi > ${(riskMidMax * 100).round()}.');
  return b.toString();
}