import 'dart:io';

import 'package:flutter/material.dart' hide Text;
import 'package:image_picker/image_picker.dart';

import '../../core/i18n/tr_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/icon_title.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/personal_data.dart';
import '../../data/models/user_account.dart';
import '../../state/app_data.dart';
import '../auth/login_screen.dart';
import '../dashboard/widgets/language_sheet.dart';
import '../personal_data/personal_data_screen.dart';

class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key, required this.onShowTutorial});

  final VoidCallback onShowTutorial; // memulai tur sorotan di Beranda

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  final ImagePicker _picker = ImagePicker();

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------- Foto profil ----------

  Future<void> _changePhoto() async {
    final String? choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (BuildContext sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text('Foto profil', style: ts(18, weight: FontWeight.w800, height: 24)),
              const SizedBox(height: 12),
              _sheetTile(sheet, Icons.photo_library_outlined, 'Pilih dari galeri', 'galeri'),
              _sheetTile(sheet, Icons.photo_camera_outlined, 'Ambil foto', 'kamera'),
              if (appData.avatarFile != null)
                _sheetTile(sheet, Icons.restart_alt_rounded, 'Pakai foto akun / email', 'hapus'),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'hapus') {
      await appData.removeAvatar();
      return;
    }
    try {
      final XFile? picked = await _picker.pickImage(
        source: choice == 'kamera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked == null) return;
      await appData.setAvatar(File(picked.path));
      if (mounted) _snack('Foto profil diganti.');
    } catch (e) {
      if (mounted) _snack('Foto tidak bisa dipakai: $e');
    }
  }

  Widget _sheetTile(BuildContext sheet, IconData icon, String label, String value) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: IconTile(icon: icon, size: 40),
      title: Text(label, style: ts(15, weight: FontWeight.w700)),
      onTap: () => Navigator.of(sheet).pop(value),
    );
  }

  // ---------- Aksi lain ----------

  Future<void> _editName() async {
    final TextEditingController controller = TextEditingController(text: appData.name);
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        title: const Text('Nama panggilan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: tr('Nama yang tampil di beranda')),
          onSubmitted: (String v) => Navigator.of(dialog).pop(v),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(controller.text), child: const Text('Simpan')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await appData.setName(value.trim());
    if (mounted) _snack('Nama disimpan.');
  }

  Future<void> _clearHistory() async {
    final bool ok = await confirmDialog(
      context,
      title: 'Hapus semua riwayat?',
      message: 'Semua hasil dan foto di HP ini, dan yang tersimpan di akun Anda, akan dihapus.',
      confirmLabel: 'Hapus semua',
    );
    if (!ok) return;
    await appData.clearAll();
    if (mounted) _snack('Riwayat dihapus.');
  }

  Future<void> _signIn() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const LoginScreen(mode: LoginMode.signInOnly),
      ),
    );
  }

  Future<void> _signOut() async {
    final bool ok = await confirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda lanjut sebagai tamu. Riwayat dan data diri tetap aman di akun dan muncul lagi saat masuk.',
      confirmLabel: 'Keluar',
    );
    if (!ok) return;
    await appData.signOut();
    if (mounted) _snack('Anda sudah keluar.');
  }

  Future<void> _openPersonalData() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (BuildContext context) => const DataDiriScreen()),
    );
    if (saved == true && mounted) _snack('Data diri disimpan.');
  }

  // ---------- Tampilan ----------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[appData, appLanguage]),
      builder: (BuildContext context, Widget? child) => _buildContent(),
    );
  }

  Widget _buildContent() {
    final UserAccount? account = appData.account;
    final PersonalData? p = appData.personal;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: <Widget>[
        Text('Profil', style: ts(26, weight: FontWeight.w800, height: 32, letterSpacing: -0.5)),
        const SizedBox(height: 18),
        _buildHeader(account),
        const SizedBox(height: 24),
        const SectionTitle('Akun'),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: <Widget>[
              if (account != null)
                _tile(
                  icon: Icons.badge_outlined,
                  title: 'Data diri',
                  subtitle: p == null ? 'Belum diisi · dipakai untuk ringkasan ke dokter' : null,
                  subtitleRaw: p == null ? null : '${p.fullName} · ${tr('${p.age} tahun')} · ${tr(p.gender)}',
                  onTap: _openPersonalData,
                ),
              _tile(
                icon: Icons.edit_outlined,
                title: 'Nama panggilan',
                subtitleRaw: appData.name.isEmpty ? tr('Belum diisi') : appData.name,
                onTap: _editName,
              ),
              _tile(
                icon: Icons.translate_rounded,
                title: 'Bahasa',
                subtitleRaw: appLanguage.current.nativeName,
                onTap: () => showLanguageSheet(context),
              ),
              _tile(
                icon: Icons.school_outlined,
                title: 'Lihat tutorial lagi',
                subtitle: 'Penjelasan singkat tiap fitur aplikasi',
                onTap: widget.onShowTutorial,
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Data dan privasi'),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.teal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        account == null
                            ? 'Foto dikirim ke server hanya untuk dianalisis. Sebagai tamu, riwayat dan foto hanya ada di HP ini.'
                            : 'Foto dikirim ke server untuk dianalisis. Hasil dan fotonya disimpan di akun Anda dan hanya bisa dibuka oleh Anda sendiri.',
                        style: ts(13, color: AppColors.inkSoft, height: 19),
                      ),
                    ),
                  ],
                ),
              ),
              _tile(
                icon: Icons.delete_outline_rounded,
                title: 'Hapus semua riwayat',
                onTap: _clearHistory,
                danger: true,
                last: true,
              ),
            ],
          ),
        ),
        if (account != null) ...<Widget>[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _signOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.redTint, width: 1.5),
              minimumSize: const Size.fromHeight(52),
              textStyle: ts(15, weight: FontWeight.w700),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Keluar dari akun'),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'AppSco · Alat screening awal, bukan pengganti pemeriksaan dokter.',
          textAlign: TextAlign.center,
          style: ts(12, color: AppColors.muted, height: 17),
        ),
      ],
    );
  }

  Widget _buildHeader(UserAccount? account) {
    final String title = account == null
        ? 'Tamu'
        : (account.name.isNotEmpty ? account.name : (appData.name.isNotEmpty ? appData.name : account.email));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x330B4F4A), blurRadius: 28, offset: Offset(0, 14)),
        ],
      ),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: _changePhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                const UserAvatar(size: 72, borderColor: Colors.white),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.teal, width: 2),
                    ),
                    child: const Icon(Icons.photo_camera_rounded, size: 15, color: AppColors.teal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  translate: account == null,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(19, weight: FontWeight.w800, color: Colors.white, height: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  account == null ? 'Belum masuk ke akun' : account.email,
                  translate: account == null,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(13, color: Colors.white.withValues(alpha: 0.78), height: 18),
                ),
                const SizedBox(height: 10),
                if (account == null)
                  FilledButton(
                    onPressed: _signIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.teal,
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      textStyle: ts(14, weight: FontWeight.w800),
                    ),
                    child: const Text('Masuk / Daftar'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(account.isGoogle ? Icons.g_mobiledata_rounded : Icons.mail_outline_rounded,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          account.isGoogle ? 'Akun Google' : 'Akun email',
                          style: ts(12, weight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Satu baris pengaturan. [subtitle] diterjemahkan; [subtitleRaw] ditampilkan apa adanya.
  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? subtitleRaw,
    required VoidCallback onTap,
    bool danger = false,
    bool last = false,
  }) {
    final Color color = danger ? AppColors.red : AppColors.teal;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.lineSoft)),
        ),
        child: Row(
          children: <Widget>[
            IconTile(
              icon: icon,
              size: 40,
              background: danger ? AppColors.redTint : AppColors.tealTint,
              foreground: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: ts(15, weight: FontWeight.w700, color: danger ? AppColors.red : AppColors.ink, height: 20)),
                  if (subtitle != null || subtitleRaw != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitleRaw ?? subtitle!,
                      translate: subtitleRaw == null,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ts(13, color: AppColors.muted, height: 18),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: danger ? AppColors.red : AppColors.muted),
          ],
        ),
      ),
    );
  }
}