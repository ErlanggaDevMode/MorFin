import 'package:flutter/material.dart';
import 'core/theme/morfin_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'state/morfin_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MorfinApp());
}

class MorfinApp extends StatefulWidget {
  final MorfinController? controller;
  const MorfinApp({super.key, this.controller});

  @override
  State<MorfinApp> createState() => _MorfinAppState();
}

class _MorfinAppState extends State<MorfinApp> {
  late final MorfinController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? MorfinController();
    _ctrl.bootstrap();
  }

  @override
  void dispose() {
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
        return MaterialApp(
          title: 'MorFin — Finance Tracker',
          debugShowCheckedModeBanner: false,
          theme: MorfinTheme.build(palette),
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 340),
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
            child: !_ctrl.isInitialized
                ? Scaffold(
                    key: const ValueKey('morfin_boot'),
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator(color: MorfinColors.carbon)),
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
