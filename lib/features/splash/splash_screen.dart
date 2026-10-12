import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../state/app_data.dart';
import '../auth/login_screen.dart';
import '../shell/home_shell.dart';
import 'widgets/splash_logo_painter.dart';

/// Layar pembuka: logo digambar bertahap, nama aplikasi muncul, lalu pindah ke Beranda.
/// Pindahnya menunggu animasi selesai dan data riwayat selesai dimuat.
/// Ketuk layar untuk melewati animasi.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    // Kalau pengguna mematikan animasi di pengaturan HP, layar ini dibuat singkat.
    final bool reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reduceMotion ? 300 : 2400),
    );
    _controller.addStatusListener(_onStatus);
    appData.addListener(_goNextIfReady);
    _controller.forward();
  }

  @override
  void dispose() {
    appData.removeListener(_goNextIfReady);
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goNextIfReady();
    }
  }

  void _skip() {
    if (!_controller.isCompleted) {
      _controller.value = 1.0;
    }
  }

  // Selalu ke Beranda; tur sorotan untuk pengguna baru dimulai dari sana.
  void _goNextIfReady() {
    if (_left || !mounted) return;
    if (!_controller.isCompleted || !appData.loaded) return;
    _left = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) =>
            appData.authMode == null ? const LoginScreen() : const HomeShell(),
        transitionsBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // Posisi t di dalam rentang [start, end], hasilnya 0-1.
  static double _segment(double t, double start, double end) {
    return ((t - start) / (end - start)).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.teal,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skip,
          child: SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_controller, appData]),
              builder: (BuildContext context, Widget? child) {
                final double t = _controller.value;
                final double logoScale =
                    0.88 + 0.12 * Curves.easeOutBack.transform(_segment(t, 0.0, 0.4));
                final double titleT = Curves.easeOutCubic.transform(_segment(t, 0.55, 0.85));
                final double taglineT = Curves.easeOutCubic.transform(_segment(t, 0.65, 0.95));
                final bool waiting = _controller.isCompleted && !appData.loaded;

                // SizedBox.expand: kolom selebar layar, jadi isinya benar-benar di tengah.
                return SizedBox.expand(
                  child: Column(
                    children: <Widget>[
                      const Spacer(flex: 3),
                      Transform.scale(
                        scale: logoScale,
                        child: SizedBox(
                          width: 168,
                          height: 168,
                          child: CustomPaint(painter: SplashLogoPainter(progress: t)),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: titleT,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - titleT)),
                          child: Text(
                            'SkolioCek',
                            textAlign: TextAlign.center,
                            style: ts(34, weight: FontWeight.w800, color: Colors.white, height: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: taglineT,
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - taglineT)),
                          child: Text(
                            'Screening postur punggung',
                            textAlign: TextAlign.center,
                            style: ts(15, color: AppColors.tealPale, height: 22),
                          ),
                        ),
                      ),
                      const Spacer(flex: 4),
                      SizedBox(
                        height: 40,
                        child: waiting
                            ? const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Opacity(
                        opacity: taglineT,
                        child: Text(
                          'Alat screening awal, bukan diagnosis',
                          textAlign: TextAlign.center,
                          style: ts(12, color: AppColors.tealPale, height: 17),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}