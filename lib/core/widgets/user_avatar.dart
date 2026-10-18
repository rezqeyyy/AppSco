import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart' hide Text;

import '../i18n/tr_text.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../../state/app_data.dart';

/// Foto profil pengguna. Urutan sumber:
/// 1) foto yang dipilih sendiri, 2) foto akun Google, 3) foto dari alamat email (Gravatar),
/// 4) huruf depan nama di lingkaran teal.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.size = 50, this.borderColor});

  final double size;
  final Color? borderColor; // garis tepi (misalnya putih di atas kartu teal)

  static String gravatarUrl(String email, int px) {
    final String hash = md5.convert(utf8.encode(email.trim().toLowerCase())).toString();
    return 'https://www.gravatar.com/avatar/$hash?s=$px&d=404';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appData,
      builder: (BuildContext context, Widget? child) {
        final int px = (size * MediaQuery.devicePixelRatioOf(context)).round();
        ImageProvider? image;
        final File? file = appData.avatarFile;
        final String photo = appData.account?.photoUrl ?? '';
        final String email = appData.account?.email ?? '';
        if (file != null) {
          image = FileImage(file);
        } else if (photo.isNotEmpty) {
          image = NetworkImage(photo);
        } else if (email.isNotEmpty) {
          image = NetworkImage(gravatarUrl(email, px));
        }
        final Widget fallback = _initial();
        return Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(borderColor == null ? 0 : 2.5),
          decoration: BoxDecoration(shape: BoxShape.circle, color: borderColor),
          child: ClipOval(
            child: image == null
                ? fallback
                : Image(
                    key: ValueKey<int>(appData.avatarVersion),
                    image: image,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    // Selama memuat / kalau gagal (misalnya email tidak punya Gravatar): pakai inisial.
                    frameBuilder: (BuildContext c, Widget img, int? frame, bool sync) =>
                        frame == null && !sync ? fallback : img,
                    errorBuilder: (BuildContext c, Object e, StackTrace? s) => fallback,
                  ),
          ),
        );
      },
    );
  }

  Widget _initial() {
    final String source = appData.name.trim().isNotEmpty
        ? appData.name.trim()
        : (appData.account?.name.trim().isNotEmpty ?? false)
            ? appData.account!.name.trim()
            : 'A';
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Text(
        source.characters.first.toUpperCase(),
        translate: false,
        style: ts(size * 0.4, weight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}