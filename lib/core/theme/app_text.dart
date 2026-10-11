import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Gaya teks Plus Jakarta Sans. [height] = tinggi baris dalam piksel.
/// Kalau tidak mau memakai package google_fonts, ganti isi fungsi ini dengan
/// TextStyle(...) biasa dan hapus import google_fonts di atas.
TextStyle ts(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.ink,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height == null ? null : height / size,
    letterSpacing: letterSpacing,
  );
}