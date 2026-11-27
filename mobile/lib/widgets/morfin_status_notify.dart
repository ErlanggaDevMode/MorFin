import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';
import 'morfin_mascot.dart';

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
  MascotMood? mood,
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
      mood: mood ?? (isSuccess ? MascotMood.happy : MascotMood.worried),
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
  final MascotMood mood;
  final String title;
  final String message;
  final String buttonLabel;
  final Duration duration;
  final VoidCallback onRemoved;

  const _MorfinStatusNotifyOverlay({
    required this.isSuccess,
    required this.mood,
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

            // Animated Fin Mascot celebrating success or sympathizing on error
            ScaleTransition(
              scale: badgeScale,
              child: MorfinMascot(
                mood: widget.mood,
                size: 102,
              ),
            ),

            const SizedBox(height: 16),

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
