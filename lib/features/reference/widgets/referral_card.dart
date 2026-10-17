import 'package:flutter/material.dart' hide Text;
import '../../../core/i18n/tr_text.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Muncul di halaman hasil kalau skor risiko di atas 60%.
class ReferralCard extends StatelessWidget {
  const ReferralCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x409C2B1B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.local_hospital_outlined, size: 22, color: AppColors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Disarankan periksa ke dokter',
                  style: ts(15, weight: FontWeight.w800, color: AppColors.red, height: 21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Skor risiko di atas 60%. Masuk dengan akun Google dan isi data diri untuk '
            'melihat rumah sakit terdekat dari lokasi Anda.',
            style: ts(13, color: AppColors.ink, height: 19),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
              textStyle: ts(14, weight: FontWeight.w700),
            ),
            icon: const Icon(Icons.near_me_outlined, size: 20),
            label: const Text('Cari rumah sakit terdekat'),
          ),
        ],
      ),
    );
  }
}