import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/section_title.dart';
import '../../state/app_data.dart';

class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key});

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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('Profil', style: ts(24, weight: FontWeight.w800, height: 30)),
        const SizedBox(height: 20),
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