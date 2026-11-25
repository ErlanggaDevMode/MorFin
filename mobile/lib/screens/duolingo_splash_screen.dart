import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';

/// Iconic MorFin lime squircle mark with the rising-chart carved "M" stroke.
/// Supports [drawProgress] from 0.0 to 1.0 for smooth path-carving animation.
class MorfinLogoBox extends StatelessWidget {
  final double size;
  final double drawProgress;
  final Color? boxColor;
  final Color? strokeColor;
  final double sheenProgress;

  const MorfinLogoBox({
    super.key,
    this.size = 76,
    this.drawProgress = 1.0,
    this.boxColor,
    this.strokeColor,
    this.sheenProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final bg = boxColor ?? const Color(0xFFC9F73B);
    final ink = strokeColor ?? const Color(0xFF121614);
    final radius = size * 0.27;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.22),
            blurRadius: size * 0.34,
            offset: Offset(0, size * 0.10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          size: Size(size, size),
          painter: _MorfinMCarvePainter(
            progress: drawProgress.clamp(0.0, 1.0),
            strokeColor: ink,
            sheenProgress: sheenProgress,
          ),
        ),
      ),
    );
  }
}

class _MorfinMCarvePainter extends CustomPainter {
  final double progress;
  final Color strokeColor;
  final double sheenProgress;

  const _MorfinMCarvePainter({
    required this.progress,
    required this.strokeColor,
    required this.sheenProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Subtle diagonal glass glint after M finishes carving
    if (sheenProgress > 0.0 && sheenProgress < 1.0) {
      final sheenX = -w * 0.6 + (w * 2.2) * sheenProgress;
      final sheenPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.42),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.25, 0.5, 0.75],
        ).createShader(Rect.fromLTWH(sheenX - w * 0.4, 0, w * 0.8, h));
      canvas.drawRect(Offset.zero & size, sheenPaint);
    }

    if (progress <= 0.001) return;

    // Asymmetric rising-chart "M" matching the exact MorFin brand logo:
    // bottom-left -> left shoulder -> center V valley -> higher right peak -> bottom-right
    final path = Path()
      ..moveTo(w * 0.225, h * 0.745)
      ..lineTo(w * 0.225, h * 0.370)
      ..lineTo(w * 0.495, h * 0.605)
      ..lineTo(w * 0.775, h * 0.265)
      ..lineTo(w * 0.775, h * 0.745);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final extracted = metric.extractPath(0.0, metric.length * progress);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.105
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(extracted, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _MorfinMCarvePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.sheenProgress != sheenProgress;
  }
}

/// Kinetic MorFin loading splash screen inspired by Duolingo's crisp motion design:
/// 1. Electric lime squircle box drops from the sky with squash-and-stretch bounce
/// 2. The asymmetric rising "M" logo carves smoothly inside the lime box
/// 3. The lime box slides left while the white "morfin" wordmark glides out to the right
class DuolingoSplashScreen extends StatefulWidget {
  final double progress;
  final String statusText;
  final VoidCallback? onTapSkip;

  const DuolingoSplashScreen({
    super.key,
    required this.progress,
    required this.statusText,
    this.onTapSkip,
  });

  @override
  State<DuolingoSplashScreen> createState() => _DuolingoSplashScreenState();
}

