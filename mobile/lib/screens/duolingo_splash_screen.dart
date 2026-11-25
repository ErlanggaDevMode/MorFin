import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';

/// Duolingo-inspired vibrant animated loading splash screen for MorFin.
/// Features an expressive squash-and-stretch bouncing mascot ("Mori"),
/// periodic blinking eyes, flapping wings, dynamic ground shadow,
/// chunky 3D pill loading bar, and bottom brand wordmark.
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
    with TickerProviderStateMixin {
  late final AnimationController _hopCtrl;
  late final AnimationController _blinkCtrl;
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _hopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _hopCtrl.dispose();
    _blinkCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = MorfinColors.canvas;
    final accentLight = MorfinColors.limeSoft;
    final accentDeep = MorfinColors.limeDeep;
    final entryScale = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutBack,
    );
    final entryFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOut,
    );

    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTapSkip,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.18),
              radius: 1.05,
              colors: [
                Color.lerp(bg, Colors.white, 0.12)!,
                bg,
                Color.lerp(bg, accentDeep, 0.28)!,
              ],
              stops: const [0.0, 0.58, 1.0],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 520;
                final mascotSize = compact ? 132.0 : 176.0;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: compact ? 18 : 34,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      // Animated Duolingo-style Mascot ("Mori")
                      FadeTransition(
                        opacity: entryFade,
                        child: ScaleTransition(
                          scale: entryScale,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_hopCtrl, _blinkCtrl]),
                            builder: (context, _) {
                              final t = _hopCtrl.value;
                              // Hop physics:
                              // 0.00..0.14: anticipation squash
                              // 0.14..0.52: joyful upward jump arc
                              // 0.52..0.68: cushioned landing squash
                              // 0.68..1.00: cheerful settle
                              double jumpY = 0;
                              double sx = 1.0;
                              double sy = 1.0;
                              double tilt = 0.0;
                              double wingFlap = 0.0;

                              if (t < 0.14) {
                                final p = math.sin((t / 0.14) * math.pi);
                                sx = 1.0 + 0.09 * p;
                                sy = 1.0 - 0.10 * p;
                                jumpY = 6.0 * p;
                                wingFlap = -0.22 * p;
                              } else if (t < 0.56) {
                                final p = (t - 0.14) / 0.42;
                                final arc = math.sin(p * math.pi);
                                jumpY = -30.0 * arc;
                                sx = 1.0 - 0.06 * arc;
                                sy = 1.0 + 0.08 * arc;
                                tilt = math.sin(p * math.pi * 2) * 0.06;
                                wingFlap = 0.55 * arc;
                              } else if (t < 0.72) {
                                final p = math.sin(((t - 0.56) / 0.16) * math.pi);
                                sx = 1.0 + 0.10 * p;
                                sy = 1.0 - 0.11 * p;
                                jumpY = 5.0 * p;
                                wingFlap = -0.18 * p;
                              } else {
                                final p = (t - 0.72) / 0.28;
                                jumpY = -2.0 * math.sin(p * math.pi);
                                wingFlap = 0.08 * math.sin(p * math.pi);
                              }

                              // Blink window near end of 2.8s cycle
                              final b = _blinkCtrl.value;
                              double blinkAmount = 0.0;
                              if (b > 0.86 && b < 0.94) {
                                blinkAmount = math.sin(((b - 0.86) / 0.08) * math.pi);
                              }

                              final shadowScale = (1.0 + jumpY / 110.0).clamp(0.68, 1.12);
                              final shadowAlpha = (0.22 + jumpY / 260.0).clamp(0.08, 0.26);

                              return SizedBox(
                                width: mascotSize + 44,
                                height: mascotSize + 52,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Soft glow behind mascot
                                    Container(
                                      width: mascotSize * 0.96,
                                      height: mascotSize * 0.96,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.14),
                                      ),
                                    ),
                                    // Dynamic ground shadow
                                    Positioned(
                                      bottom: 10,
                                      child: Transform.scale(
                                        scaleX: shadowScale,
                                        scaleY: shadowScale * 0.85,
                                        child: Container(
                                          width: mascotSize * 0.58,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: MorfinColors.carbon.withValues(alpha: shadowAlpha),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Bouncing mascot
                                    Transform.translate(
                                      offset: Offset(0, jumpY - 6),
                                      child: Transform.rotate(
                                        angle: tilt,
                                        child: Transform(
                                          alignment: Alignment.bottomCenter,
                                          transform: Matrix4.diagonal3Values(sx, sy, 1.0),
                                          child: CustomPaint(
                                            size: Size(mascotSize, mascotSize),
                                            painter: _MoriMascotPainter(
                                              bodyColor: Color.lerp(MorfinColors.lime, Colors.white, 0.22)!,
                                              bodyShade: accentDeep,
                                              bellyColor: MorfinColors.pistachio,
                                              wingColor: accentLight,
                                              wingFlap: wingFlap,
                                              blinkAmount: blinkAmount,
                                              sparklePhase: t,
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
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Chunky Duolingo-style 3D pill loading bar
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Column(
                          children: [
                            Container(
                              height: 14,
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: LayoutBuilder(
                                builder: (context, barBox) {
                                  final fillW = (barBox.maxWidth * widget.progress.clamp(0.08, 1.0));
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 240),
                                      curve: Curves.easeOutCubic,
                                      width: fillW,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Container(
                                          height: 3.5,
                                          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: MorfinColors.limeSoft.withValues(alpha: 0.55),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                        ),
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
                                  12.5,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: compact ? 18 : 30),

                      // Bottom Brand Wordmark (Duolingo signature layout)
                      Text(
                        'MorFin',
                        style: MorfinTheme.display(
                          compact ? 30 : 36,
                          color: Colors.white,
                          weight: FontWeight.w800,
                        ).copyWith(
                          letterSpacing: -0.8,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              offset: const Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SMART FINANCE TRACKER',
                        style: MorfinTheme.body(
                          10.5,
                          color: Colors.white.withValues(alpha: 0.78),
                          weight: FontWeight.w800,
                        ).copyWith(letterSpacing: 2.2),
                      ),
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

class _MoriMascotPainter extends CustomPainter {
  final Color bodyColor;
  final Color bodyShade;
  final Color bellyColor;
  final Color wingColor;
  final double wingFlap;
  final double blinkAmount;
  final double sparklePhase;

  const _MoriMascotPainter({
    required this.bodyColor,
    required this.bodyShade,
    required this.bellyColor,
    required this.wingColor,
    required this.wingFlap,
    required this.blinkAmount,
    required this.sparklePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.54;

    // 1. Cute little orange feet
    final footPaint = Paint()..color = const Color(0xFFF5A623);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - w * 0.14, h * 0.90), width: w * 0.17, height: h * 0.08),
        const Radius.circular(99),
      ),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + w * 0.14, h * 0.90), width: w * 0.17, height: h * 0.08),
        const Radius.circular(99),
      ),
      footPaint,
    );

    // 2. Flapping side wings
    final wingPaint = Paint()..color = bodyShade;
    final wingHighlight = Paint()..color = wingColor.withValues(alpha: 0.5);

    // Left wing
    canvas.save();
    canvas.translate(cx - w * 0.30, cy + h * 0.02);
    canvas.rotate(-0.35 - wingFlap);
    final leftWingRect = Rect.fromCenter(center: Offset(-w * 0.08, h * 0.05), width: w * 0.22, height: h * 0.32);
    canvas.drawRRect(RRect.fromRectAndRadius(leftWingRect, const Radius.circular(99)), wingPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(leftWingRect.deflate(4), const Radius.circular(99)),
      wingHighlight,
    );
    canvas.restore();

    // Right wing
    canvas.save();
    canvas.translate(cx + w * 0.30, cy + h * 0.02);
    canvas.rotate(0.35 + wingFlap);
    final rightWingRect = Rect.fromCenter(center: Offset(w * 0.08, h * 0.05), width: w * 0.22, height: h * 0.32);
    canvas.drawRRect(RRect.fromRectAndRadius(rightWingRect, const Radius.circular(99)), wingPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rightWingRect.deflate(4), const Radius.circular(99)),
      wingHighlight,
    );
    canvas.restore();

    // 3. Head tuft feathers (Duolingo-inspired friendly crest)
    final tuftPaint = Paint()..color = bodyColor;
    final tuftPath = Path()
      ..moveTo(cx - w * 0.07, h * 0.20)
      ..quadraticBezierTo(cx - w * 0.11, h * 0.08, cx - w * 0.01, h * 0.12)
      ..quadraticBezierTo(cx + w * 0.05, h * 0.04, cx + w * 0.08, h * 0.16)
      ..quadraticBezierTo(cx + w * 0.14, h * 0.11, cx + w * 0.12, h * 0.22)
      ..close();
    canvas.drawPath(tuftPath, tuftPaint);

    // 4. Main plump rounded owl/buddy body (with subtle bottom 3D rim)
    final bodyRect = Rect.fromCenter(center: Offset(cx, cy), width: w * 0.68, height: h * 0.72);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect.shift(const Offset(0, 4)), Radius.circular(w * 0.33)),
      Paint()..color = bodyShade,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.33)),
      Paint()..color = bodyColor,
    );

    // 5. Creamy belly patch with subtle coin chevron scallops
    final bellyRect = Rect.fromCenter(
      center: Offset(cx, cy + h * 0.16),
      width: w * 0.44,
      height: h * 0.32,
    );
    canvas.drawOval(bellyRect, Paint()..color = bellyColor);

    final featherMark = Paint()
      ..color = bodyColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    for (final dx in [-0.09, 0.0, 0.09]) {
      final path = Path()
        ..moveTo(cx + w * (dx - 0.03), cy + h * 0.14)
        ..quadraticBezierTo(cx + w * dx, cy + h * 0.18, cx + w * (dx + 0.03), cy + h * 0.14);
      canvas.drawPath(path, featherMark);
    }

    // 6. Expressive big eyes mask (soft light green rings around eyes)
    final eyeY = cy - h * 0.09;
    final eyeDx = w * 0.15;
    final maskPaint = Paint()..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawCircle(Offset(cx - eyeDx, eyeY), w * 0.165, maskPaint);
    canvas.drawCircle(Offset(cx + eyeDx, eyeY), w * 0.165, maskPaint);

    // White sclera
    final eyeR = w * 0.135;
    final whitePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = const Color(0xFF161916);

    for (final sign in [-1.0, 1.0]) {
      final ex = cx + sign * eyeDx;
      if (blinkAmount > 0.45) {
        // Happy squinting blink arc
        final arcPaint = Paint()
          ..color = const Color(0xFF161916)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.2
          ..strokeCap = StrokeCap.round;
        final rect = Rect.fromCenter(center: Offset(ex, eyeY + 3), width: eyeR * 1.4, height: eyeR * 0.9);
        canvas.drawArc(rect, math.pi * 1.15, math.pi * 0.70, false, arcPaint);
      } else {
        final openH = eyeR * 2 * (1.0 - blinkAmount * 0.8);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(ex, eyeY), width: eyeR * 1.9, height: openH),
          whitePaint,
        );
        // Pupil
        final pupilR = eyeR * 0.56;
        final pupilCenter = Offset(ex + sign * -1.8, eyeY + 1.0);
        canvas.drawCircle(pupilCenter, pupilR, pupilPaint);
        // Glossy specular catchlights
        canvas.drawCircle(
          pupilCenter + Offset(-pupilR * 0.34, -pupilR * 0.34),
          pupilR * 0.30,
          whitePaint,
        );
        canvas.drawCircle(
          pupilCenter + Offset(pupilR * 0.32, pupilR * 0.28),
          pupilR * 0.14,
          whitePaint,
        );
      }
    }

    // 7. Rosy cheeks
    final cheekPaint = Paint()..color = const Color(0xFFFF8A6B).withValues(alpha: 0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.22, cy + h * 0.03), width: w * 0.10, height: h * 0.055),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.22, cy + h * 0.03), width: w * 0.10, height: h * 0.055),
      cheekPaint,
    );

    // 8. Cute golden beak
    final beakTop = Path()
      ..moveTo(cx - w * 0.075, cy + h * 0.005)
      ..quadraticBezierTo(cx, cy - h * 0.055, cx + w * 0.075, cy + h * 0.005)
      ..quadraticBezierTo(cx, cy + h * 0.075, cx - w * 0.075, cy + h * 0.005)
      ..close();
    canvas.drawPath(beakTop, Paint()..color = const Color(0xFFF5C049));

    final beakBottom = Path()
      ..moveTo(cx - w * 0.05, cy + h * 0.02)
      ..quadraticBezierTo(cx, cy + h * 0.085, cx + w * 0.05, cy + h * 0.02)
      ..close();
    canvas.drawPath(beakBottom, Paint()..color = const Color(0xFFE78B28));

    // 9. Floating golden coin badge (top-right of head) that pulses gently
    final coinPulse = 0.92 + 0.12 * math.sin(sparklePhase * math.pi * 2);
    final coinCenter = Offset(cx + w * 0.34, h * 0.18 - 5 * math.sin(sparklePhase * math.pi * 2));
    final coinR = w * 0.095 * coinPulse;
    canvas.drawCircle(coinCenter + const Offset(0, 2), coinR, Paint()..color = const Color(0xFFD9931E));
    canvas.drawCircle(coinCenter, coinR, Paint()..color = const Color(0xFFFCD34D));
    canvas.drawCircle(
      coinCenter,
      coinR * 0.72,
      Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // 10. Twinkling 4-point sparkle (top-left)
    final starScale = 0.65 + 0.35 * math.cos(sparklePhase * math.pi * 2).abs();
    _drawSparkle(canvas, Offset(cx - w * 0.35, h * 0.22), w * 0.055 * starScale, Colors.white.withValues(alpha: 0.9));
  }

  void _drawSparkle(Canvas canvas, Offset center, double r, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MoriMascotPainter oldDelegate) {
    return oldDelegate.wingFlap != wingFlap ||
        oldDelegate.blinkAmount != blinkAmount ||
        oldDelegate.sparklePhase != sparklePhase ||
        oldDelegate.bodyColor != bodyColor;
  }
}
