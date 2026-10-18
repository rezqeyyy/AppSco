import 'package:flutter/material.dart' hide Text;

import '../../../core/i18n/tr_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../tour/tour_keys.dart';

/// Menu bawah: pil teal gelap yang mengambang.
/// Menu aktif = pil putih berisi ikon + nama (melebar halus saat dipilih);
/// menu lain = ikon saja dengan lebar sama, jadi jaraknya selalu rapi.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const List<IconData> _icons = <IconData>[
    Icons.home_outlined,
    Icons.history_rounded,
    Icons.menu_book_outlined,
    Icons.person_outline_rounded,
  ];
  static const List<IconData> _activeIcons = <IconData>[
    Icons.home_rounded,
    Icons.history_rounded,
    Icons.menu_book_rounded,
    Icons.person_rounded,
  ];
  static const List<String> _labels = <String>['Beranda', 'Riwayat', 'Edukasi', 'Profil'];

  static const Duration _anim = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.tealDeep,
            borderRadius: BorderRadius.circular(34),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x330F2327), blurRadius: 24, offset: Offset(0, 10)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (int i = 0; i < _labels.length; i++)
                KeyedSubtree(key: TourKeys.nav[i], child: _item(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final bool active = i == index;
    return Semantics(
      button: true,
      selected: active,
      label: tr(_labels[i]),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(i),
        child: AnimatedContainer(
          duration: _anim,
          curve: Curves.easeOutCubic,
          height: 52,
          constraints: const BoxConstraints(minWidth: 52),
          padding: EdgeInsets.symmetric(horizontal: active ? 18 : 14),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                active ? _activeIcons[i] : _icons[i],
                size: 24,
                color: active ? AppColors.teal : Colors.white.withValues(alpha: 0.72),
              ),
              // Nama menu muncul/menghilang dengan animasi lebar, jadi pil tidak "meloncat".
              AnimatedSize(
                duration: _anim,
                curve: Curves.easeOutCubic,
                child: active
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 96),
                          child: Text(
                            _labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ts(14, weight: FontWeight.w800, color: AppColors.teal),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}