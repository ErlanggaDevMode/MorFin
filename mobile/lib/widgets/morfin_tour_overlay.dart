import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';
import '../screens/duolingo_splash_screen.dart';

class MorfinTourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final double borderRadius;

  const MorfinTourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.borderRadius = 22,
  });
}

/// Interactive onboarding tour overlay for MorFin:
/// 1. Starts with a blurred welcome choice modal ("Ikuti Tour" vs "Skip Tour")
/// 2. Steps 1-by-1 through core features: blurs & dims everything EXCEPT the
///    highlighted widget, with an animated spotlight ring and crisp speech bubble.
class MorfinTourOverlay extends StatefulWidget {
  final List<MorfinTourStep> steps;
  final VoidCallback onFinished;

  const MorfinTourOverlay({
    super.key,
    required this.steps,
    required this.onFinished,
  });

  @override
  State<MorfinTourOverlay> createState() => _MorfinTourOverlayState();
}

class _MorfinTourOverlayState extends State<MorfinTourOverlay>
    with SingleTickerProviderStateMixin {
  bool _inIntro = true;
  int _stepIdx = 0;
  Rect? _targetRect;
  Rect? _prevRect;
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _focusStep(int index) async {
    if (!mounted) return;
    if (index < 0 || index >= widget.steps.length) {
      widget.onFinished();
      return;
    }

    final step = widget.steps[index];
    final targetCtx = step.targetKey.currentContext;

    if (targetCtx != null) {
      try {
        await Scrollable.ensureVisible(
          targetCtx,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.35,
        );
      } catch (_) {}
      // Give scroll/layout one frame to settle before reading coordinates
      await Future.delayed(const Duration(milliseconds: 60));
    }

    if (!mounted) return;
    final rect = _measureTarget(step.targetKey);
    if (rect == null) {
      // If a target widget is not mounted in the current layout, move cleanly to next
      if (index + 1 < widget.steps.length) {
        await _focusStep(index + 1);
      } else {
        widget.onFinished();
      }
      return;
    }

    setState(() {
      _prevRect = _targetRect ?? rect;
      _targetRect = rect;
      _stepIdx = index;
      _inIntro = false;
    });
    _animCtrl
      ..reset()
      ..forward();
  }

  Rect? _measureTarget(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final render = ctx.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return null;
    final offset = render.localToGlobal(Offset.zero);
    if (offset.dx.isNaN || offset.dy.isNaN) return null;
    return (offset & render.size).inflate(6);
  }

  @override
  Widget build(BuildContext context) {
    if (_inIntro) {
      return _buildWelcomeChoice(context);
    }

    final screen = MediaQuery.of(context).size;
    final step = widget.steps[_stepIdx];
    final currentRect = _targetRect ?? Rect.fromCenter(center: screen.center(Offset.zero), width: 120, height: 60);
    final startRect = _prevRect ?? currentRect;

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _animCtrl,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_animCtrl.value);
            final activeRect = Rect.lerp(startRect, currentRect, t) ?? currentRect;

            return Stack(
              children: [
                // 1. Blurred + dimmed backdrop ONLY OUTSIDE the highlighted feature cutout
                Positioned.fill(
                  child: ClipPath(
                    clipper: _InvertedSpotlightClipper(
                      holeRect: activeRect,
                      radius: step.borderRadius,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _focusStep(_stepIdx + 1),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.50),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Crisp glowing Lime highlight border around the sharp focused widget
                Positioned.fromRect(
                  rect: activeRect,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(step.borderRadius),
                        border: Border.all(color: MorfinColors.lime, width: 2.6),
                        boxShadow: [
                          BoxShadow(
                            color: MorfinColors.lime.withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Concise Speech Bubble pointing right at the focused feature
                _buildSpeechBubble(
                  context: context,
                  screen: screen,
                  target: activeRect,
                  step: step,
                  fadeT: t,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeChoice(BuildContext context) {
    final fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    final scale = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: FadeTransition(
          opacity: fade,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              color: Colors.black.withValues(alpha: 0.48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ScaleTransition(
                scale: scale,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                    decoration: BoxDecoration(
                      color: MorfinColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 34,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MorfinLogoBox(
                          size: 62,
                          boxColor: MorfinColors.lime,
                          strokeColor: MorfinColors.carbon,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Selamat Datang di MorFin!',
                          textAlign: TextAlign.center,
                          style: MorfinTheme.display(20, color: MorfinColors.ink),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Akunmu mulai dari Rp 0 dan siap mencatat keuangan nyata. Mau ikuti tur singkat mengenal fitur utama MorFin?',
                          textAlign: TextAlign.center,
                          style: MorfinTheme.body(13, color: MorfinColors.muted),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MorfinColors.carbon,
                              foregroundColor: MorfinColors.lime,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => _focusStep(0),
                            child: Text('Ikuti Tour', style: MorfinTheme.display(14.5, color: MorfinColors.lime)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: TextButton(
                            onPressed: widget.onFinished,
                            child: Text(
                              'Skip Tour',
                              style: MorfinTheme.body(13.5, color: MorfinColors.muted, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechBubble({
    required BuildContext context,
    required Size screen,
    required Rect target,
    required MorfinTourStep step,
    required double fadeT,
  }) {
    final safeTop = MediaQuery.of(context).padding.top + 14;
    final safeBottom = MediaQuery.of(context).padding.bottom + 14;
    final bubbleW = math.min(340.0, screen.width - 32);

    final spaceBelow = screen.height - safeBottom - target.bottom;
    final spaceAbove = target.top - safeTop;
    final placeBelow = spaceBelow >= 195 || spaceBelow >= spaceAbove;

    final left = (target.center.dx - bubbleW / 2).clamp(16.0, screen.width - bubbleW - 16.0);
    // Relative X of the pointer arrow inside the bubble
    final arrowX = (target.center.dx - left).clamp(24.0, bubbleW - 24.0);
    final isLast = _stepIdx == widget.steps.length - 1;

    final bubbleBody = Container(
      width: bubbleW,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
      decoration: BoxDecoration(
        color: MorfinColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: MorfinColors.lime,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${_stepIdx + 1} / ${widget.steps.length}',
                  style: MorfinTheme.display(11, color: MorfinColors.onLime),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onFinished,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Skip Tour',
                    style: MorfinTheme.body(11.5, color: MorfinColors.muted, weight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(step.title, style: MorfinTheme.display(16, color: MorfinColors.ink)),
          const SizedBox(height: 5),
          Text(
            step.description,
            style: MorfinTheme.body(12.5, color: MorfinColors.muted, weight: FontWeight.w500).copyWith(height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (_stepIdx > 0)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _focusStep(_stepIdx - 1),
                  child: Text('Kembali', style: MorfinTheme.body(12, color: MorfinColors.muted, weight: FontWeight.w700)),
                ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MorfinColors.carbon,
                  foregroundColor: MorfinColors.lime,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (isLast) {
                    widget.onFinished();
                  } else {
                    _focusStep(_stepIdx + 1);
                  }
                },
                child: Text(
                  isLast ? 'Mulai Pakai' : 'Lanjut',
                  style: MorfinTheme.display(12.5, color: MorfinColors.lime),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final bubbleWithTail = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (placeBelow)
          Padding(
            padding: EdgeInsets.only(left: arrowX - 9),
            child: CustomPaint(size: const Size(18, 9), painter: _BubbleTailPainter(pointsUp: true)),
          ),
        bubbleBody,
        if (!placeBelow)
          Padding(
            padding: EdgeInsets.only(left: arrowX - 9),
            child: CustomPaint(size: const Size(18, 9), painter: _BubbleTailPainter(pointsUp: false)),
          ),
      ],
    );

    return Positioned(
      left: left,
      top: placeBelow ? (target.bottom + 8).clamp(safeTop, screen.height - safeBottom - 170) : null,
      bottom: placeBelow ? null : (screen.height - target.top + 8).clamp(safeBottom, screen.height - safeTop - 170),
      child: Opacity(
        opacity: fadeT.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1.0 - fadeT) * (placeBelow ? 10 : -10)),
          child: bubbleWithTail,
        ),
      ),
    );
  }
}

class _InvertedSpotlightClipper extends CustomClipper<Path> {
  final Rect holeRect;
  final double radius;

  const _InvertedSpotlightClipper({
    required this.holeRect,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(holeRect, Radius.circular(radius)));
  }

  @override
  bool shouldReclip(covariant _InvertedSpotlightClipper oldClipper) {
    return oldClipper.holeRect != holeRect || oldClipper.radius != radius;
  }
}

class _BubbleTailPainter extends CustomPainter {
  final bool pointsUp;
  const _BubbleTailPainter({required this.pointsUp});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsUp) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = MorfinColors.surfaceWhite);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) => oldDelegate.pointsUp != pointsUp;
}
