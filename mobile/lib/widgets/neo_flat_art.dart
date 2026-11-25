import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';

/// Stacked flat-geometric illustration matching KASU / MorFin Splash Screen.
class MorfinSplashArt extends StatelessWidget {
  final double width;
  final double height;
  const MorfinSplashArt({super.key, this.width = 230, this.height = 265});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SplashArtPainter(),
    );
  }
}

class _SplashArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 240.0;
    final sy = size.height / 280.0;
    canvas.save();
    canvas.scale(sx, sy);

    // Floating pastel confetti dots
    canvas.drawCircle(const Offset(42, 52), 9, Paint()..color = const Color(0xFFC4E1F6));
    canvas.drawCircle(const Offset(206, 148), 6, Paint()..color = const Color(0xFFB3E3CC));
    canvas.drawCircle(const Offset(24, 212), 7, Paint()..color = const Color(0xFFF7D1B6));
    canvas.drawCircle(const Offset(204, 238), 5, Paint()..color = const Color(0xFFE3F0C7));

    // Top carbon half-circle smiling face
    canvas.save();
    canvas.translate(138, 66);
    canvas.rotate(24 * math.pi / 180);
    canvas.drawArc(
      const Rect.fromLTWH(-54, -54, 108, 108),
      0,
      math.pi,
      true,
      Paint()..color = MorfinColors.carbon,
    );
    canvas.drawCircle(const Offset(-12, 18), 3, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(12, 18), 3, Paint()..color = Colors.white);
    final checkPath = Path()
      ..moveTo(-10, 29)
      ..lineTo(0, 38)
      ..lineTo(16, 22);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = MorfinColors.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    // Middle matcha-lime half-circle bowl
    canvas.save();
    canvas.translate(86, 134);
    canvas.rotate(-8 * math.pi / 180);
    canvas.drawArc(
      const Rect.fromLTWH(-64, -64, 128, 128),
      0,
      math.pi,
      true,
      Paint()..color = MorfinColors.lime,
    );
    canvas.restore();

    // Right carbon quarter wedge
    canvas.save();
    canvas.translate(142, 150);
    canvas.rotate(10 * math.pi / 180);
    canvas.drawArc(
      const Rect.fromLTWH(-52, 0, 104, 104),
      -math.pi / 2,
      math.pi / 2,
      true,
      Paint()..color = MorfinColors.carbon,
    );
    canvas.restore();

    // Bottom matcha-lime dome with white coin-arrow mark
    canvas.save();
    canvas.translate(116, 256);
    canvas.rotate(-6 * math.pi / 180);
    canvas.drawArc(
      const Rect.fromLTWH(-66, -66, 132, 132),
      math.pi,
      math.pi,
      true,
      Paint()..color = MorfinColors.lime,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-24, -42, 10, 30), const Radius.circular(3)),
      Paint()..color = Colors.white,
    );
    final tri = Path()
      ..moveTo(-6, -42)
      ..lineTo(28, -27)
      ..lineTo(-6, -12)
      ..close();
    canvas.drawPath(tri, Paint()..color = Colors.white);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Flat coral-orange flame icon for "25 Hari Hemat" card.
class FlameStreakArt extends StatelessWidget {
  final double size;
  const FlameStreakArt({super.key, this.size = 78});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _FlamePainter());
  }
}

class _FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 84.0, size.height / 84.0);
    final outer = Path()
      ..moveTo(46, 12)
      ..cubicTo(54, 24, 68, 30, 68, 48)
      ..cubicTo(68, 64, 56, 76, 42, 76)
      ..cubicTo(26, 76, 16, 64, 16, 50)
      ..cubicTo(16, 38, 24, 30, 28, 24)
      ..cubicTo(29, 33, 34, 36, 37, 33)
      ..cubicTo(39, 24, 41, 18, 46, 12)
      ..close();
    canvas.drawPath(outer, Paint()..color = MorfinColors.coral);
    canvas.drawPath(
      outer,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round,
    );
    final inner = Path()
      ..moveTo(44, 38)
      ..cubicTo(49, 46, 55, 50, 55, 59)
      ..cubicTo(55, 67, 49, 72, 42, 72)
      ..cubicTo(35, 72, 30, 66, 30, 59)
      ..cubicTo(30, 52, 35, 47, 38, 43)
      ..cubicTo(39, 48, 41, 49, 44, 38)
      ..close();
    canvas.drawPath(inner, Paint()..color = MorfinColors.gold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Golden trophy art for the "Keep It Up!" budget hero card.
class TrophyCupArt extends StatelessWidget {
  final double size;
  const TrophyCupArt({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size * 0.92), painter: _TrophyPainter());
  }
}

