import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationFailure implements Exception {
  const LocationFailure(this.message, {this.openSettings = false});

  final String message;
  final bool openSettings; // tampilkan tombol ke pengaturan aplikasi
}

/// Lokasi pengguna dari GPS, dengan izin yang diminta saat dibutuhkan.
class LocationService {
  LocationService._();

  static Future<Position> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure('Lokasi (GPS) di HP sedang mati. Nyalakan lokasi lalu coba lagi.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Izin lokasi ditolak. Izin ini hanya dipakai untuk mencari rumah sakit terdekat.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Izin lokasi diblokir. Buka pengaturan aplikasi untuk mengizinkannya.',
        openSettings: true,
      );
    }
    // Lokasi terakhir yang masih baru (< 10 menit) langsung dipakai: untuk mencari rumah sakit
    // dalam radius puluhan km, akurasi beberapa ratus meter sudah cukup.
    try {
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null && DateTime.now().difference(last.timestamp).inMinutes < 10) {
        return last;
      }
    } catch (_) {
      // Tidak ada lokasi tersimpan: lanjut minta lokasi baru.
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // lebih cepat dari high, cukup untuk cari rumah sakit
          timeLimit: Duration(seconds: 12),
        ),
      );
    } on TimeoutException {
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw const LocationFailure(
        'Lokasi belum didapat. Coba di tempat terbuka atau nyalakan Wi-Fi, lalu coba lagi.',
      );
    }
  }

  static Future<bool> openSettings() => Geolocator.openAppSettings();
}