import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';

OverlayEntry? _activeNotifyEntry;

/// Displays the MorFin signature scalloped-badge status notification:
/// - Mobile (< 700px): bottom sheet occupying 50% of screen height
/// - Web Desktop / Tablet (>= 700px): centered elevated pop-up card
/// - Enters sliding up from bottom; exits sliding down off-screen
/// - Theme-colored timer line (no numeric countdown), max 4 seconds
/// - Tapping anywhere on screen immediately dismisses with slide-down animation
void showMorfinStatusNotify(
  BuildContext context, {
  required bool isSuccess,
  String? title,
  required String message,
  String? buttonLabel,
  Duration duration = const Duration(seconds: 4),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  // Cleanly remove any previous active notify before showing the new one
  _activeNotifyEntry?.remove();
  _activeNotifyEntry = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _MorfinStatusNotifyOverlay(
      isSuccess: isSuccess,
      title: title ?? (isSuccess ? 'Berhasil!' : 'Gagal!'),
      message: message,
      buttonLabel: buttonLabel ?? (isSuccess ? 'Oke, Sip!' : 'Tutup'),
      duration: duration,
      onRemoved: () {
        if (_activeNotifyEntry == entry) {
          _activeNotifyEntry = null;
        }
        entry.remove();
      },
    ),
  );

  _activeNotifyEntry = entry;
  overlay.insert(entry);
}

class _MorfinStatusNotifyOverlay extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final String buttonLabel;
  final Duration duration;
  final VoidCallback onRemoved;

  const _MorfinStatusNotifyOverlay({
    required this.isSuccess,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.duration,
    required this.onRemoved,
  });

  @override
  State<_MorfinStatusNotifyOverlay> createState() => _MorfinStatusNotifyOverlayState();
}

