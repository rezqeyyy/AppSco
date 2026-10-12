import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/hospital.dart';

class HospitalTile extends StatelessWidget {
  const HospitalTile({
    super.key,
    required this.hospital,
    required this.onDirections,
    this.onCall,
    this.nearest = false,
  });

  final Hospital hospital;
  final VoidCallback onDirections;
  final VoidCallback? onCall; // null kalau nomor telepon tidak ada
  final bool nearest;

  Widget _chip(String text, Color foreground, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: ts(12, weight: FontWeight.w700, color: foreground, height: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.local_hospital_outlined, size: 22, color: AppColors.red),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(hospital.name, style: ts(15, weight: FontWeight.w700, height: 21)),
                    if (hospital.address.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        hospital.address,
                        style: ts(13, color: AppColors.muted, height: 18),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        _chip(formatDistance(hospital.distanceMeters), AppColors.teal, AppColors.tealTint),
                        if (nearest) _chip('Terdekat', Colors.white, AppColors.teal),
                        if (hospital.emergency) _chip('IGD', AppColors.red, AppColors.redTint),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDirections,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: const StadiumBorder(),
                    textStyle: ts(14, weight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.directions, size: 20),
                  label: const Text('Petunjuk arah'),
                ),
              ),
              if (onCall != null) ...<Widget>[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onCall,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal),
                    minimumSize: const Size(0, 44),
                    shape: const StadiumBorder(),
                    textStyle: ts(14, weight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.call_outlined, size: 20),
                  label: const Text('Telepon'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}