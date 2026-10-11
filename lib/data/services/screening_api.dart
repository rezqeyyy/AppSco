import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/app_config.dart';
import '../models/analysis_outcome.dart';

// Server selalu menjawab JSON; kalau bukan JSON (misalnya halaman error), hasilnya null.
Map<String, dynamic>? decodeBody(http.Response response) {
  try {
    final dynamic decoded = json.decode(utf8.decode(response.bodyBytes));
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

Future<AnalysisOutcome> analyzeImage(File file) async {
  try {
    final http.MultipartRequest request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('image', file.path));

    // Server gratis "tidur" setelah 15 menit tanpa permintaan, dan butuh sekitar
    // satu menit untuk bangun. Karena itu batas waktunya dibuat longgar.
    final http.StreamedResponse streamed =
        await request.send().timeout(const Duration(seconds: 120));
    final http.Response response = await http.Response.fromStream(streamed);
    final Map<String, dynamic>? body = decodeBody(response);

    if (response.statusCode == 200 && body != null) {
      if (body['status'] == 'ok') return AnalysisOutcome.ok(body);
      // invalid_image, no_detection, low_quality: server memberi alasannya di "message"
      return AnalysisOutcome.notice(
        body['message']?.toString() ?? 'Gambar tidak bisa dianalisis. Coba foto lain.',
      );
    }
    if (response.statusCode == 413) {
      return const AnalysisOutcome.error('Ukuran foto terlalu besar (maksimal 20 MB).');
    }
    final String? serverMessage = body == null ? null : body['message']?.toString();
    return AnalysisOutcome.error(
      serverMessage ?? 'Gagal dari server. Status: ${response.statusCode}',
    );
  } on TimeoutException {
    return const AnalysisOutcome.error(
      'Server terlalu lama menjawab. Server mungkin sedang bangun; coba lagi sebentar lagi.',
    );
  } catch (e) {
    return AnalysisOutcome.error('Koneksi gagal. Periksa koneksi internet Anda. Detail: $e');
  }
}