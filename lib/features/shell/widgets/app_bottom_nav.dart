import 'package:flutter/material.dart' hide Text;
import '../../../core/i18n/tr_text.dart';
import '../../../core/i18n/tr_text.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../tour/tour_keys.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const List<IconData> _icons = <IconData>[
    Icons.home_outlined,
    Icons.history,
    Icons.menu_book_outlined,
    Icons.person_outline,
  ];
  static const List<String> _labels = <String>['Beranda', 'Riwayat', 'Edukasi', 'Profil'];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: <Widget>[
                for (int i = 0; i < _labels.length; i++)
                  Expanded(
                    child: KeyedSubtree(
                      key: TourKeys.nav[i],
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onChanged(i),
                        child: SizedBox(
                          height: 52,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                _icons[i],
                                size: 24,
                                color: i == index ? AppColors.teal : AppColors.muted,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _labels[i],
                                style: ts(
                                  12,
                                  weight: i == index ? FontWeight.w700 : FontWeight.w600,
                                  color: i == index ? AppColors.teal : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}