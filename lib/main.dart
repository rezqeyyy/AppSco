import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Alamat API di Render
const String apiUrl = 'https://backendscoli.onrender.com/api/v1/detect-scoliosis';

// Batas tingkat risiko. Harus sama dengan risk_thresholds di pipeline_config.json.
const double riskLowMax = 0.35;
const double riskMidMax = 0.65;

const String appName = 'SKOLIOCEK';

// ---------------------------------------------------------------------------
// Warna dan huruf (sama dengan desain)
// ---------------------------------------------------------------------------

class AppColors {
  static const Color ground = Color(0xFFF3F6F5);
  static const Color ink = Color(0xFF10262B);
  static const Color inkSoft = Color(0xFF33474C);
  static const Color muted = Color(0xFF4A5F64);
  static const Color line = Color(0xFFD9E2E0);
  static const Color lineSoft = Color(0xFFE6ECEB);
  static const Color teal = Color(0xFF0A6E6A);
  static const Color tealDark = Color(0xFF075552);
  static const Color tealTint = Color(0xFFDCEFEC);
  static const Color tealPale = Color(0xFFE3F4F2);
  static const Color amber = Color(0xFF8A5200);
  static const Color amberBar = Color(0xFFB87A10);
  static const Color amberTint = Color(0xFFFBE9C8);
  static const Color red = Color(0xFF9C2B1B);
  static const Color redTint = Color(0xFFF8DAD3);
  static const Color dark = Color(0xFF0C1719);
  static const Color darkSurface = Color(0xFF1C2B2E);
  static const Color darkMuted = Color(0xFFB9CBC9);
  static const Color mint = Color(0xFF7FE3D8);
}

/// Gaya teks Plus Jakarta Sans. [height] = tinggi baris dalam piksel.
/// Kalau tidak mau memakai package google_fonts, ganti isi fungsi ini dengan
/// TextStyle(...) biasa dan hapus import google_fonts di atas.
TextStyle ts(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.ink,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height == null ? null : height / size,
    letterSpacing: letterSpacing,
  );
}

Color riskColor(String? level) {
  switch (level) {
    case 'Rendah':
      return AppColors.teal;
    case 'Sedang':
      return AppColors.amber;
    case 'Tinggi':
      return AppColors.red;
    default:
      return AppColors.ink;
  }
}

Color riskTint(String? level) {
  switch (level) {
    case 'Rendah':
      return AppColors.tealTint;
    case 'Sedang':
      return AppColors.amberTint;
    case 'Tinggi':
      return AppColors.redTint;
    default:
      return AppColors.lineSoft;
  }
}

String riskSummary(String? level) {
  switch (level) {
    case 'Rendah':
      return 'Postur terlihat cukup seimbang. Ulangi screening beberapa bulan lagi untuk memantau perubahannya.';
    case 'Sedang':
      return 'Ada beberapa ketidakseimbangan postur. Ulangi foto dengan posisi tegak, lalu pertimbangkan periksa ke dokter.';
    case 'Tinggi':
      return 'Terlihat ketidakseimbangan postur yang cukup jelas. Sebaiknya periksakan ke dokter ortopedi.';
    default:
      return 'Tingkat risiko tidak tersedia untuk hasil ini.';
  }
}

const List<String> _bulan = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String formatDate(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

String formatDayMonth(DateTime d) => '${d.day} ${_bulan[d.month - 1]}';

String formatNumber(double value, int digits) {
  return value.toStringAsFixed(digits).replaceAll('.', ',');
}

String formatPercent(dynamic value) {
  if (value is num) return '${(value * 100).round()}%';
  return '-';
}

// ---------------------------------------------------------------------------
// Data: riwayat screening disimpan di HP (shared_preferences + folder aplikasi)
// ---------------------------------------------------------------------------

class ScreeningRecord {
  ScreeningRecord({
    required this.id,
    required this.date,
    required this.imagePath,
    required this.result,
  });

  final String id;
  final DateTime date;
  final String imagePath;
  final Map<String, dynamic> result;

  double? get riskScore {
    final dynamic v = result['risk_score'];
    return v is num ? v.toDouble() : null;
  }

  String? get riskLevel => result['risk_level']?.toString();

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'image': imagePath,
      'result': result,
    };
  }

  static ScreeningRecord? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final DateTime? date = DateTime.tryParse(raw['date']?.toString() ?? '');
    final dynamic result = raw['result'];
    if (date == null || result is! Map) return null;
    final Map<String, dynamic> resultMap = <String, dynamic>{};
    result.forEach((dynamic key, dynamic value) {
      resultMap[key.toString()] = value;
    });
    return ScreeningRecord(
      id: raw['id']?.toString() ?? date.toIso8601String(),
      date: date,
      imagePath: raw['image']?.toString() ?? '',
      result: resultMap,
    );
  }
}

class AppData extends ChangeNotifier {
  static const String _keyName = 'nama';
  static const String _keyHistory = 'riwayat_v1';

  bool loaded = false;
  String name = '';
  List<ScreeningRecord> records = <ScreeningRecord>[]; // terbaru di depan

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      name = prefs.getString(_keyName) ?? '';
      final String? raw = prefs.getString(_keyHistory);
      if (raw != null) {
        final dynamic decoded = json.decode(raw);
        if (decoded is List) {
          final List<ScreeningRecord> list = <ScreeningRecord>[];
          for (final dynamic item in decoded) {
            final ScreeningRecord? record = ScreeningRecord.fromJson(item);
            if (record != null) list.add(record);
          }
          list.sort((ScreeningRecord a, ScreeningRecord b) => b.date.compareTo(a.date));
          records = list;
        }
      }
    } catch (_) {
      // Data lama rusak atau penyimpanan tidak tersedia: mulai dari kosong.
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
      for (final ScreeningRecord record in records) {
        list.add(record.toJson());
      }
      await prefs.setString(_keyHistory, json.encode(list));
    } catch (_) {
      // Gagal menyimpan: riwayat tetap ada sampai aplikasi ditutup.
    }
  }

  Future<void> setName(String value) async {
    name = value;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyName, value);
    } catch (_) {
      // Gagal menyimpan: nama tetap dipakai sampai aplikasi ditutup.
    }
  }

  /// Menyalin foto ke folder aplikasi (supaya tidak hilang saat cache dibersihkan)
  /// lalu mencatat hasilnya di riwayat.
  Future<ScreeningRecord> addRecord(File image, Map<String, dynamic> result) async {
    final DateTime now = DateTime.now();
    final String id = now.millisecondsSinceEpoch.toString();
    String path = image.path;
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final int dot = image.path.lastIndexOf('.');
      final String ext =
          (dot >= 0 && image.path.length - dot <= 6) ? image.path.substring(dot) : '.jpg';
      final File copy = await image.copy('${dir.path}/screening_$id$ext');
      path = copy.path;
    } catch (_) {
      // Tidak bisa menyalin: pakai lokasi foto aslinya.
    }
    final ScreeningRecord record =
        ScreeningRecord(id: id, date: now, imagePath: path, result: result);
    records.insert(0, record);
    notifyListeners();
    await _saveHistory();
    return record;
  }

  Future<void> _deleteImage(ScreeningRecord record) async {
    try {
      final File file = File(record.imagePath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Foto sudah tidak ada atau tidak bisa dihapus: abaikan.
    }
  }

  Future<void> deleteRecord(ScreeningRecord record) async {
    records.remove(record);
    notifyListeners();
    await _deleteImage(record);
    await _saveHistory();
  }

  Future<void> clearAll() async {
    final List<ScreeningRecord> old = records;
    records = <ScreeningRecord>[];
    notifyListeners();
    for (final ScreeningRecord record in old) {
      await _deleteImage(record);
    }
    await _saveHistory();
  }
}

