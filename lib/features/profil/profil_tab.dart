import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/icon_title.dart';
import '../../core/widgets/section_title.dart';
import '../../data/models/personal_data.dart';
import '../../data/models/user_account.dart';
import '../../state/app_data.dart';
import '../auth/login_screen.dart';
import '../personal_data/personal_data_screen.dart';

class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key, required this.onShowTutorial});

  final VoidCallback onShowTutorial; // memulai tur sorotan di Beranda

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: appData.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    FocusScope.of(context).unfocus();
    await appData.setName(_nameController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama disimpan.')));
  }

  Future<void> _clearHistory() async {
    final bool ok = await confirmDialog(
      context,
      title: 'Hapus semua riwayat?',
      message: 'Semua hasil dan foto yang tersimpan di HP ini dihapus.',
      confirmLabel: 'Hapus semua',
    );
    if (!ok) return;
    await appData.clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Riwayat dihapus.')));
  }

  Future<void> _signIn() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const LoginScreen(mode: LoginMode.signInOnly),
      ),
    );
    if (!mounted) return;
    if (_nameController.text.isEmpty) _nameController.text = appData.name;
  }

  Future<void> _signOut() async {
    final bool ok = await confirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda lanjut sebagai tamu. Data diri ikut dihapus dari HP ini; riwayat tetap ada.',
      confirmLabel: 'Keluar',
    );
    if (!ok) return;
    await appData.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Anda sudah keluar.')));
  }

  Future<void> _openPersonalData() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (BuildContext context) => const DataDiriScreen()),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Data diri disimpan.')));
    }
  }

  Widget _buildAccountCard() {
    final UserAccount? account = appData.account;
    final String? photo = account?.photoUrl;
    return AppCard(
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.tealTint,
            foregroundImage: photo == null || photo.isEmpty ? null : NetworkImage(photo),
            child: const Icon(Icons.person_outline, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  account == null
                      ? 'Tamu'
                      : (account.name.isEmpty ? account.email : account.name),
                  style: ts(15, weight: FontWeight.w700, height: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  account == null
                    ? 'Belum masuk ke akun'
                    : (account.isGoogle ? '${account.email} · Google' : account.email),
                  style: ts(13, color: AppColors.muted, height: 18),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (account == null)
            FilledButton(
              onPressed: _signIn,
              style: primaryButtonStyle(height: 40, fullWidth: false),
              child: const Text('Masuk'),
            )
          else
            TextButton(
              onPressed: _signOut,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.red,
                textStyle: ts(14, weight: FontWeight.w700),
              ),
              child: const Text('Keluar'),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalCard() {
    final PersonalData? p = appData.personal;
    return AppCard(
      onTap: _openPersonalData,
      child: Row(
        children: <Widget>[
          const IconTile(icon: Icons.badge_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Data diri', style: ts(14, weight: FontWeight.w700, height: 20)),
                const SizedBox(height: 2),
                Text(
                  p == null
                      ? 'Belum diisi. Dipakai untuk ringkasan ke dokter.'
                      : '${p.fullName} · ${p.age} tahun · ${p.gender}',
                  style: ts(13, color: AppColors.muted, height: 18),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appData,
      builder: (BuildContext context, Widget? child) => _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('Profil', style: ts(24, weight: FontWeight.w800, height: 30)),
        const SizedBox(height: 20),
        _buildAccountCard(),
        if (appData.isSignedIn) ...<Widget>[
          const SizedBox(height: 12),
          _buildPersonalCard(),
        ],
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (String value) => _saveName(),
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Nama yang tampil di beranda',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saveName,
                style: primaryButtonStyle(height: 48),
                child: const Text('Simpan nama'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: widget.onShowTutorial,
          child: Row(
            children: <Widget>[
              const IconTile(icon: Icons.school_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Lihat tutorial lagi', style: ts(14, weight: FontWeight.w700, height: 20)),
                    const SizedBox(height: 2),
                    Text(
                      'Penjelasan singkat tiap fitur aplikasi',
                      style: ts(13, color: AppColors.muted, height: 18),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Data dan privasi'),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Foto dikirim ke server untuk dianalisis. Riwayat dan foto yang Anda simpan hanya ada di HP ini.',
                style: ts(14, color: AppColors.inkSoft, height: 20),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _clearHistory,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                  textStyle: ts(14, weight: FontWeight.w700),
                ),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Hapus semua riwayat'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Alat screening awal, bukan pengganti pemeriksaan dokter.',
          textAlign: TextAlign.center,
          style: ts(12, color: AppColors.muted, height: 17),
        ),
      ],
    );
  }
}