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

  // Foto yang sedang diproses
  File? _image;
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      if (!mounted) {
        await fresh.dispose();
        return;
      }
      final CameraController ready = fresh;
      setState(() {
        _controller = ready;
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
    setState(() {
      _message = null;
      _isLoading = true;
    });
    try {
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
                _cameraReady
                    ? 'Posisikan punggung di dalam garis'
                    : 'Posisikan punggung seperti garis ini',
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
              Expanded(
                child: Center(
                  child: AspectRatio(aspectRatio: photoAspect, child: _buildViewfinder()),
                ),
              ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bingkai foto: pratinjau kamera langsung, dengan kerangka punggung di atasnya.
  Widget _buildViewfinder() {
    final File? image = _image;
    final CameraController? controller = _controller;
    final Widget? preview = image != null
        ? Image.file(image, fit: BoxFit.cover)
        : (controller != null && controller.value.isInitialized
            ? _buildLivePreview(controller)
            : null);
    final bool live = image == null && preview != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: AppColors.darkSurface,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (preview != null) preview,
            if (image == null) const CustomPaint(painter: SilhouetteGuidePainter()),
            if (image == null && !live)
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
                    _startingCamera ? 'Membuka kamera' : 'Contoh posisi',
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