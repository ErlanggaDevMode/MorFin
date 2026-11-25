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
    return MaterialApp(
      title: 'MorFin — Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: MorfinTheme.build(),
      builder: (context, child) {
        // On wide desktop/web viewports, frame MorFin inside a sleek Matcha-Lime mobile halo matching KASU!
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= 520) return child ?? const SizedBox.shrink();
            final frameHeight = (constraints.maxHeight - 32).clamp(360.0, 820.0);
            return Container(
              color: MorfinColors.canvas,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 404,
                height: frameHeight,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(46),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF283A0C).withValues(alpha: 0.2),
                      blurRadius: 44,
                      offset: const Offset(0, 22),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: child,
                ),
              ),
            );
          },
        );
      },
      home: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          if (!_ctrl.isInitialized) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator(color: MorfinColors.carbon)),
            );
          }
          if (!_ctrl.hasPassedSplash) {
            return SplashScreen(onStart: _ctrl.completeSplash);
          }
          if (!_ctrl.isAuthenticated) {
            return AuthScreen(controller: _ctrl);
          }
          return MainShell(controller: _ctrl);
        },
      ),
    );
  }
}
