import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_config.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/image_crop.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../data/content/articles.dart';
import '../../data/models/analysis_outcome.dart';
import '../../data/services/screening_api.dart';
import '../result/result_screen.dart';
import 'widgets/photo_guide_sheet.dart';
import 'widgets/silhouette_guide_painter.dart';

class PanduanScreen extends StatefulWidget {
  const PanduanScreen({super.key});

  @override
  State<PanduanScreen> createState() => _PanduanScreenState();
}

class _PanduanScreenState extends State<PanduanScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();

  // Kamera di dalam aplikasi
  List<CameraDescription> _cameras = <CameraDescription>[];
  CameraController? _controller;
  int _cameraIndex = -1;
  bool _startingCamera = false;
  String? _cameraProblem; // terisi kalau kamera di dalam aplikasi tidak bisa dipakai
  bool _flashReady = false; // flash wajib menyala saat memotret dari kamera aplikasi

  // Foto yang sedang diproses
  File? _image;
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Layar penuh seperti kamera bawaan: status bar dan tombol navigasi disembunyikan.
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startCamera();
    // Panduan foto selalu muncul setiap kali kamera dibuka.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _showGuide());
  }

  Future<void> _showGuide() async {
    if (!mounted) return;
    await showPhotoGuideSheet(
      context,
      onReadMore: () => openArticle(context, articles[2]),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Kembalikan status bar dan tombol navigasi seperti semula.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _controller?.dispose();
    super.dispose();
  }

  // Kamera dilepas saat aplikasi ke latar belakang dan dibuka lagi saat kembali.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      if (state == AppLifecycleState.resumed && controller == null) {
        _startCamera();
      }
      return;
    }
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller = null;
      controller.dispose();
      if (mounted) {
        setState(() {});
      }
    }
  }

  bool get _cameraReady {
    final CameraController? controller = _controller;
    return controller != null && controller.value.isInitialized;
  }

  bool get _canSwitchCamera {
    final bool hasBack =
        _cameras.any((CameraDescription c) => c.lensDirection == CameraLensDirection.back);
    final bool hasFront =
        _cameras.any((CameraDescription c) => c.lensDirection == CameraLensDirection.front);
    return hasBack && hasFront;
  }

  Future<void> _startCamera() async {
    if (_startingCamera) return;
    _startingCamera = true;
    CameraController? fresh;
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }
      if (_cameras.isEmpty) {
        throw CameraException('NoCamera', 'Tidak ada kamera');
      }
      if (_cameraIndex < 0 || _cameraIndex >= _cameras.length) {
        final int back = _cameras
            .indexWhere((CameraDescription c) => c.lensDirection == CameraLensDirection.back);
        _cameraIndex = back >= 0 ? back : 0;
      }

      final CameraController? old = _controller;
      _controller = null;
      if (old != null) {
        await old.dispose();
      }

      fresh = CameraController(_cameras[_cameraIndex], ResolutionPreset.high, enableAudio: false);
      await fresh.initialize();
      try {
        // Foto selalu tegak walaupun HP dimiringkan.
        await fresh.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {
        // Tidak didukung di perangkat ini: lanjut tanpa mengunci.
      }
      final bool flashReady = await _enableFlash(fresh);
      if (!mounted) {
        await fresh.dispose();
        return;
      }
      final CameraController ready = fresh;
      setState(() {
        _controller = ready;
        _flashReady = flashReady;
        _cameraProblem = null;
      });
    } on CameraException catch (e) {
      fresh?.dispose();
      if (!mounted) return;
      setState(() {
        _controller = null;
        _cameraProblem = _describeCameraError(e);
      });
    } catch (_) {
      fresh?.dispose();
      if (!mounted) return;
      setState(() {
        _controller = null;
        _cameraProblem =
            'Kamera di dalam aplikasi tidak bisa dibuka. Tombol bulat akan membuka kamera bawaan HP.';
      });
    } finally {
      _startingCamera = false;
    }
  }

  // Flash dipaksa menyala setiap memotret supaya pencahayaan foto seragam.
  // Kamera depan umumnya tidak punya flash, jadi dianggap tidak siap.
  Future<bool> _enableFlash(CameraController controller) async {
    if (controller.description.lensDirection == CameraLensDirection.front) return false;
    try {
      await controller.setFlashMode(FlashMode.always);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _describeCameraError(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'Izin kamera ditolak. Izinkan kamera untuk aplikasi ini di pengaturan HP, atau pilih foto dari galeri.';
      case 'NoCamera':
        return 'Kamera tidak ditemukan di perangkat ini. Pilih foto dari galeri.';
      default:
        return 'Kamera di dalam aplikasi tidak bisa dibuka. Tombol bulat akan membuka kamera bawaan HP.';
    }
  }

  Future<void> _switchCamera() async {
    if (_isLoading || _startingCamera || !_canSwitchCamera || _cameraIndex < 0) return;
    final CameraLensDirection target =
        _cameras[_cameraIndex].lensDirection == CameraLensDirection.back
            ? CameraLensDirection.front
            : CameraLensDirection.back;
    final int next = _cameras.indexWhere((CameraDescription c) => c.lensDirection == target);
    if (next < 0) return;
    _cameraIndex = next;
    await _startCamera();
  }

  // Tombol bulat: memotret lewat kamera di dalam aplikasi. Kalau kamera itu tidak
  // tersedia, kamera bawaan HP dibuka sebagai cadangan.
  Future<void> _capture() async {
    if (_isLoading) return;
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      await _pickFrom(ImageSource.camera);
      return;
    }
    if (controller.value.isTakingPicture) return;
    if (!_flashReady) {
      setState(() {
        _message = _canSwitchCamera
            ? 'Foto wajib memakai flash. Kamera ini tidak punya flash; ganti ke kamera belakang.'
            : 'Foto wajib memakai flash, tapi flash HP ini tidak bisa dinyalakan. Pilih foto dari galeri.';
      });
      return;
    }
    setState(() {
      _message = null;
      _isLoading = true;
    });
    try {
      // Dipasang lagi tepat sebelum memotret: beberapa HP mengembalikan mode flash ke awal.
      await controller.setFlashMode(FlashMode.always);
      final XFile shot = await controller.takePicture();
      // Foto dipotong sama dengan bingkai di layar, jadi yang dikirim = yang terlihat.
      final File file = await cropToAspect(File(shot.path), photoAspect);
      await _analyze(file);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _image = null;
        _message = 'Gagal mengambil foto: $e';
      });
    }
  }

  Future<void> _pickFrom(ImageSource source) async {
    if (_isLoading) return;
    try {
      final XFile? picked = await _picker.pickImage(source: source);
      if (picked == null || !mounted) return;
      await _analyze(File(picked.path));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _image = null;
        _message = 'Gagal mengambil gambar: $e';
      });
    }
  }

  Future<void> _analyze(File file) async {
    if (!mounted) return;
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
    // Gagal: kembali ke kamera supaya bisa langsung foto ulang.
    setState(() {
      _isLoading = false;
      _image = null;
      _message = outcome.notice ?? outcome.error ?? 'Gambar tidak bisa dianalisis.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? message = _message ?? _cameraProblem;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTopBar(),
              // Bingkai foto selebar layar (3:4), seperti mode 3:4 di kamera bawaan HP.
              // Yang terlihat di bingkai = yang dikirim ke server.
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: photoAspect,
                    child: _buildViewfinder(message),
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: <Widget>[
          CircleIconButton(
            icon: Icons.close,
            label: 'Tutup kamera',
            background: Colors.transparent,
            foreground: Colors.white,
            bordered: false,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Center(
              child: _cameraReady ? _buildFlashBadge() : const SizedBox.shrink(),
            ),
          ),
          CircleIconButton(
            icon: Icons.info_outline,
            label: 'Cara mengambil foto yang benar',
            background: Colors.transparent,
            foreground: Colors.white,
            bordered: false,
            onTap: _showGuide,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Difoto orang lain dari belakang, jarak ±1 meter, HP setinggi tengah punggung.',
            textAlign: TextAlign.center,
            style: ts(12, color: AppColors.darkMuted, height: 17),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildSquareButton(
                icon: Icons.photo_library_outlined,
                label: 'Pilih foto dari galeri',
                onTap: _isLoading ? null : () => _pickFrom(ImageSource.gallery),
              ),
              _buildShutter(),
              if (_cameraReady && _canSwitchCamera)
                _buildSquareButton(
                  icon: Icons.cameraswitch_outlined,
                  label: 'Ganti kamera depan atau belakang',
                  onTap: _isLoading ? null : _switchCamera,
                )
              else
                const SizedBox(width: 52, height: 52),
            ],
          ),
        ],
      ),
    );
  }

  // Bingkai foto: pratinjau kamera langsung, dengan kerangka punggung di atasnya.
  Widget _buildViewfinder(String? message) {
    final File? image = _image;
    final CameraController? controller = _controller;
    final Widget? preview = image != null
        ? Image.file(image, fit: BoxFit.cover)
        : (controller != null && controller.value.isInitialized
            ? _buildLivePreview(controller)
            : null);
    final bool live = image == null && preview != null;
    return Container(
      color: AppColors.darkSurface,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (preview != null) preview,
          if (image == null) const CustomPaint(painter: SilhouetteGuidePainter()),
          if (image == null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: live ? const Color(0x99000000) : AppColors.tealTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  live
                      ? 'Leher sampai pinggul di dalam garis · kepala tidak perlu'
                      : (_startingCamera ? 'Membuka kamera' : 'Contoh posisi'),
                  style: ts(
                    12,
                    weight: FontWeight.w700,
                    color: live ? Colors.white : AppColors.tealDark,
                    height: 16,
                  ),
                ),
              ),
            ),
          if (message != null && !_isLoading)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(12),
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
                    image == null ? 'Mengambil foto' : 'Sedang menganalisis',
                    textAlign: TextAlign.center,
                    style: ts(16, weight: FontWeight.w700, color: Colors.white, height: 22),
                  ),
                  if (image != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Permintaan pertama bisa memakan waktu sekitar satu menit.',
                      textAlign: TextAlign.center,
                      style: ts(13, color: AppColors.darkMuted, height: 19),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Pratinjau kamera mengisi bingkai dan dipotong di tengah, sama seperti hasil fotonya.
  Widget _buildLivePreview(CameraController controller) {
    final Size? preview = controller.value.previewSize;
    if (preview == null) {
      return CameraPreview(controller);
    }
    // previewSize dilaporkan dalam posisi mendatar, jadi lebar dan tingginya ditukar.
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: preview.height,
        height: preview.width,
        child: CameraPreview(controller),
      ),
    );
  }

  // Penanda di bagian atas: flash menyala atau tidak tersedia.
  Widget _buildFlashBadge() {
    final bool on = _flashReady;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: on ? const Color(0xE6FFD54F) : AppColors.amberTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(on ? Icons.flash_on : Icons.flash_off, size: 16, color: AppColors.ink),
          const SizedBox(width: 4),
          Text(
            on ? 'Flash wajib: menyala' : 'Flash tidak tersedia',
            style: ts(12, weight: FontWeight.w700, color: AppColors.ink, height: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, size: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildShutter() {
    return Semantics(
      button: true,
      label: 'Ambil foto',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 4)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isLoading ? null : _capture,
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