final AppData appData = AppData();

// ---------------------------------------------------------------------------
// Komunikasi dengan server
// ---------------------------------------------------------------------------

class AnalysisOutcome {
  const AnalysisOutcome.ok(this.result)
      : notice = null,
        error = null;
  const AnalysisOutcome.notice(this.notice)
      : result = null,
        error = null;
  const AnalysisOutcome.error(this.error)
      : result = null,
        notice = null;

  final Map<String, dynamic>? result; // terisi bila status server "ok"
  final String? notice; // gambar ditolak / punggung tidak terdeteksi (bukan error)
  final String? error; // masalah koneksi atau server
}

// Server selalu menjawab JSON; kalau bukan JSON (misalnya halaman error), hasilnya null.
Map<String, dynamic>? decodeBody(http.Response response) {
  try {
    final dynamic decoded = json.decode(utf8.decode(response.bodyBytes));
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

Future<AnalysisOutcome> analyzeImage(File file) async {
  try {
    final http.MultipartRequest request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('image', file.path));

    // Server gratis "tidur" setelah 15 menit tanpa permintaan, dan butuh sekitar
    // satu menit untuk bangun. Karena itu batas waktunya dibuat longgar.
    final http.StreamedResponse streamed =
        await request.send().timeout(const Duration(seconds: 120));
    final http.Response response = await http.Response.fromStream(streamed);
    final Map<String, dynamic>? body = decodeBody(response);

    if (response.statusCode == 200 && body != null) {
      if (body['status'] == 'ok') return AnalysisOutcome.ok(body);
      // invalid_image, no_detection, low_quality: server memberi alasannya di "message"
      return AnalysisOutcome.notice(
        body['message']?.toString() ?? 'Gambar tidak bisa dianalisis. Coba foto lain.',
      );
    }
    if (response.statusCode == 413) {
      return const AnalysisOutcome.error('Ukuran foto terlalu besar (maksimal 20 MB).');
    }
    final String? serverMessage = body == null ? null : body['message']?.toString();
    return AnalysisOutcome.error(
      serverMessage ?? 'Gagal dari server. Status: ${response.statusCode}',
    );
  } on TimeoutException {
    return const AnalysisOutcome.error(
      'Server terlalu lama menjawab. Server mungkin sedang bangun; coba lagi sebentar lagi.',
    );
  } catch (e) {
    return AnalysisOutcome.error('Koneksi gagal. Periksa koneksi internet Anda. Detail: $e');
  }
}

// ---------------------------------------------------------------------------
// Aplikasi
// ---------------------------------------------------------------------------

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appData.load();
  runApp(const ScoliosisApp());
}

class ScoliosisApp extends StatelessWidget {
  const ScoliosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.teal, primary: AppColors.teal),
      scaffoldBackgroundColor: AppColors.ground,
    );
    return MaterialApp(
      title: 'SkolioCek',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
            .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _goTo(int index) {
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (BuildContext context, Widget? child) {
        if (!appData.loaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _index,
              children: <Widget>[
                BerandaTab(onOpenTab: _goTo),
                const RiwayatTab(),
                const EdukasiTab(),
                const ProfilTab(),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomNav(index: _index, onChanged: _goTo),
        );
      },
    );
  }
}

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Komponen bersama
// ---------------------------------------------------------------------------

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.radius = 16,
    this.bordered = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: bordered ? const BorderSide(color: AppColors.line) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.background = Colors.white,
    this.foreground = AppColors.ink,
    this.bordered = true,
    this.size = 48,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final bool bordered;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: background,
        shape: CircleBorder(
          side: bordered ? const BorderSide(color: AppColors.line) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 24, color: foreground),
          ),
        ),
      ),
    );
  }
}

class RiskChip extends StatelessWidget {
  const RiskChip({super.key, required this.level, this.prefix = ''});

  final String? level;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final String text = level == null ? '-' : '$prefix$level';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: riskTint(level),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: ts(13, weight: FontWeight.w700, color: riskColor(level), height: 18),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: ts(15, weight: FontWeight.w700, height: 20));
  }
}

class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.background = AppColors.tealTint,
    this.foreground = AppColors.teal,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 22, color: foreground),
    );
  }
}

ButtonStyle primaryButtonStyle({double height = 52, bool fullWidth = true}) {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.teal,
    foregroundColor: Colors.white,
    minimumSize: fullWidth ? Size.fromHeight(height) : Size(0, height),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    shape: const StadiumBorder(),
    textStyle: ts(15, weight: FontWeight.w700),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result == true;
}

void openGuide(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (BuildContext context) => const PanduanScreen()),
  );
}

void openArticle(BuildContext context, Article article) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => ArticleScreen(article: article),
    ),
  );
}

void openRecord(BuildContext context, ScreeningRecord record) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => HasilScreen(
        image: File(record.imagePath),
        result: record.result,
        record: record,
      ),
    ),
  );
}

void drawDashedPath(Canvas canvas, Path path, Paint paint, double dash, double gap) {
  for (final metric in path.computeMetrics()) {
    double distance = 0;
    while (distance < metric.length) {
      final double end = distance + dash < metric.length ? distance + dash : metric.length;
      canvas.drawPath(metric.extractPath(distance, end), paint);
      distance += dash + gap;
    }
  }
}

// ---------------------------------------------------------------------------
// 1. Beranda
// ---------------------------------------------------------------------------

