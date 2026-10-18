import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import 'chat_screen.dart';

import 'dart:ui' as ui;

/// Navigator utama aplikasi, supaya kepala AnSco (yang ada di luar Navigator)
/// bisa membuka layar chat dari halaman mana pun.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
/// Penanda kepala AnSco, dipakai tutorial untuk menyorotnya.
final GlobalKey anscoHeadKey = GlobalKey(debugLabel: 'ansco-head');

/// Kapan kepala AnSco tampil.
class AnScoBubble extends ChangeNotifier {
  bool _enabled = false; // aktif setelah masuk ke halaman utama (bukan splash/login)
  bool _touring = false; // saat tutorial: tetap tampil (ikut disorot) tapi tidak bisa diketuk
  bool _chatOpen = false; // disembunyikan saat layar chat terbuka

  bool get visible => _enabled && !_chatOpen;
  bool get interactive => !_touring;

  set enabled(bool v) => _set(_enabled != v, () => _enabled = v);
  set touring(bool v) => _set(_touring != v, () => _touring = v);
  set chatOpen(bool v) => _set(_chatOpen != v, () => _chatOpen = v);

  void _set(bool changed, VoidCallback change) {
    if (!changed) return;
    change();
    notifyListeners();
  }
}

final AnScoBubble anscoBubble = AnScoBubble();

const String anscoHeadAsset = 'assets/mascot/ansco_kepala.png';

/// Kepala AnSco yang mengambang di pinggir layar. Bisa digeser; saat dilepas
/// menempel ke sisi kiri/kanan terdekat. Ketuk untuk membuka chat.
class FloatingAnSco extends StatefulWidget {
  const FloatingAnSco({super.key});

  @override
  State<FloatingAnSco> createState() => _FloatingAnScoState();
}

class _FloatingAnScoState extends State<FloatingAnSco> with SingleTickerProviderStateMixin {
  static const double _size = 80;
  static const double _margin = 10;
  static const String _keySide = 'ansco_sisi_kanan';
  static const String _keyY = 'ansco_posisi_y';

  bool _right = true; // menempel di sisi kanan
  double _yFrac = 0.62; // posisi vertikal, 0 = atas, 1 = bawah
  Offset? _drag; // posisi saat sedang digeser (kiri-atas)
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    anscoBubble.addListener(_changed);
    _restore();
  }

  @override
  void dispose() {
    anscoBubble.removeListener(_changed);
    _bob.dispose();
    super.dispose();
  }

  // Bisa dipicu saat halaman lain sedang dibangun/ditutup, jadi tunggu frame selesai.
  void _changed() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _restore() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool? right = prefs.getBool(_keySide);
      final double? y = prefs.getDouble(_keyY);
      if (!mounted) return;
      setState(() {
        if (right != null) _right = right;
        if (y != null) _yFrac = y.clamp(0.0, 1.0);
      });
    } catch (_) {}
  }

  Future<void> _store() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySide, _right);
      await prefs.setDouble(_keyY, _yFrac);
    } catch (_) {}
  }

  // Batas atas-bawah yang boleh ditempati (tidak menutupi status bar dan menu bawah).
  (double, double) _yRange(MediaQueryData mq) {
    final double top = mq.padding.top + 12;
    final double bottom = mq.size.height - mq.padding.bottom - _size - 96;
    return (top, math.max(top, bottom));
  }

  void _open() {
    final NavigatorState? nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute<void>(builder: (BuildContext context) => const ChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final bool keyboard = mq.viewInsets.bottom > 0;
    final bool show = anscoBubble.visible && !keyboard;
    final (double minY, double maxY) = _yRange(mq);
    final double w = mq.size.width;

    final Offset rest = Offset(
      _right ? w - _size - _margin : _margin,
      minY + (maxY - minY) * _yFrac,
    );
    final Offset pos = _drag ?? rest;

    return AnimatedPositioned(
      duration: _drag != null ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      left: pos.dx,
      top: pos.dy,
      child: IgnorePointer(
        ignoring: !show || !anscoBubble.interactive,
        child: AnimatedScale(
          scale: show ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: show ? Curves.easeOutBack : Curves.easeIn,
          child: GestureDetector(
            onTap: _open,
            onPanStart: (_) => setState(() => _drag = rest),
            onPanUpdate: (DragUpdateDetails d) {
              setState(() {
                final Offset next = (_drag ?? rest) + d.delta;
                _drag = Offset(
                  next.dx.clamp(0.0, w - _size),
                  next.dy.clamp(minY, maxY),
                );
              });
            },
            onPanEnd: (_) {
              final Offset p = _drag ?? rest;
              setState(() {
                _right = p.dx + _size / 2 > w / 2;
                _yFrac = maxY > minY ? ((p.dy - minY) / (maxY - minY)).clamp(0.0, 1.0) : 0;
                _drag = null;
              });
              _store();
            },
            child: AnimatedBuilder(
              animation: _bob,
              builder: (BuildContext context, Widget? child) => Transform.translate(
                offset: Offset(0, _drag != null ? 0 : -2.5 * math.sin(_bob.value * 2 * math.pi)),
                child: child,
              ),
              // Bukan Tooltip: widget ini ada di atas Navigator, jadi belum ada Overlay.
              child: Semantics(
                button: true,
                label: 'Chat dengan AnSco',
                child: SizedBox(
                  key: anscoHeadKey,
                  width: _size,
                  height: _size,
                  child: Stack(
                    children: <Widget>[
                      // Bayangan lembut dari bentuk kepala itu sendiri, supaya kepala putih
                      // tetap kelihatan di latar terang (bukan border/lingkaran).
                      Positioned.fill(
                        top: 4,
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(Color(0x55000000), BlendMode.srcIn),
                            child: Image.asset(anscoHeadAsset, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Image.asset(anscoHeadAsset, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}