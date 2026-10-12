import 'package:flutter/material.dart';

/// Penanda bagian layar yang disorot tur. Tiap kunci ditempel ke satu widget
/// (lewat KeyedSubtree), supaya tur tahu posisi dan ukurannya di layar.
class TourKeys {
  TourKeys._();

  static final GlobalKey startScreening = GlobalKey(debugLabel: 'tur_mulai_screening');
  static final GlobalKey lastResult = GlobalKey(debugLabel: 'tur_hasil_terakhir');
  static final GlobalKey learn = GlobalKey(debugLabel: 'tur_pelajari');

  /// Menu bawah: Beranda, Riwayat, Edukasi, Profil.
  static final List<GlobalKey> nav = <GlobalKey>[
    GlobalKey(debugLabel: 'tur_menu_beranda'),
    GlobalKey(debugLabel: 'tur_menu_riwayat'),
    GlobalKey(debugLabel: 'tur_menu_edukasi'),
    GlobalKey(debugLabel: 'tur_menu_profil'),
  ];
}