class _DuolingoSplashScreenState extends State<DuolingoSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const Color _bgDark = Color(0xFF121614);
  static const Color _brandLime = Color(0xFFC9F73B);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2150),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTapSkip,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.05),
              radius: 1.15,
              colors: [
                Color(0xFF191F1C),
                _bgDark,
                Color(0xFF0C0F0E),
              ],
              stops: [0.0, 0.58, 1.0],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 380;
                final boxSize = isCompact ? 76.0 : 92.0;
                final fontSize = isCompact ? 46.0 : 56.0;
                final wordWidth = isCompact ? 164.0 : 204.0;
                final gap = isCompact ? 16.0 : 20.0;
                final totalRowW = boxSize + gap + wordWidth;
                // Offset needed to place the lime box dead-center before it glides left
                final initialCenterDx = (totalRowW - boxSize) / 2.0;

                return Column(
                  children: [
                    const Spacer(flex: 5),

                    // Main kinetic logo stage
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (context, _) {
                        final t = _ctrl.value;

                        // PHASE 1 (0.00 -> 0.29): Box drops from sky & lands with juicy squash-stretch bounce
                        double dropY = 0.0;
                        double scaleX = 1.0;
                        double scaleY = 1.0;
                        double boxOpacity = 1.0;
                        double shadowScale = 1.0;
                        double shadowAlpha = 0.28;

                        if (t < 0.19) {
                          // Freefall acceleration from sky
                          final p = t / 0.19;
                          final fallCurve = p * p;
                          dropY = -340.0 * (1.0 - fallCurve);
                          scaleX = 1.0 - 0.10 * (1.0 - fallCurve * 0.5);
                          scaleY = 1.0 + 0.14 * (1.0 - fallCurve * 0.5);
                          boxOpacity = (p * 3.2).clamp(0.0, 1.0);
                          shadowScale = 0.25 + 0.75 * fallCurve;
                          shadowAlpha = 0.04 + 0.24 * fallCurve;
                        } else if (t < 0.26) {
                          // Impact squash
                          final p = (t - 0.19) / 0.07;
                          final s = math.sin(p * math.pi);
                          dropY = 6.0 * s;
                          scaleX = 1.0 + 0.19 * s;
                          scaleY = 1.0 - 0.20 * s;
                          shadowScale = 1.0 + 0.18 * s;
                          shadowAlpha = 0.28 + 0.12 * s;
                        } else if (t < 0.33) {
                          // Crisp secondary rebound pop
                          final p = (t - 0.26) / 0.07;
                          final s = math.sin(p * math.pi);
                          dropY = -14.0 * s;
                          scaleX = 1.0 - 0.06 * s;
                          scaleY = 1.0 + 0.07 * s;
                          shadowScale = 1.0 - 0.10 * s;
                          shadowAlpha = 0.24 - 0.06 * s;
                        } else {
                          shadowScale = 0.95;
                          shadowAlpha = 0.16;
                        }

                        // PHASE 2 (0.31 -> 0.59): Carve the asymmetric "M" inside the lime box
                        final carveT = ((t - 0.31) / 0.28).clamp(0.0, 1.0);
                        final drawProgress = Curves.easeInOutCubic.transform(carveT);

                        // Crisp confirmation pop & diagonal sheen right as M completes (0.58 -> 0.70)
                        double sheenProgress = 0.0;
                        if (t >= 0.57 && t < 0.70) {
                          final p = (t - 0.57) / 0.13;
                          sheenProgress = p;
                          final pop = math.sin(p * math.pi) * 0.055;
                          scaleX += pop;
                          scaleY += pop;
                        }

                        // PHASE 3 (0.64 -> 0.90): Box slides left & "morfin" emerges from behind box to the right
                        final splitT = ((t - 0.64) / 0.26).clamp(0.0, 1.0);
                        final splitCurve = Curves.easeOutCubic.transform(splitT);

                        final boxShiftX = initialCenterDx * (1.0 - splitCurve);
                        // Clip starting behind the lime box so "morfin" physically slides out from its right edge
                        final clipLeft = boxShiftX + boxSize * 0.52;
                        final clipWidth = (totalRowW - clipLeft).clamp(1.0, totalRowW);
                        final finalTextLeftInClip = (boxSize + gap) - clipLeft;
                        final textSlideX = finalTextLeftInClip - (wordWidth * 0.92 * (1.0 - splitCurve));
                        final textOpacity = ((splitT - 0.05) / 0.45).clamp(0.0, 1.0);

                        return SizedBox(
                          width: totalRowW,
                          height: boxSize + 44,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.centerLeft,
                            children: [
                              // Soft lime floor glow under the landing box
                              Positioned(
                                left: boxShiftX + boxSize * 0.10,
                                bottom: 6,
                                child: Opacity(
                                  opacity: boxOpacity * (1.0 - splitCurve * 0.45),
                                  child: Transform.scale(
                                    scaleX: shadowScale,
                                    scaleY: shadowScale * 0.7,
                                    child: Container(
                                      width: boxSize * 0.80,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _brandLime.withValues(alpha: shadowAlpha),
                                        borderRadius: BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _brandLime.withValues(alpha: shadowAlpha * 0.9),
                                            blurRadius: 16,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Wordmark "morfin" clipped behind the lime box so it visibly glides out to the right
                              Positioned(
                                left: clipLeft,
                                child: ClipRect(
                                  child: SizedBox(
                                    width: clipWidth,
                                    height: boxSize,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Transform.translate(
                                        offset: Offset(textSlideX, 0),
                                        child: Opacity(
                                          opacity: textOpacity,
                                          child: Text(
                                            'morfin',
                                            maxLines: 1,
                                            softWrap: false,
                                            style: MorfinTheme.body(
                                              fontSize,
                                              color: Colors.white,
                                              weight: FontWeight.w700,
                                            ).copyWith(
                                              letterSpacing: -1.4,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Lime Squircle Box (drawn on top of the clipped text edge so text glides out from behind it)
                              Positioned(
                                left: boxShiftX,
                                child: Opacity(
                                  opacity: boxOpacity,
                                  child: Transform.translate(
                                    offset: Offset(0, dropY),
                                    child: Transform(
                                      alignment: Alignment.bottomCenter,
                                      transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                                      child: MorfinLogoBox(
                                        size: boxSize,
                                        drawProgress: drawProgress,
                                        boxColor: _brandLime,
                                        strokeColor: _bgDark,
                                        sheenProgress: sheenProgress,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 4),

                    // Minimal dark-mode loading indicator at bottom
                    Padding(
                      padding: const EdgeInsets.only(bottom: 36, left: 32, right: 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Column(
                          children: [
                            Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: LayoutBuilder(
                                builder: (context, bar) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 260),
                                      curve: Curves.easeOutCubic,
                                      width: bar.maxWidth * widget.progress.clamp(0.08, 1.0),
                                      decoration: BoxDecoration(
                                        color: _brandLime,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Text(
                                widget.statusText,
                                key: ValueKey(widget.statusText),
                                textAlign: TextAlign.center,
                                style: MorfinTheme.body(
                                  11.5,
                                  color: Colors.white.withValues(alpha: 0.48),
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
