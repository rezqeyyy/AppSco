import 'coach_step.dart';
import 'tour_keys.dart';

/// Urutan tur di Beranda.
final List<CoachStep> homeTourSteps = <CoachStep>[
  CoachStep(
    target: TourKeys.startScreening,
    radius: 24,
    title: 'Mulai screening',
    body: 'Tekan tombol ini untuk memotret punggung. Kamera akan menampilkan kerangka supaya posisi foto pas.',
  ),
  CoachStep(
    target: TourKeys.lastResult,
    title: 'Hasil terakhir',
    body: 'Hasil screening terbaru yang sudah disimpan muncul di sini. Ketuk untuk melihat detail dan titik pengukurannya.',
  ),
  CoachStep(
    target: TourKeys.learn,
    title: 'Pelajari',
    body: 'Bacaan singkat tentang skoliosis dan cara mengambil foto yang benar.',
  ),
  CoachStep(
    target: TourKeys.nav[1],
    padding: 2,
    radius: 12,
    title: 'Riwayat',
    body: 'Semua hasil yang disimpan, lengkap dengan grafik perubahan skornya dari waktu ke waktu.',
  ),
  CoachStep(
    target: TourKeys.nav[2],
    padding: 2,
    radius: 12,
    title: 'Edukasi',
    body: 'Artikel tentang tanda skoliosis, cara membaca hasil, dan kapan perlu ke dokter.',
  ),
  CoachStep(
    target: TourKeys.nav[3],
    padding: 2,
    radius: 12,
    title: 'Profil',
    body: 'Ubah nama, hapus riwayat, atau buka tur ini lagi kapan saja.',
  ),
];