class _TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 112.0, size.height / 104.0);
    canvas.drawCircle(const Offset(28, 24), 3, Paint()..color = MorfinColors.lime);
    canvas.drawCircle(const Offset(96, 54), 3.5, Paint()..color = MorfinColors.lime);

    canvas.save();
    canvas.translate(62, 50);
    canvas.rotate(-12 * math.pi / 180);
    final cup = Path()
      ..moveTo(-20, -24)
      ..lineTo(20, -24)
      ..lineTo(14, 8)
      ..quadraticBezierTo(10, 18, 0, 18)
      ..quadraticBezierTo(-10, 18, -14, 8)
      ..close();
    canvas.drawPath(cup, Paint()..color = MorfinColors.gold);

    final handlePaint = Paint()
      ..color = MorfinColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(const Rect.fromLTWH(-32, -18, 18, 20), math.pi * 0.5, math.pi, false, handlePaint);
    canvas.drawArc(const Rect.fromLTWH(14, -18, 18, 20), -math.pi * 0.5, math.pi, false, handlePaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-6, 16, 12, 16), const Radius.circular(3)),
      Paint()..color = const Color(0xFFE3A52A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-18, 30, 36, 10), const Radius.circular(5)),
      Paint()..color = MorfinColors.gold,
    );
    canvas.restore();

    final wrist = Path()
      ..moveTo(58, 86)
      ..lineTo(74, 104)
      ..lineTo(50, 104)
      ..close();
    canvas.drawPath(wrist, Paint()..color = const Color(0xFFC97E63));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.96, h * 0.24)
      ..lineTo(w * 0.96, h * 0.76)
      ..lineTo(w * 0.5, h)
      ..lineTo(w * 0.04, h * 0.76)
      ..lineTo(w * 0.04, h * 0.24)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class HexagonBadge extends StatelessWidget {
  final String iconKey;
  final bool unlocked;
  final String label;
  final VoidCallback? onTap;

  const HexagonBadge({
    super.key,
    required this.iconKey,
    required this.unlocked,
    required this.label,
    this.onTap,
  });

  List<Color> _colors() {
    if (!unlocked) return [const Color(0xFF8C928B), const Color(0xFF565B56)];
    switch (iconKey) {
      case 'shield':
        return [const Color(0xFFFEF08A), const Color(0xFFEAB308)];
      case 'coin':
        return [const Color(0xFFFED7AA), const Color(0xFFF97316)];
      case 'coffee':
        return [const Color(0xFFBAE6FD), const Color(0xFF38BDF8)];
      case 'chart':
        return [const Color(0xFFD9F99D), const Color(0xFF84CC16)];
      case 'plane':
        return [const Color(0xFFC4B5FD), const Color(0xFF8B5CF6)];
      default:
        return [const Color(0xFFA7F3D0), const Color(0xFF10B981)];
    }
  }

  IconData _iconData() {
    switch (iconKey) {
      case 'shield':
        return Icons.verified_user_rounded;
      case 'coin':
        return Icons.monetization_on_rounded;
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'chart':
        return Icons.trending_up_rounded;
      case 'plane':
        return Icons.flight_takeoff_rounded;
      case 'home':
        return Icons.home_rounded;
      default:
        return Icons.savings_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = _colors();
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipPath(
            clipper: HexagonClipper(),
            child: Container(
              width: 82,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: cols,
                ),
              ),
              child: Center(
                child: Icon(
                  _iconData(),
                  size: 34,
                  color: unlocked ? MorfinColors.carbon : Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: MorfinTheme.body(11.5, color: const Color(0xFFD6DFD2), weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
