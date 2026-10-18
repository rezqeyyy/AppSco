import 'package:flutter/material.dart' hide Text;

import '../../core/i18n/tr_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../data/models/personal_data.dart';
import '../../data/services/profile_service.dart';
import '../../state/app_data.dart';

/// Form data diri. Dipakai sebelum rujukan rumah sakit dan dari tab Profil.
/// Hasilnya pop(true) kalau tersimpan.
class DataDiriScreen extends StatefulWidget {
  const DataDiriScreen({super.key});

  @override
  State<DataDiriScreen> createState() => _DataDiriScreenState();
}

class _DataDiriScreenState extends State<DataDiriScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  DateTime? _birthDate;
  String? _gender;
  bool _showMissing = false; // tanggal lahir / jenis kelamin belum diisi saat menekan simpan
  bool _saving = false;

  // Nilai ini yang disimpan ke database, jadi tetap Bahasa Indonesia.
  // Yang diterjemahkan hanya tulisan di layar.
  static const List<String> _genders = <String>['Laki-laki', 'Perempuan'];

  @override
  void initState() {
    super.initState();
    final PersonalData? data = appData.personal;
    _nameController = TextEditingController(
      text: data?.fullName ?? appData.account?.name ?? '',
    );
    _phoneController = TextEditingController(text: data?.phone ?? '');
    _birthDate = data?.birthDate;
    _gender = data?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 15, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: tr('Tanggal lahir'),
      cancelText: tr('Batal'),
      confirmText: tr('Pilih'),
    );
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final bool formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk || _birthDate == null || _gender == null) {
      setState(() {
        _showMissing = true;
      });
      return;
    }
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    try {
      await appData.savePersonalData(
        PersonalData(
          fullName: _nameController.text.trim(),
          birthDate: _birthDate!,
          gender: _gender!,
          phone: _phoneController.text.trim(),
        ),
      );
    } on ProfileFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? birth = _birthDate;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleIconButton(
                    icon: Icons.arrow_back,
                    label: 'Kembali',
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                  Expanded(
                    child: Text(
                      'Data diri',
                      textAlign: TextAlign.center,
                      style: ts(16, weight: FontWeight.w800, height: 22),
                    ),
                  ),
                  const SizedBox(width: 48, height: 48),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Data ini ditampilkan sebagai ringkasan yang bisa Anda tunjukkan ke dokter.',
                style: ts(14, color: AppColors.muted, height: 20),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: tr('Nama lengkap'),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (String? value) {
                  if (value == null || value.trim().length < 2) return tr('Isi nama lengkap.');
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: tr('Tanggal lahir'),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                    errorText: _showMissing && birth == null ? tr('Pilih tanggal lahir.') : null,
                  ),
                  child: Text(
                    birth == null ? 'Pilih tanggal' : formatDate(birth),
                    style: ts(16, color: birth == null ? AppColors.muted : AppColors.ink, height: 22),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Jenis kelamin', style: ts(13, color: AppColors.muted, height: 18)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: <Widget>[
                  for (final String g in _genders)
                    ChoiceChip(
                      label: Text(g),
                      selected: _gender == g,
                      onSelected: (bool selected) {
                        setState(() {
                          _gender = g;
                        });
                      },
                      selectedColor: AppColors.tealTint,
                      labelStyle: ts(
                        14,
                        weight: FontWeight.w700,
                        color: _gender == g ? AppColors.teal : AppColors.ink,
                      ),
                      side: BorderSide(color: _gender == g ? AppColors.teal : AppColors.line),
                      backgroundColor: Colors.white,
                    ),
                ],
              ),
              if (_showMissing && _gender == null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  'Pilih jenis kelamin.',
                  style: ts(12, color: Theme.of(context).colorScheme.error, height: 16),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: tr('No. HP (tidak wajib)'),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lineSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.lock_outline, size: 20, color: AppColors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Data diri disimpan di akun Anda dan hanya bisa dibaca oleh Anda sendiri.',
                        style: ts(13, color: AppColors.inkSoft, height: 19),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: primaryButtonStyle(),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Simpan data diri'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}