import 'dart:async';
import 'package:flutter/material.dart';
import 'core/theme/morfin_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/duolingo_splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'state/morfin_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MorfinApp());
}

class MorfinApp extends StatefulWidget {
  final MorfinController? controller;
  final Duration minSplashDuration;

  const MorfinApp({
    super.key,
    this.controller,
    this.minSplashDuration = const Duration(milliseconds: 2450),
  });

  @override
  State<MorfinApp> createState() => _MorfinAppState();
}

class _MorfinAppState extends State<MorfinApp> {
  late final MorfinController _ctrl;
  bool _minSplashDone = false;
  double _splashProgress = 0.22;
  String _splashStatus = 'Menyiapkan dompet MorFin...';
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? MorfinController();
    _ctrl.bootstrap();
    _startSplashTimeline();
  }

  void _startSplashTimeline() {
    final totalMs = widget.minSplashDuration.inMilliseconds;
    if (totalMs <= 0) {
      _minSplashDone = true;
      _splashProgress = 1.0;
      return;
    }

    _timers.add(Timer(Duration(milliseconds: (totalMs * 0.25).round()), () {
      if (!mounted) return;
      setState(() {
        _splashProgress = 0.58;
        _splashStatus = 'Menyinkronkan arus kas...';
      });
    }));

    _timers.add(Timer(Duration(milliseconds: (totalMs * 0.65).round()), () {
      if (!mounted) return;
      setState(() {
        _splashProgress = 0.88;
        _splashStatus = 'Memuat anggaran & target...';
      });
    }));

    _timers.add(Timer(Duration(milliseconds: totalMs), () {
      if (!mounted) return;
      setState(() {
        _splashProgress = 1.0;
        _splashStatus = 'Siap kelola keuangan!';
        _minSplashDone = true;
      });
    }));
  }

  void _skipLoadingSplash() {
    if (_ctrl.isInitialized && !_minSplashDone) {
      setState(() {
        _splashProgress = 1.0;
        _minSplashDone = true;
      });
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    if (widget.controller == null) {
      _ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final palette = _ctrl.palette;
        final showLoadingSplash = !_ctrl.isInitialized || !_minSplashDone;
        final effectiveProgress = _ctrl.isInitialized
            ? (_minSplashDone ? 1.0 : _splashProgress)
            : _splashProgress.clamp(0.18, 0.85);

        return MaterialApp(
          title: 'MorFin — Finance Tracker',
          debugShowCheckedModeBanner: false,
          theme: MorfinTheme.build(palette),
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: showLoadingSplash
                ? DuolingoSplashScreen(
                    key: const ValueKey('morfin_duolingo_boot'),
                    progress: effectiveProgress,
                    statusText: _splashStatus,
                    onTapSkip: _skipLoadingSplash,
                  )
                : !_ctrl.hasPassedSplash
                    ? SplashScreen(key: const ValueKey('morfin_splash'), onStart: _ctrl.completeSplash)
                    : !_ctrl.isAuthenticated
                        ? AuthScreen(key: const ValueKey('morfin_auth'), controller: _ctrl)
                        : MainShell(key: ValueKey('morfin_shell_${_ctrl.themeId}'), controller: _ctrl),
          ),
        );
      },
    );
  }
}
