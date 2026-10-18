import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_config.dart';

class ChatFailure implements Exception {
  const ChatFailure(this.message);

  final String message;
}

/// Mengirim percakapan ke server AppSco, server yang meneruskan ke Groq.
/// API key Groq tidak pernah ada di aplikasi.
class ChatService {
  ChatService._();

  /// [messages]: daftar {'role': 'user'|'assistant', 'content': '...'}, urut lama → baru.
  static Future<String> send({
    required List<Map<String, String>> messages,
    required String context,
    required String language,
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(chatUrl),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: json.encode(<String, dynamic>{
              'messages': messages,
              'context': context,
              'language': language,
            }),
          )
          // Server Render gratis bisa "tidur" dan butuh waktu untuk bangun.
          .timeout(const Duration(seconds: 75));
    } on TimeoutException {
      throw const ChatFailure('AnSco terlalu lama menjawab. Coba kirim lagi.');
    } catch (_) {
      throw const ChatFailure('Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.');
    }

    dynamic body;
    try {
      body = json.decode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = null;
    }
    if (response.statusCode != 200 || body is! Map || body['reply'] is! String) {
      final dynamic msg = body is Map ? body['message'] : null;
      throw ChatFailure(msg is String && msg.isNotEmpty
          ? msg
          : 'AnSco sedang tidak bisa menjawab (status ${response.statusCode}). Coba lagi nanti.');
    }
    return (body['reply'] as String).trim();
  }
}