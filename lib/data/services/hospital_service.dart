import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/utils/geo.dart';
import '../models/hospital.dart';

class HospitalFailure implements Exception {
  const HospitalFailure(this.message);

  final String message;
}

/// Rumah sakit di sekitar pengguna dari OpenStreetMap (Overpass API, gratis, tanpa API key).
class HospitalService {
  HospitalService._();

  static const String _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Cari dalam radius 10 km; kalau hasilnya sedikit, perluas ke 30 km.
  static Future<List<Hospital>> nearby(double latitude, double longitude) async {
    List<Hospital> found = await _query(latitude, longitude, 10000);
    if (found.length < 3) {
      found = await _query(latitude, longitude, 30000);
    }
    return found;
  }

  static Future<List<Hospital>> _query(double lat, double lon, int radius) async {
    final String around = '(around:$radius,$lat,$lon)';
    final String query = '[out:json][timeout:25];('
        'node["amenity"="hospital"]$around;'
        'way["amenity"="hospital"]$around;'
        'relation["amenity"="hospital"]$around;'
        ');out center tags;';

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse(_endpoint),
        headers: <String, String>{'User-Agent': 'SkolioCek/1.0 (aplikasi skripsi)'},
        body: <String, String>{'data': query},
      ).timeout(const Duration(seconds: 35));
    } on TimeoutException {
      throw const HospitalFailure('Server data rumah sakit terlalu lama menjawab. Coba lagi sebentar lagi.');
    }
    if (response.statusCode != 200) {
      throw HospitalFailure(
        'Server data rumah sakit sedang sibuk (status ${response.statusCode}). Coba lagi sebentar lagi.',
      );
    }

    final dynamic body = json.decode(utf8.decode(response.bodyBytes));
    final dynamic elements = body is Map ? body['elements'] : null;
    if (elements is! List) return <Hospital>[];

    // Satu rumah sakit kadang tercatat dua kali (titik dan bangunan): ambil yang terdekat.
    final Map<String, Hospital> byName = <String, Hospital>{};
    for (final dynamic element in elements) {
      if (element is! Map) continue;
      double? hLat;
      double? hLon;
      final dynamic center = element['center'];
      if (element['lat'] is num && element['lon'] is num) {
        hLat = (element['lat'] as num).toDouble();
        hLon = (element['lon'] as num).toDouble();
      } else if (center is Map && center['lat'] is num && center['lon'] is num) {
        hLat = (center['lat'] as num).toDouble();
        hLon = (center['lon'] as num).toDouble();
      }
      if (hLat == null || hLon == null) continue;

      final dynamic rawTags = element['tags'];
      final Map<dynamic, dynamic> tags = rawTags is Map ? rawTags : const <dynamic, dynamic>{};
      final String name = (tags['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;

      final double distance = distanceMeters(lat, lon, hLat, hLon);
      final Hospital hospital = Hospital(
        name: name,
        latitude: hLat,
        longitude: hLon,
        distanceMeters: distance,
        address: _address(tags),
        phone: (tags['phone'] ?? tags['contact:phone'] ?? '').toString().split(';').first.trim(),
        emergency: tags['emergency']?.toString() == 'yes',
      );
      final String key = name.toLowerCase();
      final Hospital? existing = byName[key];
      if (existing == null || distance < existing.distanceMeters) {
        byName[key] = hospital;
      }
    }

    final List<Hospital> list = byName.values.toList()
      ..sort((Hospital a, Hospital b) => a.distanceMeters.compareTo(b.distanceMeters));
    return list.take(20).toList();
  }

  static String _address(Map<dynamic, dynamic> tags) {
    final String full = (tags['addr:full'] ?? '').toString().trim();
    if (full.isNotEmpty) return full;
    final List<String> parts = <String>[
      <String>[
        (tags['addr:street'] ?? '').toString().trim(),
        (tags['addr:housenumber'] ?? '').toString().trim(),
      ].where((String s) => s.isNotEmpty).join(' '),
      (tags['addr:city'] ?? '').toString().trim(),
    ].where((String s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }
}