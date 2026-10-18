import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pose maskot AnSco. Gambarnya putih dengan latar transparan,
/// jadi selalu ditaruh di atas latar gelap (lapisan tur).
enum AnScoPose {
  lambai('assets/mascot/ansco_lambai.png'), // melambai: perkenalan
  atas('assets/mascot/ansco_atas.png'), // tangan ke atas: menunjuk sesuatu di atas
  bawah('assets/mascot/ansco_bawah.png'), // tangan ke bawah: menunjuk sesuatu di bawah
  tunjuk('assets/mascot/ansco_tunjuk.png'), // menunjuk ke samping (ke kartu)
  diam('assets/mascot/ansco_diam.png'); // berdiri santai

  const AnScoPose(this.asset);
  final String asset;
}

/// Gambar AnSco yang sedikit naik-turun (seperti bernapas) dan berganti pose dengan halus.
class AnScoFigure extends StatelessWidget {
  const AnScoFigure({super.key, required this.pose, required this.height, required this.bob});

  final AnScoPose pose;
  final double height;
  final double bob; // 0-1, berulang (dari animasi tur)

  static const double aspect = 308 / 359; // lebar / tinggi gambar

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -3 * math.sin(bob * 2 * math.pi)),
      child: SizedBox(
        width: height * aspect,
        height: height,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Image.asset(
            pose.asset,
            key: ValueKey<AnScoPose>(pose),
            height: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

/// Semua gambar maskot dimuat duluan supaya tidak berkedip saat ganti pose.
void precacheAnSco(BuildContext context) {
  for (final AnScoPose p in AnScoPose.values) {
    precacheImage(AssetImage(p.asset), context);
  }
}