class BerandaTab extends StatelessWidget {
  const BerandaTab({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (BuildContext context, Widget? child) {
        final ScreeningRecord? last = appData.records.isEmpty ? null : appData.records.first;
        final String greeting = appData.name.isEmpty ? 'Halo!' : 'Halo, ${appData.name}';
        return ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        appName,
                        style: ts(
                          13,
                          weight: FontWeight.w800,
                          color: AppColors.teal,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        greeting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(24, weight: FontWeight.w800, height: 30),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CircleIconButton(
                  icon: Icons.person_outline,
                  label: 'Buka profil',
                  onTap: () => onOpenTab(3),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildHero(context),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                const Expanded(child: SectionTitle('Hasil terakhir')),
                TextButton(
                  onPressed: () => onOpenTab(1),
                  child: Text(
                    'Lihat riwayat',
                    style: ts(13, weight: FontWeight.w700, color: AppColors.teal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (last == null)
              AppCard(
                child: Text(
                  'Belum ada screening. Hasil yang disimpan akan muncul di sini.',
                  style: ts(14, color: AppColors.muted, height: 20),
                ),
              )
            else
              _buildLastResult(context, last),
            const SizedBox(height: 24),
            const SectionTitle('Pelajari'),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: _buildLearnCard(context, articles[0])),
                const SizedBox(width: 12),
                Expanded(child: _buildLearnCard(context, articles[2])),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Alat screening awal, bukan pengganti pemeriksaan dokter.',
              textAlign: TextAlign.center,
              style: ts(12, color: AppColors.muted, height: 17),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHero(BuildContext context) {
    return Material(
      color: AppColors.teal,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          const Positioned(
            right: 12,
            top: 0,
            child: CustomPaint(size: Size(96, 200), painter: HeroMotifPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Screening baru',
                        style: ts(20, weight: FontWeight.w800, color: Colors.white, height: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Satu foto punggung dari belakang. Aplikasi menandai titik tubuh dan menghitung tingkat risikonya.',
                        style: ts(14, color: AppColors.tealPale, height: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => openGuide(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.teal,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: const StadiumBorder(),
                    textStyle: ts(15, weight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.photo_camera_outlined, size: 22),
                  label: const Text('Mulai screening'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastResult(BuildContext context, ScreeningRecord last) {
    return AppCard(
      onTap: () => openRecord(context, last),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(formatDate(last.date), style: ts(13, color: AppColors.muted, height: 18)),
                const SizedBox(height: 8),
                RiskChip(level: last.riskLevel, prefix: 'Risiko '),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                formatPercent(last.riskScore),
                style: ts(28, weight: FontWeight.w800, height: 32),
              ),
              Text('skor risiko', style: ts(12, color: AppColors.muted, height: 16)),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
        ],
      ),
    );
  }

  Widget _buildLearnCard(BuildContext context, Article article) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => openArticle(context, article),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(article.icon, size: 22, color: AppColors.teal),
          const SizedBox(height: 8),
          Text(article.shortTitle, style: ts(14, weight: FontWeight.w700, height: 19)),
        ],
      ),
    );
  }
}

/// Hiasan di kartu "Screening baru": sumbu tubuh putus-putus dan tiga garis kiri-kanan.
class HeroMotifPainter extends CustomPainter {
  const HeroMotifPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const Color mint = Color(0xFF7FD6CE);
    final Paint dashed = Paint()
      ..color = mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final Path axis = Path();
    axis.moveTo(48, 8);
    axis.cubicTo(44, 50, 54, 92, 48, 132);
    axis.cubicTo(44, 160, 50, 180, 48, 196);
    drawDashedPath(canvas, axis, dashed, 2, 10);

    final Paint stroke = Paint()
      ..color = mint
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final Paint dot = Paint()..color = Colors.white;
    const List<List<Offset>> pairs = <List<Offset>>[
      <Offset>[Offset(14, 44), Offset(82, 50)],
      <Offset>[Offset(22, 96), Offset(78, 94)],
      <Offset>[Offset(18, 150), Offset(80, 153)],
    ];
    for (final List<Offset> pair in pairs) {
      canvas.drawLine(pair[0], pair[1], stroke);
      canvas.drawCircle(pair[0], 5, dot);
      canvas.drawCircle(pair[1], 5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant HeroMotifPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 2. Panduan foto
// ---------------------------------------------------------------------------

class PanduanScreen extends StatefulWidget {
  const PanduanScreen({super.key});

  @override
  State<PanduanScreen> createState() => _PanduanScreenState();
}

class _PanduanScreenState extends State<PanduanScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _isLoading = false;
  String? _message;

  Future<void> _pick(ImageSource source) async {
    if (_isLoading) return;
    try {
      final XFile? picked = await _picker.pickImage(source: source);
      if (picked == null || !mounted) return;
      final File file = File(picked.path);
      setState(() {
        _image = file;
        _message = null;
        _isLoading = true;
      });

      final AnalysisOutcome outcome = await analyzeImage(file);
      if (!mounted) return;

      final Map<String, dynamic>? result = outcome.result;
      if (result != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => HasilScreen(image: file, result: result),
          ),
        );
        return;
      }
      setState(() {
        _isLoading = false;
        _message = outcome.notice ?? outcome.error ?? 'Gambar tidak bisa dianalisis.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _message = 'Gagal mengambil gambar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? message = _message;
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleIconButton(
                    icon: Icons.arrow_back,
                    label: 'Kembali',
                    background: AppColors.darkSurface,
                    foreground: Colors.white,
                    bordered: false,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      'Panduan foto',
                      textAlign: TextAlign.center,
                      style: ts(15, weight: FontWeight.w700, color: Colors.white, height: 20),
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.info_outline,
                    label: 'Cara mengambil foto yang benar',
                    background: AppColors.darkSurface,
                    foreground: Colors.white,
                    bordered: false,
                    onTap: () => openArticle(context, articles[2]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Posisikan punggung seperti garis ini',
                textAlign: TextAlign.center,
                style: ts(19, weight: FontWeight.w800, color: Colors.white, height: 26),
              ),
              const SizedBox(height: 4),
              Text(
                'Minta orang lain memotret dari belakang, kamera sejajar punggung.',
                textAlign: TextAlign.center,
                style: ts(14, color: AppColors.darkMuted, height: 20),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildViewfinder()),
              if (message != null) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amberTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: ts(13, weight: FontWeight.w600, color: AppColors.amber, height: 19),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(child: _buildCheck('Berdiri tegak')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCheck('Tangan di samping')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(child: _buildCheck('Punggung terlihat penuh')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCheck('Latar polos')),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _buildGalleryButton(),
                    _buildShutter(),
                    const SizedBox(width: 52, height: 52),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    final File? image = _image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: AppColors.darkSurface,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (image == null)
              const CustomPaint(painter: SilhouetteGuidePainter())
            else
              Image.file(image, fit: BoxFit.cover),
            if (image == null)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.tealTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Contoh posisi',
                    style: ts(13, weight: FontWeight.w700, color: AppColors.tealDark, height: 18),
                  ),
                ),
              ),
            if (_isLoading)
              Container(
                color: const Color(0xB30C1719),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Sedang menganalisis',
                      textAlign: TextAlign.center,
                      style: ts(16, weight: FontWeight.w700, color: Colors.white, height: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Permintaan pertama bisa memakan waktu sekitar satu menit.',
                      textAlign: TextAlign.center,
                      style: ts(13, color: AppColors.darkMuted, height: 19),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheck(String text) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check, size: 18, color: AppColors.mint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: ts(13, weight: FontWeight.w600, color: Colors.white, height: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryButton() {
    return Tooltip(
      message: 'Pilih foto dari galeri',
      child: Material(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isLoading ? null : () => _pick(ImageSource.gallery),
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.photo_library_outlined, size: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildShutter() {
    return Semantics(
      button: true,
      label: 'Ambil foto dengan kamera',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 4)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isLoading ? null : () => _pick(ImageSource.camera),
          child: SizedBox(
            width: 76,
            height: 76,
            child: Center(
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Garis bantu: siluet punggung putus-putus, garis tengah tegak, dan sudut bingkai.
class SilhouetteGuidePainter extends CustomPainter {
  const SilhouetteGuidePainter();

  static Path buildSilhouette() {
    final Path p = Path();
    p.addOval(Rect.fromCircle(center: const Offset(171, 62), radius: 34));
    p.moveTo(157, 96);
    p.lineTo(157, 112);
    p.cubicTo(140, 120, 105, 122, 88, 134);
    p.cubicTo(72, 146, 66, 170, 64, 200);
    p.lineTo(58, 420);
    p.moveTo(92, 420);
    p.lineTo(98, 230);
    p.cubicTo(100, 215, 106, 205, 110, 200);
    p.lineTo(118, 290);
    p.cubicTo(116, 320, 108, 345, 106, 420);
    p.moveTo(236, 420);
    p.cubicTo(234, 345, 226, 320, 224, 290);
    p.lineTo(232, 200);
    p.cubicTo(236, 205, 242, 215, 244, 230);
    p.lineTo(250, 420);
    p.moveTo(284, 420);
    p.lineTo(278, 200);
    p.cubicTo(276, 170, 270, 146, 254, 134);
    p.cubicTo(237, 122, 202, 120, 185, 112);
    p.lineTo(185, 96);
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Gambar dibuat untuk bidang 342 x 440, lalu diskalakan ke ukuran layar.
    final double sx = size.width / 342;
    final double sy = size.height / 440;
    final double scale = sx < sy ? sx : sy;
    canvas.translate((size.width - 342 * scale) / 2, (size.height - 440 * scale) / 2);
    canvas.scale(scale);

    final Paint centerLine = Paint()
      ..color = const Color(0x73FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Path center = Path();
    center.moveTo(171, 24);
    center.lineTo(171, 424);
    drawDashedPath(canvas, center, centerLine, 6, 8);

    canvas.translate(0, 44);
    final Paint outline = Paint()
      ..color = AppColors.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    drawDashedPath(canvas, buildSilhouette(), outline, 10, 8);
    canvas.restore();

    // Sudut bingkai mengikuti ukuran layar yang sebenarnya.
    final Paint corner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const double m = 16;
    const double len = 24;
    final double w = size.width;
    final double h = size.height;
    canvas.drawLine(const Offset(m, m), const Offset(m + len, m), corner);
    canvas.drawLine(const Offset(m, m), const Offset(m, m + len), corner);
    canvas.drawLine(Offset(w - m, m), Offset(w - m - len, m), corner);
    canvas.drawLine(Offset(w - m, m), Offset(w - m, m + len), corner);
    canvas.drawLine(Offset(m, h - m), Offset(m + len, h - m), corner);
    canvas.drawLine(Offset(m, h - m), Offset(m, h - m - len), corner);
    canvas.drawLine(Offset(w - m, h - m), Offset(w - m - len, h - m), corner);
    canvas.drawLine(Offset(w - m, h - m), Offset(w - m, h - m - len), corner);
  }

  @override
  bool shouldRepaint(covariant SilhouetteGuidePainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 3. Hasil screening
// ---------------------------------------------------------------------------

class HasilScreen extends StatefulWidget {
  const HasilScreen({super.key, required this.image, required this.result, this.record});

  final File image;
  final Map<String, dynamic> result;
  final ScreeningRecord? record; // terisi kalau dibuka dari riwayat

  @override
  State<HasilScreen> createState() => _HasilScreenState();
}

class _HasilScreenState extends State<HasilScreen> {
  bool _showOverlay = true;
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    if (_saved || _saving) return;
    setState(() {
      _saving = true;
    });
    await appData.addRecord(widget.image, widget.result);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tersimpan di riwayat.')));
  }

  Future<void> _delete() async {
    final ScreeningRecord? record = widget.record;
    if (record == null) return;
    final bool ok = await confirmDialog(
      context,
      title: 'Hapus hasil ini?',
      message: 'Hasil dan fotonya dihapus dari HP ini.',
      confirmLabel: 'Hapus',
    );
    if (!ok) return;
    await appData.deleteRecord(record);
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _retake() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (BuildContext context) => const PanduanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> result = widget.result;
    final ScreeningRecord? record = widget.record;
    final List<MeasuredPoint> points = parseKeypoints(result['keypoints']);
    final String disclaimer = result['disclaimer']?.toString() ??
        'Hasil ini screening awal, bukan diagnosis. Hanya pemeriksaan dokter yang bisa memastikan skoliosis.';

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
                    'Hasil screening',
                    textAlign: TextAlign.center,
                    style: ts(16, weight: FontWeight.w800, height: 22),
                  ),
                ),
                if (record != null)
                  CircleIconButton(
                    icon: Icons.delete_outline,
                    label: 'Hapus dari riwayat',
                    onTap: _delete,
                  )
                else
                  const SizedBox(width: 48, height: 48),
              ],
            ),
            if (record != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                formatDate(record.date),
                textAlign: TextAlign.center,
                style: ts(13, color: AppColors.muted, height: 18),
              ),
            ],
            const SizedBox(height: 16),
            _buildPhoto(points),
            if (points.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Tampilkan titik pengukuran',
                      style: ts(14, weight: FontWeight.w700, height: 20),
                    ),
                  ),
                  Switch(
                    value: _showOverlay,
                    onChanged: (bool value) {
                      setState(() {
                        _showOverlay = value;
                      });
                    },
                  ),
                ],
              ),
              if (_showOverlay) _buildLegend(),
            ],
            const SizedBox(height: 16),
            _buildRiskCard(result),
            ..._buildNotes(result),
            ..._buildMeasurements(result),
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
                  const Icon(Icons.info_outline, size: 20, color: AppColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(disclaimer, style: ts(13, color: AppColors.inkSoft, height: 19)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (record == null) ...<Widget>[
              FilledButton(
                onPressed: (_saved || _saving) ? null : _save,
                style: primaryButtonStyle(),
                child: Text(_saved ? 'Tersimpan di riwayat' : 'Simpan ke riwayat'),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: _retake,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.teal),
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
                textStyle: ts(14, weight: FontWeight.w700),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(record == null ? 'Foto ulang' : 'Screening baru'),
            ),
          ],
        ),
      ),
    );
  }

  // Foto ditampilkan utuh (tidak dipotong) supaya posisi titik dari server,
  // yang berupa pecahan 0-1 dari lebar dan tinggi foto, jatuh tepat di tempatnya.
  Widget _buildPhoto(List<MeasuredPoint> points) {
    final dynamic overlay = widget.result['overlay'];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 460),
      child: Center(
        heightFactor: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: <Widget>[
              Image.file(
                widget.image,
                fit: BoxFit.contain,
                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                  return Container(
                    height: 200,
                    color: AppColors.lineSoft,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Foto tidak tersedia lagi di HP ini.',
                      textAlign: TextAlign.center,
                      style: ts(14, color: AppColors.muted, height: 20),
                    ),
                  );
                },
              ),
              if (_showOverlay && points.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(
                    painter: MeasurementPainter(
                      points: points,
                      pairs: overlay is Map
                          ? parsePairs(overlay['pairs'], points.length)
                          : const <List<int>>[],
                      axis: overlay is Map ? parseAxis(overlay['axis']) : const <Offset>[],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Widget marker, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        marker,
        const SizedBox(width: 6),
        Text(text, style: ts(12, color: AppColors.muted, height: 18)),
      ],
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink),
      ),
    );
  }

  Widget _legendBar(Color color) {
    return Container(
      width: 18,
      height: 4,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: <Widget>[
        _legendItem(_legendDot(const Color(0xFF00C766)), 'Titik tubuh'),
        _legendItem(_legendDot(MeasurementPainter.weakColor), 'Titik kurang yakin'),
        _legendItem(_legendBar(const Color(0xFFE08A00)), 'Garis kiri-kanan'),
        _legendItem(_legendBar(const Color(0xFF00A9C2)), 'Sumbu tubuh'),
        _legendItem(_legendBar(AppColors.muted), 'Garis tegak acuan (putus-putus)'),
      ],
    );
  }

  Widget _buildRiskCard(Map<String, dynamic> result) {
    final String? level = result['risk_level']?.toString();
    final dynamic rawScore = result['risk_score'];
    final double? score = rawScore is num ? rawScore.toDouble() : null;

    return AppCard(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Tingkat risiko', style: ts(13, color: AppColors.muted, height: 18)),
                    const SizedBox(height: 2),
                    Text(
                      level ?? '-',
                      style: ts(32, weight: FontWeight.w800, color: riskColor(level), height: 38),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('Skor risiko', style: ts(13, color: AppColors.muted, height: 18)),
                  const SizedBox(height: 2),
                  Text(formatPercent(score), style: ts(32, weight: FontWeight.w800, height: 38)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          RiskScale(score: score),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: riskTint(level),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(riskSummary(level), style: ts(14, height: 21)),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Hasil model', style: ts(13, color: AppColors.muted, height: 18)),
              ),
              Text(
                result['label']?.toString() ?? '-',
                style: ts(13, weight: FontWeight.w700, height: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Keyakinan model', style: ts(13, color: AppColors.muted, height: 18)),
              ),
              Text(
                formatPercent(result['confidence']),
                style: ts(13, weight: FontWeight.w700, height: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNotes(Map<String, dynamic> result) {
    final List<String> notes = <String>[];
    if (result['needs_review'] == true) {
      notes.add('Keyakinan model rendah. Sebaiknya ulangi dengan foto yang lebih jelas.');
    }
    if (result['background_removed'] == false) {
      notes.add(
        'Latar belakang foto tidak berhasil dihapus, jadi hasil bisa kurang akurat. '
        'Coba foto dengan latar polos dan seluruh punggung terlihat.',
      );
    }
    final List<Widget> widgets = <Widget>[];
    for (final String note in notes) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.amberTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            note,
            style: ts(13, weight: FontWeight.w600, color: AppColors.amber, height: 19),
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildMeasurements(Map<String, dynamic> result) {
    final dynamic raw = result['posture_features'];
    final List<FeatureInfo> items = <FeatureInfo>[];
    if (raw is Map) {
      raw.forEach((dynamic key, dynamic value) {
        items.add(describeFeature(key.toString(), value));
      });
    }
    if (items.isEmpty) return <Widget>[];

    return <Widget>[
      const SizedBox(height: 20),
      const SectionTitle('Yang terukur'),
      const SizedBox(height: 10),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < items.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: i == items.length - 1
                      ? null
                      : const Border(bottom: BorderSide(color: AppColors.lineSoft)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            items[i].title,
                            style: ts(14, weight: FontWeight.w700, height: 20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].description,
                            style: ts(13, color: AppColors.muted, height: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(items[i].value, style: ts(18, weight: FontWeight.w800, height: 24)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

/// Skala Rendah | Sedang | Tinggi dengan penanda di posisi skor.
class RiskScale extends StatelessWidget {
  const RiskScale({super.key, required this.score});

  final double? score;

  Widget _bar(Color color) {
    return Container(
      height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int lowFlex = (riskLowMax * 100).round();
    final int midFlex = ((riskMidMax - riskLowMax) * 100).round();
    final int highFlex = 100 - lowFlex - midFlex;
    final double? value = score;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double markerLeft =
                value == null ? 0.0 : width * value.clamp(0.0, 1.0).toDouble() - 10;
            return SizedBox(
              height: 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 5,
                    child: Row(
                      children: <Widget>[
                        Expanded(flex: lowFlex, child: _bar(AppColors.teal)),
                        const SizedBox(width: 3),
                        Expanded(flex: midFlex, child: _bar(AppColors.amberBar)),
                        const SizedBox(width: 3),
                        Expanded(flex: highFlex, child: _bar(AppColors.red)),
                      ],
                    ),
                  ),
                  if (value != null)
                    Positioned(
                      left: markerLeft,
                      top: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(color: AppColors.ink, spreadRadius: 1),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              flex: lowFlex,
              child: Text('Rendah', style: ts(12, color: AppColors.muted, height: 16)),
            ),
            Expanded(
              flex: midFlex,
              child: Text(
                'Sedang',
                textAlign: TextAlign.center,
                style: ts(12, color: AppColors.muted, height: 16),
              ),
            ),
            Expanded(
              flex: highFlex,
              child: Text(
                'Tinggi',
                textAlign: TextAlign.right,
                style: ts(12, color: AppColors.muted, height: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FeatureInfo {
  const FeatureInfo(this.title, this.description, this.value);

  final String title;
  final String description;
  final String value;
}

/// Mengubah nama fitur dari server (misalnya "tilt_shoulder_deg") menjadi
/// judul, penjelasan, dan nilai yang mudah dibaca.
/// Tanda nilai mengikuti notebook: kemiringan positif = sisi kanan foto lebih rendah,
/// condong positif = ke kanan foto.
FeatureInfo describeFeature(String key, dynamic raw) {
  final double? v = raw is num ? raw.toDouble() : null;
  final String degrees = v == null ? '-' : '${formatNumber(v.abs(), 1)}°';
  final String percent = v == null ? '-' : '${formatNumber(v * 100, 1)}%';

  if (key == 'tilt_diff_top_bottom_deg') {
    return FeatureInfo(
      'Selisih kemiringan atas dan bawah',
      'Beda kemiringan garis kiri-kanan teratas dan terbawah',
      degrees,
    );
  }
  if (key.startsWith('tilt_') && key.endsWith('_deg') && key.length > 9) {
    final String name = key.substring(5, key.length - 4).replaceAll('_', ' ');
    String description = 'Hampir sejajar';
    if (v != null && v.abs() >= 0.5) {
      description = v > 0 ? 'Sisi kanan foto lebih rendah' : 'Sisi kiri foto lebih rendah';
    }
    return FeatureInfo('Kemiringan $name', description, degrees);
  }
  if (key == 'trunk_lean_deg') {
    String description = 'Hampir tegak';
    if (v != null && v.abs() >= 0.5) {
      description =
          v > 0 ? 'Sumbu tubuh condong ke kanan foto' : 'Sumbu tubuh condong ke kiri foto';
    }
    return FeatureInfo('Kemiringan sumbu tubuh', description, degrees);
  }
  if (key == 'curve_angle_deg') {
    return FeatureInfo(
      'Sudut lengkung sumbu tubuh',
      'Beda arah terbesar antarbagian sumbu tubuh',
      degrees,
    );
  }
  if (key == 'lateral_dev_max_abs') {
    return FeatureInfo(
      'Simpangan samping terbesar',
      'Jarak terjauh sumbu tubuh dari garis lurus, dibanding panjang sumbu',
      percent,
    );
  }
  if (key == 'lateral_dev_range') {
    return FeatureInfo(
      'Rentang simpangan samping',
      'Besar kalau sumbu tubuh melengkung ke dua arah',
      percent,
    );
  }
  return FeatureInfo(
    key.replaceAll('_', ' '),
    'Nilai dari model',
    v == null ? raw.toString() : formatNumber(v, 2),
  );
}

// ---------------------------------------------------------------------------
// Titik pengukuran di atas foto
// ---------------------------------------------------------------------------

/// Satu titik tubuh dari server. [pos] berupa pecahan 0-1 dari lebar dan tinggi foto.
class MeasuredPoint {
  const MeasuredPoint(this.name, this.pos, this.conf);

  final String name;
  final Offset pos;
  final double conf;
}

/// Membaca "keypoints" dari jawaban server. Kalau ada satu saja yang bentuknya
/// tidak sesuai, hasilnya daftar kosong supaya nomor titik tidak bergeser.
List<MeasuredPoint> parseKeypoints(dynamic raw) {
  if (raw is! List) return const <MeasuredPoint>[];
  final List<MeasuredPoint> out = <MeasuredPoint>[];
  for (final dynamic item in raw) {
    if (item is! Map) return const <MeasuredPoint>[];
    final dynamic x = item['x'];
    final dynamic y = item['y'];
    final dynamic conf = item['conf'];
    if (x is! num || y is! num) return const <MeasuredPoint>[];
    out.add(MeasuredPoint(
      item['name']?.toString() ?? 'titik ${out.length + 1}',
      Offset(x.toDouble(), y.toDouble()),
      conf is num ? conf.toDouble() : 1.0,
    ));
  }
  return out;
}

/// Membaca "overlay.pairs": pasangan nomor titik kiri-kanan yang dihubungkan garis.
List<List<int>> parsePairs(dynamic raw, int pointCount) {
  final List<List<int>> out = <List<int>>[];
  if (raw is! List) return out;
  for (final dynamic item in raw) {
    if (item is! List || item.length != 2) continue;
    final dynamic a = item[0];
    final dynamic b = item[1];
    if (a is! int || b is! int) continue;
    if (a < 0 || b < 0 || a >= pointCount || b >= pointCount) continue;
    out.add(<int>[a, b]);
  }
  return out;
}

/// Membaca "overlay.axis": titik-titik sumbu tubuh berurutan dari atas ke bawah.
List<Offset> parseAxis(dynamic raw) {
  final List<Offset> out = <Offset>[];
  if (raw is! List) return out;
  for (final dynamic item in raw) {
    if (item is! List || item.length != 2) continue;
    final dynamic x = item[0];
    final dynamic y = item[1];
    if (x is! num || y is! num) continue;
    out.add(Offset(x.toDouble(), y.toDouble()));
  }
  return out;
}

class MeasurementPainter extends CustomPainter {
  MeasurementPainter({
    required this.points,
    required this.pairs,
    required this.axis,
  });

  final List<MeasuredPoint> points;
  final List<List<int>> pairs;
  final List<Offset> axis;

  /// Sama dengan kpt_conf di server: di bawah ini titik dianggap kurang yakin.
  static const double minConf = 0.5;

  static const Color pointColor = Color(0xFF00E676);
  static const Color weakColor = Color(0xFFBDBDBD);
  static const Color pairColor = Color(0xFFFFA726);
  static const Color axisColor = Color(0xFF00E5FF);

  @override
  void paint(Canvas canvas, Size size) {
    Offset px(Offset p) => Offset(p.dx * size.width, p.dy * size.height);

    // Tiap garis digambar dua kali (bayangan gelap lalu warna) supaya terlihat
    // di foto terang maupun gelap.
    void line(Offset a, Offset b, Color color, double width) {
      final Paint shadow = Paint()
        ..color = Colors.black54
        ..strokeWidth = width + 2
        ..strokeCap = StrokeCap.round;
      final Paint paint = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, shadow);
      canvas.drawLine(a, b, paint);
    }

    // 1. Garis pasangan kiri-kanan (misalnya bahu kiri ke bahu kanan)
    for (final List<int> pair in pairs) {
      final MeasuredPoint a = points[pair[0]];
      final MeasuredPoint b = points[pair[1]];
      final bool sure = a.conf > minConf && b.conf > minConf;
      line(px(a.pos), px(b.pos), sure ? pairColor : weakColor, 2);
    }

    // 2. Garis tegak acuan dan sumbu tubuh
    if (axis.length >= 2) {
      final Offset top = px(axis.first);
      final Offset bottom = px(axis.last);
      final Paint dashShadow = Paint()
        ..color = Colors.black54
        ..strokeWidth = 3;
      final Paint dash = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5;
      final double yStart = top.dy < bottom.dy ? top.dy : bottom.dy;
      final double yEnd = top.dy < bottom.dy ? bottom.dy : top.dy;
      for (double y = yStart; y < yEnd; y += 12) {
        final double y2 = y + 6 < yEnd ? y + 6 : yEnd;
        canvas.drawLine(Offset(top.dx, y), Offset(top.dx, y2), dashShadow);
        canvas.drawLine(Offset(top.dx, y), Offset(top.dx, y2), dash);
      }

      for (int i = 0; i < axis.length - 1; i++) {
        line(px(axis[i]), px(axis[i + 1]), axisColor, 3);
      }
      final Paint node = Paint()..color = axisColor;
      final Paint nodeEdge = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (final Offset p in axis) {
        canvas.drawCircle(px(p), 3.5, node);
        canvas.drawCircle(px(p), 3.5, nodeEdge);
      }
    }

    // 3. Titik tubuh dan nomornya
    final Paint ring = Paint()..color = Colors.white;
    final Paint edge = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < points.length; i++) {
      final Offset c = px(points[i].pos);
      final Paint fill = Paint()
        ..color = points[i].conf > minConf ? pointColor : weakColor;
      canvas.drawCircle(c, 6, ring);
      canvas.drawCircle(c, 6, edge);
      canvas.drawCircle(c, 4, fill);

      final TextPainter label = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: <Shadow>[
              Shadow(color: Colors.black, blurRadius: 3),
              Shadow(color: Colors.black, blurRadius: 3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Nomor di kanan-atas titik; digeser ke kiri kalau mentok tepi kanan foto.
      double dx = c.dx + 7;
      if (dx + label.width > size.width) dx = c.dx - 7 - label.width;
      double dy = c.dy - 7 - label.height;
      if (dy < 0) dy = c.dy + 7;
      label.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant MeasurementPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 4. Riwayat
// ---------------------------------------------------------------------------

class RiwayatTab extends StatelessWidget {
  const RiwayatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (BuildContext context, Widget? child) {
        final List<ScreeningRecord> records = appData.records;
        // Grafik: paling banyak 6 screening terakhir, urut dari yang lama ke yang baru.
        final List<ScreeningRecord> chart = records.take(6).toList().reversed.toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text('Riwayat', style: ts(24, weight: FontWeight.w800, height: 30)),
            const SizedBox(height: 20),
            if (records.isEmpty)
              _buildEmpty(context)
            else ...<Widget>[
              AppCard(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Expanded(child: SectionTitle('Skor risiko')),
                        Text(
                          '${chart.length} screening terakhir',
                          style: ts(13, color: AppColors.muted, height: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 152,
                      child: CustomPaint(painter: RiskChartPainter(records: chart)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Semua screening'),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < records.length; i++)
                      _buildRow(context, records[i], i == records.length - 1),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IconTile(icon: Icons.history),
          const SizedBox(height: 12),
          Text('Belum ada riwayat', style: ts(16, weight: FontWeight.w800, height: 22)),
          const SizedBox(height: 4),
          Text(
            'Setelah screening, tekan "Simpan ke riwayat" supaya hasilnya tercatat di sini dan perubahannya bisa dipantau.',
            style: ts(14, color: AppColors.muted, height: 20),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => openGuide(context),
            style: primaryButtonStyle(height: 48, fullWidth: false),
            child: const Text('Mulai screening'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, ScreeningRecord record, bool isLast) {
    return InkWell(
      onTap: () => openRecord(context, record),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.lineSoft)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                formatDate(record.date),
                style: ts(14, weight: FontWeight.w700, height: 20),
              ),
            ),
            RiskChip(level: record.riskLevel),
            const SizedBox(width: 10),
            SizedBox(
              width: 44,
              child: Text(
                formatPercent(record.riskScore),
                textAlign: TextAlign.right,
                style: ts(15, weight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Grafik garis skor risiko dengan dua garis batas tingkat risiko.
class RiskChartPainter extends CustomPainter {
  RiskChartPainter({required this.records});

  final List<ScreeningRecord> records; // urut dari yang lama ke yang baru

  // alignX: 0 = teks mulai di titik, 0.5 = teks di tengah titik, 1 = teks berakhir di titik
  void _text(Canvas canvas, String text, Offset anchor, TextStyle style, double alignX) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(anchor.dx - painter.width * alignX, anchor.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double chartTop = 10;
    final double chartBottom = size.height - 22;
    const double chartLeft = 20;
    final double chartRight = size.width - 62;

    double yOf(double score) {
      return chartBottom - score.clamp(0.0, 1.0).toDouble() * (chartBottom - chartTop);
    }

    final TextStyle small = ts(11, weight: FontWeight.w600, color: AppColors.muted);

    // Garis dasar dan garis batas tingkat risiko
    final Paint baseLine = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, chartBottom), Offset(size.width, chartBottom), baseLine);

    final Paint threshold = Paint()
      ..color = const Color(0xFFB9C6C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final double limit in <double>[riskLowMax, riskMidMax]) {
      final Path dashLine = Path();
      dashLine.moveTo(0, yOf(limit));
      dashLine.lineTo(size.width, yOf(limit));
      drawDashedPath(canvas, dashLine, threshold, 4, 5);
    }
    _text(canvas, 'Tinggi', Offset(size.width, yOf((1 + riskMidMax) / 2) - 7), small, 1);
    _text(canvas, 'Sedang', Offset(size.width, yOf((riskLowMax + riskMidMax) / 2) - 7), small, 1);
    _text(canvas, 'Rendah', Offset(size.width, yOf(riskLowMax / 2) - 7), small, 1);

    // Titik data
    final List<Offset> dots = <Offset>[];
    double? lastScore;
    for (int i = 0; i < records.length; i++) {
      final double x = records.length == 1
          ? (chartLeft + chartRight) / 2
          : chartLeft + (chartRight - chartLeft) * i / (records.length - 1);
      _text(canvas, formatDayMonth(records[i].date), Offset(x, chartBottom + 6), small, 0.5);
      final double? score = records[i].riskScore;
      if (score == null) continue;
      dots.add(Offset(x, yOf(score)));
      lastScore = score;
    }
    if (dots.isEmpty) return;

    final Paint linePaint = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path dataLine = Path();
    dataLine.moveTo(dots.first.dx, dots.first.dy);
    for (int i = 1; i < dots.length; i++) {
      dataLine.lineTo(dots[i].dx, dots[i].dy);
    }
    canvas.drawPath(dataLine, linePaint);

    final Paint white = Paint()..color = Colors.white;
    final Paint tealFill = Paint()..color = AppColors.teal;
    for (int i = 0; i < dots.length; i++) {
      if (i == dots.length - 1) {
        canvas.drawCircle(dots[i], 7, white);
        canvas.drawCircle(dots[i], 5.5, tealFill);
      } else {
        canvas.drawCircle(dots[i], 5.5, tealFill);
        canvas.drawCircle(dots[i], 3, white);
      }
    }

    // Nilai screening terbaru ditulis di dekat titiknya
    final Offset lastDot = dots.last;
    final double labelY = lastDot.dy - 26 > 0 ? lastDot.dy - 26 : lastDot.dy + 10;
    _text(
      canvas,
      formatPercent(lastScore),
      Offset(lastDot.dx, labelY),
      ts(12, weight: FontWeight.w800),
      0.5,
    );
  }

  @override
  bool shouldRepaint(covariant RiskChartPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 5. Edukasi
// ---------------------------------------------------------------------------

class Article {
  const Article({
    required this.title,
    required this.shortTitle,
    required this.summary,
    required this.icon,
    required this.body,
  });

  final String title;
  final String shortTitle;
  final String summary;
  final IconData icon;
  final List<String> body; // baris yang diawali "- " ditampilkan sebagai butir daftar
}

const List<Article> articles = <Article>[
  Article(
    title: 'Apa itu skoliosis?',
    shortTitle: 'Apa itu skoliosis?',
    summary: 'Tulang belakang yang melengkung ke samping, dan kenapa penting dikenali sejak dini.',
    icon: Icons.menu_book_outlined,
    body: <String>[
      'Skoliosis adalah kondisi tulang belakang yang melengkung ke samping, sering kali disertai putaran ruas tulang belakang. Dilihat dari belakang, tulang belakang biasanya tampak lurus. Pada skoliosis, bentuknya bisa menyerupai huruf C atau S.',
      'Skoliosis bisa muncul pada usia berapa pun, tetapi paling sering ditemukan pada masa pertumbuhan remaja. Pada sebagian besar kasus penyebab pastinya tidak diketahui. Jenis ini disebut skoliosis idiopatik.',
      'Banyak kasus tergolong ringan dan cukup dipantau secara berkala. Lengkung yang terus bertambah bisa memerlukan penanganan, misalnya penyangga (brace) atau operasi, sesuai penilaian dokter.',
      'Karena itu, mengenali tandanya lebih awal membantu dokter memantau dan menentukan penanganan pada waktu yang tepat.',
    ],
  ),
  Article(
    title: 'Tanda yang bisa dilihat di rumah',
    shortTitle: 'Tanda di rumah',
    summary: 'Bahu, tulang belikat, dan pinggul yang tidak sejajar',
    icon: Icons.visibility_outlined,
    body: <String>[
      'Minta orang yang diperiksa berdiri tegak membelakangi Anda, lalu perhatikan hal berikut:',
      '- Bahu kiri dan kanan tidak sama tinggi',
      '- Salah satu tulang belikat lebih menonjol',
      '- Lekuk pinggang tidak simetris, atau satu pinggul tampak lebih tinggi',
      '- Tubuh tampak condong ke satu sisi',
      '- Saat membungkuk ke depan, satu sisi punggung atau rusuk tampak lebih tinggi',
      'Tanda ini tidak selalu berarti skoliosis. Kebiasaan berdiri dan postur sehari-hari juga bisa membuat tubuh tampak tidak simetris. Yang bisa memastikannya adalah pemeriksaan dokter.',
    ],
  ),
  Article(
    title: 'Cara mengambil foto yang benar',
    shortTitle: 'Cara foto yang benar',
    summary: 'Posisi berdiri, jarak kamera, dan latar foto',
    icon: Icons.photo_camera_outlined,
    body: <String>[
      'Hasil screening sangat bergantung pada fotonya. Ikuti panduan ini setiap kali mengambil foto:',
      '- Minta orang lain memotret dari belakang',
      '- Punggung terlihat dari leher sampai pinggul, tidak tertutup baju atau rambut',
      '- Berdiri tegak dan rileks, kedua kaki sejajar, tangan di samping badan',
      '- Kamera tegak dan sejajar punggung, tidak miring atau dari atas',
      '- Pakai latar yang polos dan cahaya yang cukup',
      'Hindari pose lain, misalnya tangan diangkat atau badan menoleh. Pose seperti itu mengubah posisi bahu dan tulang belikat, sehingga skornya bisa tinggi walaupun tulang belakangnya normal.',
    ],
  ),
  Article(
    title: 'Cara membaca hasil screening',
    shortTitle: 'Membaca hasil',
    summary: 'Arti skor, tingkat risiko, dan titik pengukuran',
    icon: Icons.show_chart,
    body: <String>[
      'Skor risiko adalah perkiraan model tentang seberapa besar kemungkinan postur pada foto tidak tergolong normal. Skor ini bukan ukuran derajat lengkung tulang belakang.',
      'Di aplikasi ini skor di bawah 35% disebut rendah, 35% sampai 65% sedang, dan di atas 65% tinggi.',
      'Keyakinan model menunjukkan seberapa yakin model pada jawabannya. Kalau rendah, ulangi dengan foto yang lebih jelas.',
      'Titik pengukuran di atas foto adalah titik tubuh yang dikenali model. Garis kiri-kanan menghubungkan pasangan titik, misalnya kedua bahu. Sumbu tubuh menghubungkan titik tengahnya dari atas ke bawah.',
      'Periksa selalu posisi titiknya. Kalau titik tidak jatuh di bagian tubuh yang benar, hasilnya tidak bisa dipercaya dan fotonya perlu diulang.',
    ],
  ),
  Article(
    title: 'Kapan perlu ke dokter',
    shortTitle: 'Kapan ke dokter',
    summary: 'Langkah setelah hasil sedang atau tinggi',
    icon: Icons.local_hospital_outlined,
    body: <String>[
      'Pertimbangkan periksa ke dokter kalau:',
      '- Tanda seperti bahu atau pinggul tidak sejajar terlihat jelas, atau makin jelas dari waktu ke waktu',
      '- Hasil screening berulang kali sedang atau tinggi pada foto yang diambil dengan benar',
      '- Ada nyeri punggung yang menetap',
      '- Yang diperiksa anak atau remaja yang masih tumbuh dan tandanya terlihat',
      'Dokter biasanya melakukan pemeriksaan fisik dan, bila perlu, meminta rontgen untuk mengukur besar lengkungnya.',
      'Aplikasi ini tidak menggantikan pemeriksaan tersebut.',
    ],
  ),
];

class EdukasiTab extends StatelessWidget {
  const EdukasiTab({super.key});

  @override
  Widget build(BuildContext context) {
    final Article featured = articles[0];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('Edukasi', style: ts(24, weight: FontWeight.w800, height: 30)),
        const SizedBox(height: 20),
        Material(
          color: AppColors.tealTint,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openArticle(context, featured),
            child: Stack(
              children: <Widget>[
                const Positioned(
                  right: 16,
                  top: 8,
                  child: CustomPaint(size: Size(72, 150), painter: SpineMotifPainter()),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Mulai dari sini',
                          style: ts(
                            12,
                            weight: FontWeight.w700,
                            color: AppColors.tealDark,
                            height: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 230),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              featured.title,
                              style: ts(20, weight: FontWeight.w800, height: 26),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              featured.summary,
                              style: ts(14, color: AppColors.inkSoft, height: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Baca',
                            style: ts(14, weight: FontWeight.w700, color: AppColors.tealDark),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.tealDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Topik'),
        const SizedBox(height: 10),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (int i = 1; i < articles.length; i++)
                _buildTopic(context, articles[i], i == articles.length - 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopic(BuildContext context, Article article, bool isLast) {
    return InkWell(
      onTap: () => openArticle(context, article),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.lineSoft)),
        ),
        child: Row(
          children: <Widget>[
            IconTile(
              icon: article.icon,
              background: isLast ? AppColors.amberTint : AppColors.tealTint,
              foreground: isLast ? AppColors.amber : AppColors.teal,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(article.title, style: ts(14, weight: FontWeight.w700, height: 20)),
                  const SizedBox(height: 2),
                  Text(article.summary, style: ts(13, color: AppColors.muted, height: 18)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Hiasan kartu edukasi: ruas tulang belakang yang sedikit melengkung.
class SpineMotifPainter extends CustomPainter {
  const SpineMotifPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dashed = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final Path axis = Path();
    axis.moveTo(36, 6);
    axis.cubicTo(28, 34, 46, 58, 38, 84);
    axis.cubicTo(32, 104, 40, 124, 36, 146);
    drawDashedPath(canvas, axis, dashed, 2, 9);

    final Paint bone = Paint()
      ..color = AppColors.teal
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    const List<List<double>> bones = <List<double>>[
      <double>[24, 44, 18],
      <double>[27, 49, 38],
      <double>[30, 52, 58],
      <double>[28, 48, 78],
      <double>[24, 44, 98],
      <double>[26, 46, 118],
      <double>[26, 46, 138],
    ];
    for (final List<double> b in bones) {
      canvas.drawLine(Offset(b[0], b[2]), Offset(b[1], b[2]), bone);
    }
  }

  @override
  bool shouldRepaint(covariant SpineMotifPainter oldDelegate) => false;
}

class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key, required this.article});

  final Article article;

  Widget _buildLine(String line) {
    if (!line.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(line, style: ts(15, height: 23)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 9, left: 4, right: 12),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
            ),
          ),
          Expanded(child: Text(line.substring(2), style: ts(15, height: 23))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: CircleIconButton(
                icon: Icons.arrow_back,
                label: 'Kembali',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: IconTile(icon: article.icon),
            ),
            const SizedBox(height: 12),
            Text(article.title, style: ts(24, weight: FontWeight.w800, height: 30)),
            const SizedBox(height: 16),
            for (final String line in article.body) _buildLine(line),
            const SizedBox(height: 8),
            Text(
              'Informasi umum, bukan nasihat medis.',
              style: ts(12, color: AppColors.muted, height: 17),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profil
// ---------------------------------------------------------------------------

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