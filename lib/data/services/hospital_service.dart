import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/geo.dart';
import '../models/hospital.dart';

class HospitalFailure implements Exception {
  const HospitalFailure(this.message);

  final String message;
}

/// Rumah sakit di sekitar pengguna dari OpenStreetMap (Overpass API, gratis, tanpa API key).
///
/// Supaya cepat dan jarang gagal:
/// - hasil disimpan di HP; kalau pengguna masih di sekitar lokasi yang sama, langsung dipakai,
/// - satu kueri saja (radius 25 km), bukan dua kali bertahap,
/// - beberapa server Overpass dicoba bergantian; yang pertama menjawab dipakai,
/// - kalau semua server gagal, hasil tersimpan terakhir tetap ditampilkan.
class HospitalService {
  HospitalService._();

  static const List<String> _servers = <String>[
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];
  static const int _radius = 25000; // meter
  static const Duration _stagger = Duration(seconds: 4); // jeda sebelum mencoba server berikutnya
  static const Duration _perServerTimeout = Duration(seconds: 20);

  static const String _cacheKey = 'rs_cache_v1';
  static const Duration _cacheFresh = Duration(days: 7);
  static const double _cacheNearMeters = 3000; // dianggap lokasi yang sama

  /// [forceRefresh] true: abaikan simpanan dan ambil ulang dari server.
  static Future<List<Hospital>> nearby(double latitude, double longitude, {bool forceRefresh = false}) async {
    final _Cached? cached = await _readCache();
    final double? movedMeters =
        cached == null ? null : distanceMeters(latitude, longitude, cached.lat, cached.lon);
    if (!forceRefresh &&
        cached != null &&
        movedMeters! <= _cacheNearMeters &&
        DateTime.now().difference(cached.time) <= _cacheFresh &&
        cached.items.isNotEmpty) {
      return _withDistances(cached.items, latitude, longitude);
    }

    try {
      final List<Hospital> fresh = await _fetchFastest(latitude, longitude);
      if (fresh.isNotEmpty) await _writeCache(latitude, longitude, fresh);
      return fresh;
    } on HospitalFailure {
      // Semua server gagal: pakai simpanan lama kalau lokasinya masih dekat (≤ 15 km).
      if (cached != null && movedMeters! <= 15000 && cached.items.isNotEmpty) {
        return _withDistances(cached.items, latitude, longitude);
      }
      rethrow;
    }
  }

  /// Server pertama dicoba langsung, server berikutnya menyusul tiap beberapa detik bila
  /// belum ada jawaban. Jawaban sukses pertama yang dipakai.
  static Future<List<Hospital>> _fetchFastest(double lat, double lon) {
    final Completer<List<Hospital>> done = Completer<List<Hospital>>();
    final http.Client client = http.Client();
    final List<Timer> timers = <Timer>[];
    final Set<int> started = <int>{};
    int failed = 0;
    String lastError = 'Server data rumah sakit tidak bisa dihubungi. Periksa internet lalu coba lagi.';

    void finish() {
      for (final Timer t in timers) {
        t.cancel();
      }
      client.close(); // hentikan permintaan lain yang masih berjalan
    }

    void start(int i) {
      if (done.isCompleted || i >= _servers.length || !started.add(i)) return;
      _query(client, _servers[i], lat, lon).then((List<Hospital> list) {
        if (done.isCompleted) return;
        done.complete(list);
        finish();
      }).catchError((Object e) {
        if (done.isCompleted) return;
        failed++;
        if (e is HospitalFailure) lastError = e.message;
        if (failed >= _servers.length) {
          done.completeError(HospitalFailure(lastError));
          finish();
          return;
        }
        // Server ini gagal: langsung coba server berikutnya yang belum dicoba.
        for (int j = 0; j < _servers.length; j++) {
          if (!started.contains(j)) {
            start(j);
            break;
          }
        }
      });
    }

    start(0);
    for (int i = 1; i < _servers.length; i++) {
      timers.add(Timer(_stagger * i, () => start(i)));
    }
    return done.future;
  }

  static Future<List<Hospital>> _query(http.Client client, String server, double lat, double lon) async {
    final String around = '(around:$_radius,$lat,$lon)';
    final String query = '[out:json][timeout:15];'
        'nwr["amenity"="hospital"]["name"]$around;'
        'out center tags 60;';

    final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse(server),
            headers: <String, String>{'User-Agent': 'AppSco/1.0 (aplikasi skripsi)'},
            body: <String, String>{'data': query},
          )
          .timeout(_perServerTimeout);
    } on TimeoutException {
      throw const HospitalFailure('Server data rumah sakit terlalu lama menjawab. Coba lagi sebentar lagi.');
    } catch (_) {
      throw const HospitalFailure('Server data rumah sakit tidak bisa dihubungi. Periksa internet lalu coba lagi.');
    }
    if (response.statusCode != 200) {
      throw HospitalFailure('Server data rumah sakit sedang sibuk (status ${response.statusCode}). Coba lagi sebentar lagi.');
    }

    final dynamic body;
    try {
      body = json.decode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const HospitalFailure('Jawaban server data rumah sakit tidak bisa dibaca. Coba lagi.');
    }
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

  /// Hitung ulang jarak dari posisi sekarang (simpanan dibuat dari posisi sebelumnya).
  static List<Hospital> _withDistances(List<Hospital> items, double lat, double lon) {
    final List<Hospital> list = items
        .map((Hospital h) => Hospital(
              name: h.name,
              latitude: h.latitude,
              longitude: h.longitude,
              distanceMeters: distanceMeters(lat, lon, h.latitude, h.longitude),
              address: h.address,
              phone: h.phone,
              emergency: h.emergency,
            ))
        .toList()
      ..sort((Hospital a, Hospital b) => a.distanceMeters.compareTo(b.distanceMeters));
    return list;
  }

  static Future<_Cached?> _readCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final dynamic m = json.decode(raw);
      if (m is! Map) return null;
      final List<Hospital> items = <Hospital>[];
      for (final dynamic h in (m['items'] as List<dynamic>? ?? <dynamic>[])) {
        if (h is! Map) continue;
        items.add(Hospital(
          name: '${h['name']}',
          latitude: (h['lat'] as num).toDouble(),
          longitude: (h['lon'] as num).toDouble(),
          distanceMeters: 0,
          address: '${h['address'] ?? ''}',
          phone: '${h['phone'] ?? ''}',
          emergency: h['emergency'] == true,
        ));
      }
      return _Cached(
        (m['lat'] as num).toDouble(),
        (m['lon'] as num).toDouble(),
        DateTime.parse('${m['time']}'),
        items,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeCache(double lat, double lon, List<Hospital> items) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        json.encode(<String, dynamic>{
          'lat': lat,
          'lon': lon,
          'time': DateTime.now().toIso8601String(),
          'items': items
              .map((Hospital h) => <String, dynamic>{
                    'name': h.name,
                    'lat': h.latitude,
                    'lon': h.longitude,
                    'address': h.address,
                    'phone': h.phone,
                    'emergency': h.emergency,
                  })
              .toList(),
        }),
      );
    } catch (_) {
      // Gagal menyimpan: tidak masalah, hanya tidak ada percepatan berikutnya.
    }
  }
}

class _Cached {
  const _Cached(this.lat, this.lon, this.time, this.items);

  final double lat;
  final double lon;
  final DateTime time;
  final List<Hospital> items;
}