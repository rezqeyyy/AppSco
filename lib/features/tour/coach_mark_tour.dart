import 'package:flutter/material.dart' hide Text;

import '../../core/i18n/tr_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import 'ansco.dart';
import 'coach_step.dart';
import 'widgets/spotlight_painter.dart';

/// Tur sorotan bersama maskot AnSco.
///
/// Urutannya: perkenalan AnSco → tiap bagian layar disorot dan dijelaskan AnSco
/// (pose tangannya menunjuk ke arah bagian yang disorot) → penutup.
class CoachMarkTour extends StatefulWidget {
  const CoachMarkTour({super.key, required this.steps, required this.onFinish});

  final List<CoachStep> steps;
  final VoidCallback onFinish;

  @override
  State<CoachMarkTour> createState() => _CoachMarkTourState();
}

class _CoachMarkTourState extends State<CoachMarkTour> with TickerProviderStateMixin {
  static const double _gap = 64; // ruang untuk panah antara sorotan dan kartu
  static const double _mascotHeight = 132; // tinggi AnSco di samping kartu langkah

  late final AnimationController _pulse;
  late final AnimationController _move;
  late final AnimationController _fade;

  // -1 = perkenalan, 0..n-1 = langkah tur, n = penutup.
  int _index = -1;
  Rect? _from; // posisi sorotan sebelum pindah ke langkah berikutnya
  Rect? _last; // posisi sorotan yang terakhir digambar
  bool _closing = false;
  bool _precached = false;

  bool get _isIntro => _index < 0;
  bool get _isOutro => _index >= widget.steps.length;
  CoachStep? get _step => (_isIntro || _isOutro) ? null : widget.steps[_index];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))
      ..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      precacheAnSco(context);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _move.dispose();
    _fade.dispose();
    super.dispose();
  }

  // Gulir layar kalau bagian yang disorot belum terlihat.
  void _reveal() {
    final BuildContext? target = _step?.target.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.35,
      );
    }
  }

  void _goTo(int index) {
    if (_closing || index < -1) return;
    if (index > widget.steps.length) {
      _finish();
      return;
    }
    setState(() {
      _from = _last;
      _index = index;
    });
    _move.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  Future<void> _finish() async {
    if (_closing) return;
    _closing = true;
    await _fade.reverse();
    widget.onFinish();
  }

  // Posisi bagian yang disorot, relatif terhadap layar tur ini.
  Rect? _targetRect() {
    final CoachStep? step = _step;
    if (step == null) return null;
    final RenderObject? target = step.target.currentContext?.findRenderObject();
    final RenderObject? self = context.findRenderObject();
    if (target is! RenderBox || self is! RenderBox) return null;
    if (!target.attached || !target.hasSize || !self.hasSize) return null;
    final Offset topLeft = target.localToGlobal(Offset.zero) - self.localToGlobal(Offset.zero);
    return (topLeft & target.size).inflate(step.padding);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_pulse, _move, _fade]),
        builder: (BuildContext context, Widget? child) {
          Rect? hole = _targetRect();
          final Rect? from = _from;
          if (hole != null && from != null && _move.isAnimating) {
            hole = Rect.lerp(from, hole, Curves.easeInOutCubic.transform(_move.value));
          }
          _last = hole;
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Opacity(
                opacity: _fade.value,
                child: _buildLayer(hole, constraints.biggest),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLayer(Rect? hole, Size size) {
    final double topInset = MediaQuery.of(context).padding.top;
    final bool cardAbove = hole != null && hole.center.dy > size.height * 0.5;
    final CoachStep? step = _step;
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _goTo(_index + 1),
            child: CustomPaint(
              painter: SpotlightPainter(
                hole: hole,
                radius: step == null ? 0 : step.radius + step.padding,
                pulse: _pulse.value,
                cardAbove: cardAbove,
                gap: _gap,
              ),
            ),
          ),
        ),
        if (_isIntro)
          Center(child: _buildSpeech(intro: true))
        else if (_isOutro)
          Center(child: _buildSpeech(intro: false))
        else if (hole != null)
          Positioned(
            left: 16,
            right: 12,
            top: cardAbove ? null : hole.bottom + _gap,
            bottom: cardAbove ? size.height - hole.top + _gap : null,
            child: _buildStepRow(cardAbove ? AnScoPose.bawah : AnScoPose.atas),
          )
        else
          Positioned(left: 16, right: 12, top: 0, bottom: 0, child: Center(child: _buildStepRow(AnScoPose.diam))),
        if (!_isOutro)
          Positioned(
            top: topInset + 8,
            right: 12,
            child: TextButton(
              onPressed: _finish,
              child: Text('Lewati', style: ts(14, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
      ],
    );
  }

  // Kartu penjelasan langkah + AnSco berdiri di sebelah kanannya.
  Widget _buildStepRow(AnScoPose pose) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(child: _buildStepCard()),
        const SizedBox(width: 4),
        AnScoFigure(pose: pose, height: _mascotHeight, bob: _pulse.value),
      ],
    );
  }

  Widget _buildStepCard() {
    final CoachStep step = _step!;
    final int total = widget.steps.length;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('AnSco', translate: false, style: ts(12, weight: FontWeight.w800, color: AppColors.teal, height: 16)),
                Text(
                  '  ·  ${_index + 1}/$total',
                  translate: false,
                  style: ts(12, weight: FontWeight.w600, color: AppColors.muted, height: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(step.title, style: ts(17, weight: FontWeight.w800, height: 22)),
            const SizedBox(height: 4),
            Text(step.body, style: ts(13.5, color: AppColors.inkSoft, height: 20)),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => _goTo(_index - 1),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: Text('Kembali', style: ts(14, weight: FontWeight.w700, color: AppColors.muted)),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => _goTo(_index + 1),
                  style: primaryButtonStyle(height: 42, fullWidth: false),
                  child: const Text('Lanjut'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Perkenalan dan penutup: AnSco besar di tengah dengan balon kata di bawahnya.
  Widget _buildSpeech({required bool intro}) {
    final String title = intro ? 'Hai, aku AnSco!' : 'Sudah siap!';
    final String body = intro
        ? 'Aku yang akan menemanimu mengecek postur punggung. '
            'Yuk, aku tunjukkan dulu cara memakai aplikasi ini. Cuma sebentar kok.'
                : 'Sekarang kamu sudah tahu semuanya. Coba screening pertamamu, '
                  'dan kalau bingung, ketuk kepalaku untuk tanya apa saja. Tur ini juga bisa dibuka lagi dari Profil.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnScoFigure(
              pose: intro ? AnScoPose.lambai : AnScoPose.tunjuk,
              height: 240,
              bob: _pulse.value,
            ),
            const SizedBox(height: 4),
            // Ekor kecil balon kata yang mengarah ke AnSco.
            CustomPaint(size: const Size(22, 11), painter: _BubbleTailPainter()),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: ts(20, weight: FontWeight.w800, height: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: ts(14, color: AppColors.inkSoft, height: 21),
                    ),
                    const SizedBox(height: 14),
                    if (intro)
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextButton(
                              onPressed: _finish,
                              child: Text('Nanti saja', style: ts(14, weight: FontWeight.w700, color: AppColors.muted)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _goTo(0),
                              style: primaryButtonStyle(height: 46),
                              child: const Text('Ayo mulai'),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextButton(
                              onPressed: () => _goTo(_index - 1),
                              child: Text('Kembali', style: ts(14, weight: FontWeight.w700, color: AppColors.muted)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: _finish,
                              style: primaryButtonStyle(height: 46),
                              child: const Text('Selesai'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}