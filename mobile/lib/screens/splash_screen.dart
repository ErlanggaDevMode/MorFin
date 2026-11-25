import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';
import '../widgets/neo_flat_art.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onStart;
  const SplashScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MorfinColors.surfaceWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 820;
            return Container(
              width: double.infinity,
              color: isDesktop ? MorfinColors.canvas : MorfinColors.surfaceWhite,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Container(
                  width: isDesktop ? 420 : null,
                  padding: isDesktop ? const EdgeInsets.symmetric(horizontal: 36, vertical: 40) : EdgeInsets.zero,
                  decoration: isDesktop
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(38),
                          boxShadow: [
                            BoxShadow(
                              color: MorfinColors.carbon.withValues(alpha: 0.16),
                              blurRadius: 42,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MorfinSplashArt(width: 205, height: 235),
                      const SizedBox(height: 16),
                      Text('MorFin', style: MorfinTheme.display(38, color: MorfinColors.ink)),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onStart,
                        child: Container(
                          width: 92,
                          height: 48,
                          decoration: BoxDecoration(
                            color: MorfinColors.carbon,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: MorfinColors.carbon.withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Let's Start",
                        style: MorfinTheme.body(13, color: MorfinColors.muted, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Kelola arus kas, anggaran harian, dan target tabungan Anda dengan ringan dan terukur.',
                        textAlign: TextAlign.center,
                        style: MorfinTheme.body(11, color: MorfinColors.mutedLight),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
