import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/risk_style.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/section_title.dart';
import '../../data/models/hospital.dart';
import '../../data/models/personal_data.dart';
import '../../data/services/hospital_service.dart';
import '../../data/services/location_service.dart';
import '../../state/app_data.dart';
import 'widgets/hospital_tile.dart';

enum _Stage { locating, searching, done, failed }

/// Ringkasan untuk dokter + daftar rumah sakit terdekat dari lokasi pengguna.
class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key, required this.result, required this.date});

  final Map<String, dynamic> result;
  final DateTime date;

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  _Stage _stage = _Stage.locating;
  List<Hospital> _hospitals = <Hospital>[];
  String? _error;
  bool _canOpenSettings = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _stage = _Stage.locating;
      _error = null;
      _canOpenSettings = false;
    });
    try {
      final Position position = await LocationService.current();
      if (!mounted) return;
      setState(() {
        _stage = _Stage.searching;
      });
      final List<Hospital> list =
          await HospitalService.nearby(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _hospitals = list;
        _stage = _Stage.done;
      });
    } on LocationFailure catch (e) {
      _fail(e.message, openSettings: e.openSettings);
    } on HospitalFailure catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Daftar rumah sakit gagal dimuat. Periksa koneksi internet lalu coba lagi.');
    }
  }

  void _fail(String message, {bool openSettings = false}) {
    if (!mounted) return;
    setState(() {
      _stage = _Stage.failed;
      _error = message;
      _canOpenSettings = openSettings;
    });
  }

  Future<void> _open(Uri uri) async {
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada aplikasi yang bisa membuka ini.')),
      );
    }
  }

  void _directions(Hospital h) {
    _open(Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${h.latitude},${h.longitude}',
    ));
  }

  void _call(Hospital h) {
    final String number = h.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    _open(Uri(scheme: 'tel', path: number));
  }

  void _searchMaps() {
    _open(Uri.parse('https://www.google.com/maps/search/?api=1&query=rumah+sakit+terdekat'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleIconButton(
                  icon: Icons.arrow_back,
                  label: 'Kembali',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    'Rujukan pemeriksaan',
                    textAlign: TextAlign.center,
                    style: ts(16, weight: FontWeight.w800, height: 22),
                  ),
                ),
                const SizedBox(width: 48, height: 48),
              ],
            ),
            const SizedBox(height: 16),
            _buildAdvice(),
            const SizedBox(height: 16),
            _buildSummary(),
            const SizedBox(height: 20),
            const SectionTitle('Rumah sakit terdekat'),
            const SizedBox(height: 10),
            ..._buildHospitals(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.teal),
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
                textStyle: ts(14, weight: FontWeight.w700),
              ),
              icon: const Icon(Icons.arrow_back, size: 20),
              label: const Text('Kembali ke hasil'),
            ),
            const SizedBox(height: 16),
            Text(
              'Data rumah sakit © OpenStreetMap contributors. Data bisa tidak lengkap; '
              'hubungi rumah sakit dulu untuk memastikan ada dokter spesialis ortopedi.',
              textAlign: TextAlign.center,
              style: ts(12, color: AppColors.muted, height: 17),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.medical_services_outlined, size: 22, color: AppColors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Periksakan ke dokter spesialis ortopedi',
                  style: ts(15, weight: FontWeight.w800, color: AppColors.red, height: 21),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minta pemeriksaan ke dokter Sp.OT (ortopedi). Dokter biasanya melakukan tes '
                  'membungkuk (Adam\'s forward bend) dan rontgen tulang belakang untuk memastikan. '
                  'Tunjukkan ringkasan di bawah ini saat periksa.',
                  style: ts(13, color: AppColors.ink, height: 19),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 128,
            child: Text(label, style: ts(13, color: AppColors.muted, height: 18)),
          ),
          Expanded(
            child: Text(value, style: ts(13, weight: FontWeight.w700, height: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final PersonalData? p = appData.personal;
    final String? level = widget.result['risk_level']?.toString();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Ringkasan untuk dokter', style: ts(15, weight: FontWeight.w700, height: 20)),
          const SizedBox(height: 8),
          if (p != null) ...<Widget>[
            _row('Nama', p.fullName),
            _row('Umur', '${p.age} tahun'),
            _row('Jenis kelamin', p.gender),
            if (p.phone.isNotEmpty) _row('No. HP', p.phone),
          ],
          _row('Tanggal screening', formatDate(widget.date)),
          _row('Skor risiko', formatPercent(widget.result['risk_score'])),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 128,
                  child: Text('Tingkat risiko', style: ts(13, color: AppColors.muted, height: 18)),
                ),
                Text(
                  level ?? '-',
                  style: ts(13, weight: FontWeight.w800, color: riskColor(level), height: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hasil dari aplikasi screening foto, bukan diagnosis.',
            style: ts(12, color: AppColors.muted, height: 17),
          ),
        ],
      ),
    );
  }

  // Cadangan kalau daftar gagal dimuat atau kosong.
  Widget _mapsLink() {
    return TextButton.icon(
      onPressed: _searchMaps,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.teal,
        textStyle: ts(14, weight: FontWeight.w700),
      ),
      icon: const Icon(Icons.map_outlined, size: 20),
      label: const Text('Cari di Google Maps'),
    );
  }

  Widget _status(String text) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.teal),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: ts(14, color: AppColors.inkSoft, height: 20))),
        ],
      ),
    );
  }

  List<Widget> _buildHospitals() {
    switch (_stage) {
      case _Stage.locating:
        return <Widget>[_status('Mencari lokasi Anda...')];
      case _Stage.searching:
        return <Widget>[_status('Mencari rumah sakit di sekitar Anda...')];
      case _Stage.failed:
        return <Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(_error ?? 'Terjadi kesalahan.', style: ts(14, height: 20)),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton(
                        onPressed: _load,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          minimumSize: const Size.fromHeight(44),
                          shape: const StadiumBorder(),
                          textStyle: ts(14, weight: FontWeight.w700),
                        ),
                        child: const Text('Coba lagi'),
                      ),
                    ),
                    if (_canOpenSettings) ...<Widget>[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: LocationService.openSettings,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.teal,
                            side: const BorderSide(color: AppColors.teal),
                            minimumSize: const Size.fromHeight(44),
                            shape: const StadiumBorder(),
                            textStyle: ts(14, weight: FontWeight.w700),
                          ),
                          child: const Text('Buka pengaturan'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                _mapsLink(),
              ],
            ),
          ),
        ];
      case _Stage.done:
        if (_hospitals.isEmpty) {
          return <Widget>[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Tidak ada rumah sakit yang tercatat dalam radius 30 km. '
                    'Coba cari langsung di Google Maps.',
                    style: ts(14, height: 20),
                  ),
                  const SizedBox(height: 4),
                  _mapsLink(),
                ],
              ),
            ),
          ];
        }
        final List<Widget> tiles = <Widget>[];
        for (int i = 0; i < _hospitals.length; i++) {
          final Hospital h = _hospitals[i];
          if (i > 0) tiles.add(const SizedBox(height: 10));
          tiles.add(
            HospitalTile(
              hospital: h,
              nearest: i == 0,
              onDirections: () => _directions(h),
              onCall: h.phone.isEmpty ? null : () => _call(h),
            ),
          );
        }
        return tiles;
    }
  }
}