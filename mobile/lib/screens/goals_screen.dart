import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';
import '../state/morfin_controller.dart';
import '../widgets/add_sheets.dart';
import '../widgets/neo_flat_art.dart';

class GoalsScreen extends StatelessWidget {
  final MorfinController controller;
  final VoidCallback onJumpToWallets;

  const GoalsScreen({
    super.key,
    required this.controller,
    required this.onJumpToWallets,
  });

  @override
  Widget build(BuildContext context) {
    final dash = controller.dashboard;
    final summary = dash?.summary;
    final goals = dash?.goals ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 780;
        final cols = constraints.maxWidth >= 980 ? 5 : (isWide ? 4 : 3);

        return Container(
          color: MorfinColors.darkBg,
          padding: EdgeInsets.fromLTRB(isWide ? 28 : 18, 16, isWide ? 28 : 18, 18),
          child: Column(
            children: [
              Center(child: Text('Target Keuangan', style: MorfinTheme.display(19, color: Colors.white))),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 9, child: _statBox('${summary?.completedGoals ?? 0}', 'Tercapai', false)),
                        const SizedBox(width: 8),
                        Expanded(flex: 12, child: _statBox('${summary?.activeGoals ?? 0}', 'Berjalan', true)),
                        const SizedBox(width: 8),
                        Expanded(flex: 9, child: _statBox('${summary?.pausedGoals ?? 0}', 'Tertunda', false)),
                      ],
                    ),
                    Positioned(
                      top: -4,
                      right: isWide ? 142 : 78,
                      child: GestureDetector(
                        onTap: onJumpToWallets,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: MorfinColors.pistachio,
                            shape: BoxShape.circle,
                            border: Border.all(color: MorfinColors.darkBg, width: 4),
                          ),
                          child: Icon(Icons.north_east_rounded, size: 16, color: MorfinColors.carbon),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: goals.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada target keuangan.\nTekan tombol + di bawah untuk membuat target pertama.',
                          textAlign: TextAlign.center,
                          style: MorfinTheme.body(13, color: MorfinColors.mutedLight),
                        ),
                      )
                    : GridView.builder(
                        itemCount: goals.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.84,
                        ),
                        itemBuilder: (_, idx) {
                          final g = goals[idx];
                          return HexagonBadge(
                            iconKey: g.icon,
                            unlocked: g.isUnlocked,
                            label: g.title,
                            onTap: () => showGoalDetailSheet(context, controller, g),
                          );
                        },
                      ),
              ),
              Text(
                'Ketuk lencana untuk tambah tabungan atau ubah status target',
                style: MorfinTheme.body(10.5, color: MorfinColors.mutedLight),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MorfinColors.lime,
                      foregroundColor: MorfinColors.carbon,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => showAddGoalSheet(context, controller),
                    child: const Icon(Icons.add_rounded, size: 26),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statBox(String num, String label, bool isMid) => Container(
        height: 122,
        decoration: BoxDecoration(
          color: MorfinColors.lime,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            bottomLeft: const Radius.circular(22),
            bottomRight: const Radius.circular(22),
            topRight: Radius.circular(isMid ? 44 : 22),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(num, style: MorfinTheme.display(32, color: MorfinColors.ink)),
            const SizedBox(height: 6),
            Text(label, style: MorfinTheme.body(11, color: MorfinColors.ink.withValues(alpha: 0.82), weight: FontWeight.w700)),
          ],
        ),
      );
}
