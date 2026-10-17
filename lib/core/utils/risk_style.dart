import 'package:flutter/material.dart' hide Text;

import '../theme/app_colors.dart';

Color riskColor(String? level) {
  switch (level) {
    case 'Rendah':
      return AppColors.teal;
    case 'Sedang':
      return AppColors.amber;
    case 'Tinggi':
      return AppColors.red;
    default:
      return AppColors.ink;
  }
}

Color riskTint(String? level) {
  switch (level) {
    case 'Rendah':
      return AppColors.tealTint;
    case 'Sedang':
      return AppColors.amberTint;
    case 'Tinggi':
      return AppColors.redTint;
    default:
      return AppColors.lineSoft;
  }
}

String riskSummary(String? level) {
  switch (level) {
    case 'Rendah':
      return 'Postur terlihat cukup seimbang. Ulangi screening beberapa bulan lagi untuk memantau perubahannya.';
    case 'Sedang':
      return 'Ada beberapa ketidakseimbangan postur. Ulangi foto dengan posisi tegak, lalu pertimbangkan periksa ke dokter.';
    case 'Tinggi':
      return 'Terlihat ketidakseimbangan postur yang cukup jelas. Sebaiknya periksakan ke dokter ortopedi.';
    default:
      return 'Tingkat risiko tidak tersedia untuk hasil ini.';
  }
}