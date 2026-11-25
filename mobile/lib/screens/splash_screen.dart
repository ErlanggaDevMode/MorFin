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
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: (constraints.maxHeight - 40).clamp(0, 2000)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MorfinSplashArt(width: 205, height: 235),
                      const SizedBox(height: 16),
                      Text(
                        'MorFin',
                        style: MorfinTheme.display(38, color: MorfinColors.ink),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onStart,
                        child: Container(
                          width: 88,
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
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Kelola arus kas, anggaran harian, dan target tabungan Anda dengan ringan dan terukur.',
                      textAlign: TextAlign.center,
                      style: MorfinTheme.body(11, color: MorfinColors.mutedLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
