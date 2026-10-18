import 'package:flutter/material.dart';

/// Palet AppSco: latar hangat yang lembut, teal sebagai warna utama, dan lime sebagai aksen.
/// Nama warna lama tetap dipakai supaya semua layar ikut berubah tanpa diubah satu per satu.
class AppColors {
  static const Color ground = Color(0xFFF3F6F5); // latar layar (abu kehijauan sangat muda)
  static const Color surface = Colors.white; // kartu
  static const Color ink = Color(0xFF0F2327); // teks utama
  static const Color inkSoft = Color(0xFF34494D);
  static const Color muted = Color(0xFF5B6E72); // teks keterangan
  static const Color line = Color(0xFFE3E8E4);
  static const Color lineSoft = Color(0xFFEEF1EC);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealDark = Color(0xFF0B4F4A);
  static const Color tealDeep = Color(0xFF07332F);
  static const Color tealTint = Color(0xFFDDF2EE);
  static const Color tealPale = Color(0xFFCFEAE5);
  static const Color lime = Color(0xFFFFFFFF); // tombol utama di atas kartu teal (putih)
  static const Color limeTint = Color(0xFFE6F4F1); // latar ikon/kotak kecil (mint lembut)
  static const Color amber = Color(0xFF9A5B00);
  static const Color amberBar = Color(0xFFE0A422);
  static const Color amberTint = Color(0xFFFCEFD2);
  static const Color red = Color(0xFFB42318);
  static const Color redTint = Color(0xFFFDE3DF);
  // Warna kartu artikel: satu keluarga hijau-biru yang kalem, supaya serasi dengan teal.
  static const Color lavender = Color(0xFFE4EEF6); // biru abu lembut
  static const Color peach = Color(0xFFEFF3E6); // hijau sage lembut
  static const Color sky = Color(0xFFE0F1F4); // aqua lembut
  static const Color dark = Color(0xFF0C1719);
  static const Color darkSurface = Color(0xFF1C2B2E);
  static const Color darkMuted = Color(0xFFB9CBC9);
  static const Color mint = Color(0xFF7FE3D8);

  /// Bayangan lembut untuk kartu (pengganti garis tepi).
  static const List<BoxShadow> softShadow = <BoxShadow>[
    BoxShadow(color: Color(0x120F2327), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF0B5C56), Color(0xFF13897F)],
  );
}