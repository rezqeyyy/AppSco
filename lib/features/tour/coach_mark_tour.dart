import 'package:flutter/material.dart' hide Text;
import '../../core/i18n/tr_text.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import 'coach_step.dart';
import 'widgets/spotlight_painter.dart';

/// Tur sorotan: layar digelapkan kecuali bagian yang sedang dijelaskan,
/// lalu ada panah dan kartu penjelasan. Ketuk di mana saja untuk lanjut.
class CoachMarkTour extends StatefulWidget {
  const CoachMarkTour({super.key, required this.steps, required this.onFinish});

  final List<CoachStep> steps;
  final VoidCallback onFinish;

  @override
  State<CoachMarkTour> createState() => _CoachMarkTourState();
}

class _CoachMarkTourState extends State<CoachMarkTour> with TickerProviderStateMixin {
  static const double _gap = 64; // ruang untuk panah antara sorotan dan kartu

  late final AnimationController _pulse;
  late final AnimationController _move;
  late final AnimationController _fade;

  int _index = 0;
  Rect? _from; // posisi sorotan sebelum pindah ke langkah berikutnya
  Rect? _last; // posisi sorotan yang terakhir digambar
  bool _closing = false;

  CoachStep get _step => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))
      ..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
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
    final BuildContext? target = _step.target.currentContext;
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
    if (_closing || index < 0) return;
    if (index >= widget.steps.length) {
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
    final RenderObject? target = _step.target.currentContext?.findRenderObject();
    final RenderObject? self = context.findRenderObject();
    if (target is! RenderBox || self is! RenderBox) return null;
    if (!target.attached || !target.hasSize || !self.hasSize) return null;
    final Offset topLeft = target.localToGlobal(Offset.zero, ancestor: self);
    return (topLeft & target.size).inflate(_step.padding);
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
          if (hole != null) {
            _last = hole;
          }
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
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _goTo(_index + 1),
            child: CustomPaint(
              painter: SpotlightPainter(
                hole: hole,
                radius: _step.radius + _step.padding,
                pulse: _pulse.value,
                cardAbove: cardAbove,
                gap: _gap,
              ),
            ),
          ),
        ),
        if (hole != null)
          Positioned(
            left: 20,
            right: 20,
            top: cardAbove ? null : hole.bottom + _gap,
            bottom: cardAbove ? size.height - hole.top + _gap : null,
            child: _buildCard(),
          )
        else
          Center(
            child: Padding(padding: const EdgeInsets.all(20), child: _buildCard()),
          ),
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

  Widget _buildCard() {
    final int total = widget.steps.length;
    final bool isLast = _index == total - 1;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${_index + 1} dari $total',
              style: ts(12, weight: FontWeight.w700, color: AppColors.teal, height: 16),
            ),
            const SizedBox(height: 4),
            Text(_step.title, style: ts(18, weight: FontWeight.w800, height: 24)),
            const SizedBox(height: 6),
            Text(_step.body, style: ts(14, color: AppColors.inkSoft, height: 21)),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                if (_index > 0)
                  TextButton(
                    onPressed: () => _goTo(_index - 1),
                    child: Text(
                      'Kembali',
                      style: ts(14, weight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () => _goTo(_index + 1),
                  style: primaryButtonStyle(height: 44, fullWidth: false),
                  child: Text(isLast ? 'Selesai' : 'Lanjut'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}