class _MorfinStatusNotifyOverlayState extends State<_MorfinStatusNotifyOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final AnimationController _badgeCtrl;
  late final AnimationController _timerCtrl;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _timerCtrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slideCtrl.forward().then((_) {
      if (mounted && !_dismissing) {
        _badgeCtrl.forward();
        _timerCtrl.forward();
      }
    });

    // Start badge animation slightly overlapping entrance for snappy feel
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted && !_dismissing && !_badgeCtrl.isAnimating && _badgeCtrl.value == 0) {
        _badgeCtrl.forward();
      }
    });

    _timerCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _timerCtrl.stop();
    await _slideCtrl.reverse();
    if (mounted) {
      widget.onRemoved();
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _badgeCtrl.dispose();
    _timerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktopOrTablet = media.size.width >= 700;
    final sheetHeight = math.max(300.0, media.size.height * 0.50);

    // Slide from bottom up on enter; slide from current position straight down off-screen on exit
    final slideAnim = CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final badgeScale = CurvedAnimation(
      parent: _badgeCtrl,
      curve: Curves.easeOutBack,
    );

    final badgeColor = widget.isSuccess ? const Color(0xFF16A84D) : const Color(0xFFE53935);
    final timerColor = MorfinColors.lime;

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _dismiss,
          child: AnimatedBuilder(
            animation: slideAnim,
            builder: (context, child) {
              final backdropAlpha = 0.42 * slideAnim.value;
              // For desktop popup centered on screen, push down 1.35x height so it fully exits off bottom
              final offscreenDy = isDesktopOrTablet ? 1.45 : 1.05;
              final currentDy = (1.0 - slideAnim.value) * offscreenDy;

              return Container(
                color: Colors.black.withValues(alpha: backdropAlpha),
                alignment: isDesktopOrTablet ? Alignment.center : Alignment.bottomCenter,
                child: FractionalTranslation(
                  translation: Offset(0, currentDy),
                  child: child,
                ),
              );
            },
            child: _buildCard(
              isDesktopOrTablet: isDesktopOrTablet,
              sheetHeight: sheetHeight,
              badgeColor: badgeColor,
              timerColor: timerColor,
              badgeScale: badgeScale,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required bool isDesktopOrTablet,
    required double sheetHeight,
    required Color badgeColor,
    required Color timerColor,
    required Animation<double> badgeScale,
  }) {
    final borderRadius = isDesktopOrTablet
        ? BorderRadius.circular(32)
        : const BorderRadius.vertical(top: Radius.circular(32));

    return Container(
      width: isDesktopOrTablet ? 410 : double.infinity,
      height: isDesktopOrTablet ? null : sheetHeight,
      constraints: isDesktopOrTablet
          ? const BoxConstraints(minHeight: 320, maxWidth: 410)
          : null,
      margin: isDesktopOrTablet ? const EdgeInsets.symmetric(horizontal: 24) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: MorfinColors.surfaceWhite,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Column(
          mainAxisSize: isDesktopOrTablet ? MainAxisSize.min : MainAxisSize.max,
          children: [
            // Theme-colored timer line (no duration text) shrinking smoothly over 4 seconds
            AnimatedBuilder(
              animation: _timerCtrl,
              builder: (context, _) {
                final remaining = (1.0 - _timerCtrl.value).clamp(0.0, 1.0);
                return Container(
                  width: double.infinity,
                  height: 5,
                  color: timerColor.withValues(alpha: 0.16),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: remaining,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: timerColor,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(99)),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Top handle pill on mobile bottom sheet (matches reference)
            if (!isDesktopOrTablet) ...[
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE2DB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],

            if (!isDesktopOrTablet) const Spacer(flex: 2) else const SizedBox(height: 30),

            // Scalloped Green/Red Badge with crisp neo-brutalist shadow
            ScaleTransition(
              scale: badgeScale,
              child: CustomPaint(
                size: const Size(94, 94),
                painter: _ScallopedStatusBadgePainter(
                  badgeColor: badgeColor,
                  isSuccess: widget.isSuccess,
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Title & Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: MorfinTheme.display(24, color: MorfinColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: MorfinTheme.body(14, color: MorfinColors.muted, weight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Dark Carbon Pill Button (matches "Nice one!" reference)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14),
              decoration: BoxDecoration(
                color: MorfinColors.carbon,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.buttonLabel,
                style: MorfinTheme.display(14, color: Colors.white),
              ),
            ),

            if (!isDesktopOrTablet) const Spacer(flex: 3) else const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ScallopedStatusBadgePainter extends CustomPainter {
  final Color badgeColor;
  final bool isSuccess;

  const _ScallopedStatusBadgePainter({
    required this.badgeColor,
    required this.isSuccess,
  });

  Path _buildScallopedPath(Offset center, double outerR, double innerR, int lobes) {
    final path = Path();
    final midR = (outerR + innerR) / 2;
    final amp = (outerR - innerR) / 2;
    const samples = 140;
    for (int i = 0; i <= samples; i++) {
      final t = (i / samples) * math.pi * 2;
      final r = midR + amp * math.cos(lobes * t);
      final x = center.dx + r * math.cos(t - math.pi / 2);
      final y = center.dy + r * math.sin(t - math.pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.45;
    final innerR = size.width * 0.375;

    // 1. Offset crisp dark neo-flat shadow behind the scalloped badge (like reference)
    final shadowPath = _buildScallopedPath(Offset(cx - 2.5, cy + 3.5), outerR, innerR, 10);
    canvas.drawPath(shadowPath, Paint()..color = const Color(0xFF141814));

    // 2. Main scalloped seal badge (green for success, red for error)
    final badgePath = _buildScallopedPath(Offset(cx, cy), outerR, innerR, 10);
    canvas.drawPath(badgePath, Paint()..color = badgeColor);

    // 3. White icon stroke (checkmark or cross)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.068
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isSuccess) {
      final check = Path()
        ..moveTo(size.width * 0.34, size.height * 0.51)
        ..lineTo(size.width * 0.46, size.height * 0.62)
        ..lineTo(size.width * 0.67, size.height * 0.39);
      canvas.drawPath(check, iconPaint);
    } else {
      final d = size.width * 0.145;
      canvas.drawLine(Offset(cx - d, cy - d), Offset(cx + d, cy + d), iconPaint);
      canvas.drawLine(Offset(cx + d, cy - d), Offset(cx - d, cy + d), iconPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScallopedStatusBadgePainter oldDelegate) {
    return oldDelegate.badgeColor != badgeColor || oldDelegate.isSuccess != isSuccess;
  }
}
