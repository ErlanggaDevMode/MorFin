import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';

/// The 7 reactive emotional moods of Fin — MorFin's supportive coin-sprout mascot.
enum MascotMood {
  idle,
  happy,
  thinking,
  listening,
  worried,
  sad,
  party,
}

/// Animated CustomPainter widget for Fin, MorFin's coin-with-sprout mascot.
///
/// - Colors automatically adapt to all 5 `MorfinTheme` palettes + Dark Mode.
/// - Respects `MediaQuery.disableAnimations` (reduce-motion).
/// - Smoothly crossfades (`250ms`) when `mood` changes.
class MorfinMascot extends StatefulWidget {
  final MascotMood mood;
  final double size;
  final bool showShadow;

  const MorfinMascot({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 96,
    this.showShadow = true,
  });

  @override
  State<MorfinMascot> createState() => _MorfinMascotState();
}

class _MorfinMascotState extends State<MorfinMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // 8.4s master cycle cleanly aligns sprout sway, 4.2s blinks, hops, waves, drips, & confetti.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnim) {
      _ctrl.stop();
      _ctrl.value = 0.0;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final width = widget.size;
    final height = widget.size * (230.0 / 200.0);

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: AnimatedBuilder(
          key: ValueKey(widget.mood),
          animation: _ctrl,
          builder: (context, _) {
            final tSec = disableAnim ? 0.0 : _ctrl.value * 8.4;
            return CustomPaint(
              size: Size(width, height),
              painter: _FinMascotPainter(
                mood: widget.mood,
                tSec: tSec,
                lime: MorfinColors.lime,
                limeDeep: MorfinColors.limeDeep,
                limeSoft: MorfinColors.limeSoft,
                carbon: MorfinColors.carbon,
                isDark: MorfinColors.isDark,
                cheek: MorfinColors.active.id == 'sunset'
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFFF4A6A6),
                showShadow: widget.showShadow,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FinMascotPainter extends CustomPainter {
  final MascotMood mood;
  final double tSec;
  final Color lime;
  final Color limeDeep;
  final Color limeSoft;
  final Color carbon;
  final bool isDark;
  final Color cheek;
  final bool showShadow;

  const _FinMascotPainter({
    required this.mood,
    required this.tSec,
    required this.lime,
    required this.limeDeep,
    required this.limeSoft,
    required this.carbon,
    required this.isDark,
    required this.cheek,
    required this.showShadow,
  });

  double _wave01(double period, {double delay = 0}) {
    final phase = ((tSec - delay) % period) / period;
    return 0.5 - 0.5 * math.cos(phase * math.pi * 2);
  }

  double _saw01(double period, {double delay = 0}) {
    final v = (tSec - delay) % period;
    return (v < 0 ? v + period : v) / period;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 200.0;
    final sy = size.height / 230.0;
    canvas.save();
    canvas.scale(sx, sy);

    // Subtle light contrast rim on dark surfaces so dark carbon outline stays crisp
    final outlineColor = isDark ? const Color(0xFF141815) : carbon;
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.32) : carbon.withValues(alpha: 0.13);

    // Compute rig transform per mood (anchored near feet at (100, 206))
    double rigDx = 0;
    double rigDy = 0;
    double rigScaleX = 1.0;
    double rigScaleY = 1.0;

    switch (mood) {
      case MascotMood.idle:
        rigDy = -5.0 * _wave01(2.8);
        break;
      case MascotMood.happy:
        final p = _saw01(1.05);
        if (p < 0.14) {
          final k = p / 0.14;
          rigScaleX = 1.0 + 0.08 * k;
          rigScaleY = 1.0 - 0.09 * k;
        } else if (p < 0.45) {
          final k = math.sin(((p - 0.14) / 0.31) * math.pi * 0.5);
          rigDy = -20.0 * k;
          rigScaleX = 1.08 - 0.13 * k;
          rigScaleY = 0.91 + 0.15 * k;
        } else if (p < 0.72) {
          final k = (p - 0.45) / 0.27;
          rigDy = -20.0 * (1 - k);
          rigScaleX = 0.95 + 0.10 * k;
          rigScaleY = 1.06 - 0.12 * k;
        } else {
          final k = (p - 0.72) / 0.28;
          rigScaleX = 1.05 - 0.05 * k;
          rigScaleY = 0.94 + 0.06 * k;
        }
        break;
      case MascotMood.thinking:
        rigDy = -4.5 * _wave01(3.2);
        break;
      case MascotMood.listening:
        rigDy = -5.5 * _wave01(2.1);
        break;
      case MascotMood.worried:
        rigDx = math.sin(tSec * math.pi * 2 / 0.35) * 3.0;
        break;
      case MascotMood.sad:
        final k = _wave01(2.8);
        rigDy = 2.0 + 3.5 * k;
        rigScaleX = 1.02 + 0.025 * k;
        rigScaleY = 0.98 - 0.025 * k;
        break;
      case MascotMood.party:
        final p = _saw01(0.84);
        final bounce = math.sin(p * math.pi);
        rigDy = -18.0 * bounce;
        rigScaleX = 1.04 - 0.09 * bounce;
        rigScaleY = 0.96 + 0.10 * bounce;
        break;
    }

    // 1. Ground shadow (shrinks slightly as Fin hops up)
    if (showShadow) {
      final shadowScale = (1.0 + rigDy / 95.0).clamp(0.72, 1.08);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(100, 214),
          width: 92 * shadowScale,
          height: 14 * shadowScale,
        ),
        Paint()..color = shadowColor,
      );
    }

    // 2. Rig group (transform origin at bottom center 100, 206)
    canvas.save();
    canvas.translate(100 + rigDx, 206 + rigDy);
    canvas.scale(rigScaleX, rigScaleY);
    canvas.translate(-100, -206);

    // 2a. Sprout (stem + two leaves) with gentle sway around (100, 62)
    final swayDeg = -6.0 + 12.0 * _wave01(2.8);
    canvas.save();
    canvas.translate(100, 62);
    canvas.rotate(swayDeg * math.pi / 180.0);
    canvas.translate(-100, -62);

    final stemPath = Path()
      ..moveTo(100, 62)
      ..quadraticBezierTo(99, 50, 101, 38);
    canvas.drawPath(
      stemPath,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    final leafAPath = Path()
      ..moveTo(101, 42)
      ..cubicTo(88, 30, 72, 32, 66, 40)
      ..cubicTo(76, 50, 92, 50, 101, 42)
      ..close();
    canvas.drawPath(leafAPath, Paint()..color = limeDeep);
    canvas.drawPath(
      leafAPath,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );

    final leafBPath = Path()
      ..moveTo(101, 40)
      ..cubicTo(108, 24, 126, 20, 136, 26)
      ..cubicTo(130, 40, 114, 46, 101, 40)
      ..close();
    canvas.drawPath(leafBPath, Paint()..color = limeSoft);
    canvas.drawPath(
      leafBPath,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    // 2b. Arms (behind coin body)
    final limbPaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final handFill = Paint()..color = lime;
    final handStroke = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    if (mood == MascotMood.party) {
      final armSwing = 12.0 * _wave01(0.42);
      // Left arm raised
      canvas.save();
      canvas.translate(44, 120);
      canvas.rotate((armSwing - 6) * math.pi / 180.0);
      canvas.translate(-44, -120);
      final al = Path()
        ..moveTo(44, 120)
        ..quadraticBezierTo(28, 108, 26, 90);
      canvas.drawPath(al, limbPaint);
      canvas.drawCircle(const Offset(26, 87), 7, handFill);
      canvas.drawCircle(const Offset(26, 87), 7, handStroke);
      canvas.restore();

      // Right arm raised
      canvas.save();
      canvas.translate(156, 120);
      canvas.rotate((-armSwing + 6) * math.pi / 180.0);
      canvas.translate(-156, -120);
      final ar = Path()
        ..moveTo(156, 120)
        ..quadraticBezierTo(172, 108, 174, 90);
      canvas.drawPath(ar, limbPaint);
      canvas.drawCircle(const Offset(174, 87), 7, handFill);
      canvas.drawCircle(const Offset(174, 87), 7, handStroke);
      canvas.restore();
    } else {
      // Left arm resting
      final al = Path()
        ..moveTo(44, 132)
        ..quadraticBezierTo(28, 138, 26, 154);
      canvas.drawPath(al, limbPaint);
      canvas.drawCircle(const Offset(26, 157), 7, handFill);
      canvas.drawCircle(const Offset(26, 157), 7, handStroke);

      // Right arm (waves enthusiastically in happy mood!)
      canvas.save();
      if (mood == MascotMood.happy) {
        final waveDeg = -28.0 * _wave01(0.525);
        canvas.translate(156, 132);
        canvas.rotate(waveDeg * math.pi / 180.0);
        canvas.translate(-156, -132);
      }
      final ar = Path()
        ..moveTo(156, 132)
        ..quadraticBezierTo(172, 138, 174, 154);
      canvas.drawPath(ar, limbPaint);
      canvas.drawCircle(const Offset(174, 157), 7, handFill);
      canvas.drawCircle(const Offset(174, 157), 7, handStroke);
      canvas.restore();
    }

    // 2c. Legs & feet
    canvas.drawLine(const Offset(86, 186), const Offset(84, 202), limbPaint);
    canvas.drawLine(const Offset(114, 186), const Offset(116, 202), limbPaint);
    final footPaint = Paint()..color = outlineColor;
    canvas.drawOval(Rect.fromCenter(center: const Offset(80, 205), width: 20, height: 10), footPaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(120, 205), width: 20, height: 10), footPaint);

    // 2d. Coin body + subtle outer glow in dark mode + inner coin rim
    if (isDark) {
      canvas.drawCircle(
        const Offset(100, 126),
        67.5,
        Paint()..color = lime.withValues(alpha: 0.16),
      );
    }
    canvas.drawCircle(const Offset(100, 126), 64, Paint()..color = lime);
    canvas.drawCircle(
      const Offset(100, 126),
      64,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawCircle(
      const Offset(100, 126),
      53,
      Paint()
        ..color = limeDeep.withValues(alpha: 0.52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );

    // 2e. Improved crisp rising-chart "M" belly emblem (larger & clearer than draft)
    final bellyM = Path()
      ..moveTo(81, 172)
      ..lineTo(81, 158)
      ..lineTo(93, 166)
      ..lineTo(106, 154)
      ..lineTo(118, 161);
    canvas.drawPath(
      bellyM,
      Paint()
        ..color = limeDeep.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Tiny rising accent dot at the peak of the chart
    canvas.drawCircle(const Offset(119, 161), 2.8, Paint()..color = limeDeep.withValues(alpha: 0.9));

    // 2f. Face group (shifted up -7 like SVG)
    canvas.save();
    canvas.translate(0, -7);

    // Rosy cheeks
    final cheekPaint = Paint()..color = cheek.withValues(alpha: 0.58);
    canvas.drawOval(Rect.fromCenter(center: const Offset(68, 136), width: 18, height: 12), cheekPaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(132, 136), width: 18, height: 12), cheekPaint);

    final inkStroke = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final inkFill = Paint()..color = outlineColor;

    // Eyebrows (per mood)
    if (mood == MascotMood.worried) {
      canvas.drawLine(const Offset(68, 94), const Offset(90, 99), inkStroke);
      canvas.drawLine(const Offset(132, 94), const Offset(110, 99), inkStroke);
    } else if (mood == MascotMood.sad) {
      canvas.drawLine(const Offset(70, 100), const Offset(90, 94), inkStroke);
      canvas.drawLine(const Offset(130, 100), const Offset(110, 94), inkStroke);
    } else if (mood == MascotMood.thinking) {
      canvas.drawLine(const Offset(70, 94), const Offset(90, 92), inkStroke);
      canvas.drawLine(const Offset(110, 90), const Offset(130, 96), inkStroke);
    }

    // Eyes (with natural blink every 4.2s)
    if (mood == MascotMood.happy || mood == MascotMood.party) {
      final eyeL = Path()
        ..moveTo(67, 117)
        ..quadraticBezierTo(80, 102, 93, 117);
      final eyeR = Path()
        ..moveTo(107, 117)
        ..quadraticBezierTo(120, 102, 133, 117);
      canvas.drawPath(eyeL, inkStroke);
      canvas.drawPath(eyeR, inkStroke);
    } else {
      final blinkPhase = _saw01(4.2);
      double eyeScaleY = 1.0;
      if (blinkPhase > 0.92 && blinkPhase < 0.99) {
        final b = (blinkPhase - 0.92) / 0.07;
        eyeScaleY = 1.0 - 0.90 * math.sin(b * math.pi);
      }

      Offset pupilOffset = Offset.zero;
      if (mood == MascotMood.sad) pupilOffset = const Offset(0, 3);
      if (mood == MascotMood.thinking) pupilOffset = const Offset(4, -5);
      if (mood == MascotMood.listening) pupilOffset = const Offset(-3, 0);

      canvas.save();
      canvas.translate(100, 114);
      canvas.scale(1.0, eyeScaleY);
      canvas.translate(-100, -114);

      final eyeWhite = Paint()..color = Colors.white;
      final eyeBorder = Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      canvas.drawOval(Rect.fromCenter(center: const Offset(80, 114), width: 28, height: 32), eyeWhite);
      canvas.drawOval(Rect.fromCenter(center: const Offset(80, 114), width: 28, height: 32), eyeBorder);
      canvas.drawOval(Rect.fromCenter(center: const Offset(120, 114), width: 28, height: 32), eyeWhite);
      canvas.drawOval(Rect.fromCenter(center: const Offset(120, 114), width: 28, height: 32), eyeBorder);

      canvas.drawCircle(Offset(82 + pupilOffset.dx, 117 + pupilOffset.dy), 7.5, inkFill);
      canvas.drawCircle(Offset(122 + pupilOffset.dx, 117 + pupilOffset.dy), 7.5, inkFill);
      canvas.drawCircle(Offset(85 + pupilOffset.dx, 113 + pupilOffset.dy), 2.6, eyeWhite);
      canvas.drawCircle(Offset(125 + pupilOffset.dx, 113 + pupilOffset.dy), 2.6, eyeWhite);

      canvas.restore();
    }

    // Mouth (per mood)
    switch (mood) {
      case MascotMood.idle:
        final m = Path()
          ..moveTo(89, 140)
          ..quadraticBezierTo(100, 150, 111, 140);
        canvas.drawPath(m, inkStroke);
        break;
      case MascotMood.happy:
        final m = Path()
          ..moveTo(86, 137)
          ..quadraticBezierTo(100, 160, 114, 137)
          ..close();
        canvas.drawPath(m, inkFill);
        final tongue = Path()
          ..moveTo(93, 147)
          ..quadraticBezierTo(100, 154, 107, 147)
          ..quadraticBezierTo(100, 150, 93, 147)
          ..close();
        canvas.drawPath(tongue, Paint()..color = const Color(0xFFF08A8A));
        break;
      case MascotMood.worried:
        final m = Path()
          ..moveTo(88, 146)
          ..quadraticBezierTo(94, 141, 100, 146)
          ..quadraticBezierTo(106, 151, 112, 146);
        canvas.drawPath(m, inkStroke);
        break;
      case MascotMood.sad:
        final m = Path()
          ..moveTo(88, 150)
          ..quadraticBezierTo(100, 139, 112, 150);
        canvas.drawPath(m, inkStroke);
        break;
      case MascotMood.thinking:
        canvas.drawLine(const Offset(94, 145), const Offset(108, 142), inkStroke);
        break;
      case MascotMood.listening:
        canvas.drawOval(Rect.fromCenter(center: const Offset(100, 144), width: 14, height: 16), inkFill);
        break;
      case MascotMood.party:
        final m = Path()
          ..moveTo(84, 136)
          ..quadraticBezierTo(100, 164, 116, 136)
          ..close();
        canvas.drawPath(m, inkFill);
        break;
    }

    // Extra front effects (sweat drop / tear drop)
    if (mood == MascotMood.worried) {
      final p = _saw01(1.4);
      final alpha = p < 0.15 ? (p / 0.15) : (1.0 - (p - 0.15) / 0.85);
      final dy = 24.0 * p;
      final drop = Path()
        ..moveTo(150, 92 + dy)
        ..quadraticBezierTo(156, 104 + dy, 150, 110 + dy)
        ..quadraticBezierTo(144, 104 + dy, 150, 92 + dy)
        ..close();
      canvas.drawPath(drop, Paint()..color = const Color(0xFF7CC4F5).withValues(alpha: alpha));
      canvas.drawPath(
        drop,
        Paint()
          ..color = outlineColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else if (mood == MascotMood.sad) {
      final p = _saw01(1.8);
      final alpha = p < 0.15 ? (p / 0.15) : (1.0 - (p - 0.15) / 0.85);
      final dy = 24.0 * p;
      final tear = Path()
        ..moveTo(72, 130 + dy)
        ..quadraticBezierTo(76, 140 + dy, 72, 144 + dy)
        ..quadraticBezierTo(68, 140 + dy, 72, 130 + dy)
        ..close();
      canvas.drawPath(tear, Paint()..color = const Color(0xFF7CC4F5).withValues(alpha: alpha));
      canvas.drawPath(
        tear,
        Paint()
          ..color = outlineColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    canvas.restore(); // end face
    canvas.restore(); // end rig

    // 3. Top floating overlay effects (outside rig bob)
    if (mood == MascotMood.thinking) {
      final dotColor = isDark ? limeSoft : outlineColor;
      final dots = [
        (const Offset(152, 62), 6.0, 0.0),
        (const Offset(168, 50), 7.0, 0.2),
        (const Offset(186, 36), 8.0, 0.4),
      ];
      for (final d in dots) {
        final a = 0.22 + 0.78 * _wave01(1.2, delay: d.$3);
        canvas.drawCircle(d.$1, d.$2, Paint()..color = dotColor.withValues(alpha: a));
      }
    } else if (mood == MascotMood.listening) {
      final waveColor = isDark ? lime : outlineColor;
      for (int i = 0; i < 2; i++) {
        final p = _saw01(1.4, delay: i * 0.45);
        final scale = 0.65 + 0.55 * p;
        final alpha = (1.0 - p) * 0.92;
        canvas.save();
        canvas.translate(174, 126);
        canvas.scale(scale, scale);
        canvas.translate(-174, -126);
        final wv = Path()
          ..moveTo(176 + i * 9.0, 108 - i * 8.0)
          ..quadraticBezierTo(188 + i * 11.0, 126, 176 + i * 9.0, 144 + i * 8.0);
        canvas.drawPath(
          wv,
          Paint()
            ..color = waveColor.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.6
            ..strokeCap = StrokeCap.round,
        );
        canvas.restore();
      }
    } else if (mood == MascotMood.party) {
      // Flickering streak flame near top-right
      final flScale = _wave01(0.5);
      canvas.save();
      canvas.translate(147, 56);
      canvas.scale(1.0 - 0.08 * flScale, 1.0 + 0.11 * flScale);
      canvas.translate(-147, -56);
      final flame = Path()
        ..moveTo(147, 29)
        ..cubicTo(157, 41, 161, 48, 154, 55)
        ..cubicTo(150, 50, 147, 52, 147, 52)
        ..cubicTo(147, 52, 144, 50, 140, 55)
        ..cubicTo(133, 48, 137, 41, 147, 29)
        ..close();
      canvas.drawPath(flame, Paint()..color = const Color(0xFFFB923C));
      canvas.drawPath(
        flame,
        Paint()
          ..color = outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.restore();

      // 6 falling multi-color confetti pieces
      final confetti = [
        (30.0, const Color(0xFFFBBF24), 0.0),
        (60.0, limeDeep, 0.4),
        (140.0, const Color(0xFFFB7185), 0.2),
        (170.0, const Color(0xFF38BDF8), 0.7),
        (90.0, const Color(0xFFFBBF24), 1.1),
        (120.0, limeSoft, 1.5),
      ];
      for (final c in confetti) {
        final p = _saw01(2.1, delay: c.$3);
        final y = -10.0 + 195.0 * p;
        final rot = p * 260.0 * math.pi / 180.0;
        final alpha = p < 0.1 ? (p / 0.1) : (p > 0.85 ? (1.0 - p) / 0.15 : 1.0);
        canvas.save();
        canvas.translate(c.$1, y);
        canvas.rotate(rot);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -6, 8, 12),
            const Radius.circular(2),
          ),
          Paint()..color = c.$2.withValues(alpha: alpha.clamp(0.0, 1.0)),
        );
        canvas.restore();
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FinMascotPainter old) {
    return old.mood != mood ||
        old.tSec != tSec ||
        old.lime != lime ||
        old.limeDeep != limeDeep ||
        old.limeSoft != limeSoft ||
        old.carbon != carbon ||
        old.isDark != isDark ||
        old.showShadow != showShadow;
  }
}
