import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';
import '../state/morfin_controller.dart';
import '../widgets/neo_flat_art.dart';

class HomeScreen extends StatelessWidget {
  final MorfinController controller;
  final ValueChanged<int> onNavigateTab;

  const HomeScreen({
    super.key,
    required this.controller,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    final dash = controller.dashboard;
    final summary = dash?.summary;
    final hide = user?.hideBalance ?? false;

    final balanceText = hide ? 'Rp •••••••••' : formatIdr(summary?.totalBalance ?? 0);
    final budgetRem = hide ? 'Rp •••' : formatIdrCompact(summary?.budgetRemaining ?? 0);
    final days = summary?.weeklyDays ?? [];

    return RefreshIndicator(
      color: MorfinColors.carbon,
      backgroundColor: MorfinColors.lime,
      onRefresh: controller.refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          // Top User Row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF6366F1)]),
                  border: Border.all(color: Colors.white, width: 2.2),
                ),
                child: Center(
                  child: Text(
                    (user?.name.isNotEmpty == true ? user!.name[0] : 'M').toUpperCase(),
                    style: MorfinTheme.display(18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Pengguna MorFin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MorfinTheme.display(17),
                    ),
                    Text(
                      'Keuangan Sehat · ${user?.authProvider == 'google' ? 'Google OAuth' : 'Email Sync'}',
                      style: MorfinTheme.body(11.5, color: MorfinColors.muted, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(color: MorfinColors.ink.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Text(
                  '+${summary?.savingsRate ?? 0}%',
                  style: MorfinTheme.display(12, color: MorfinColors.ink),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Keluar Akun',
                onPressed: controller.logout,
                icon: const Icon(Icons.logout_rounded, size: 20, color: MorfinColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notched Dark Balance & Weekly Budget Check Card
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: MorfinColors.carbon,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Saldo Bersih', style: MorfinTheme.body(11.5, color: MorfinColors.mutedLight, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(balanceText, style: MorfinTheme.display(22, color: Colors.white)),
                    const SizedBox(height: 14),
                    Row(
                      children: days.map((d) {
                        final isDone = d.status == 'done';
                        final isToday = d.status == 'today';
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDone
                                        ? MorfinColors.lime
                                        : isToday
                                            ? Colors.transparent
                                            : const Color(0xFFE3E8DF),
                                    border: isToday ? Border.all(color: MorfinColors.carbon, width: 2) : null,
                                  ),
                                  child: Center(
                                    child: isToday
                                        ? Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(color: MorfinColors.carbon, shape: BoxShape.circle),
                                          )
                                        : Icon(
                                            Icons.check_rounded,
                                            size: 13,
                                            color: isDone ? Colors.white : MorfinColors.mutedLight,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  d.label,
                                  style: MorfinTheme.body(
                                    9.5,
                                    color: isDone || isToday ? MorfinColors.ink : MorfinColors.mutedLight,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              // Top-right organic notch cutout with privacy toggle switch
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 82,
                  height: 38,
                  padding: const EdgeInsets.fromLTRB(8, 0, 2, 4),
                  decoration: const BoxDecoration(
                    color: MorfinColors.pistachio,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20)),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: controller.toggleHideBalance,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 64,
                        height: 30,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 220),
                          alignment: hide ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hide ? MorfinColors.carbon : MorfinColors.lime,
                            ),
                            child: Icon(
                              hide ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Two Square Bento Feature Cards
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onNavigateTab(1),
                  child: Container(
                    height: 144,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: MorfinColors.lime,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Anggaran', style: MorfinTheme.display(15)),
                            Text('Sisa $budgetRem', style: MorfinTheme.body(11, color: MorfinColors.ink.withValues(alpha: 0.72), weight: FontWeight.w700)),
                          ],
                        ),
                        Container(
                          height: 68,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: MorfinColors.carbon,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 34,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: MorfinColors.gold,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(child: Text('Rp', style: MorfinTheme.display(12))),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${summary?.budgetHealthPercent ?? 72}%', style: MorfinTheme.display(16, color: MorfinColors.lime)),
                                  Text('Terkendali', style: MorfinTheme.body(9.5, color: MorfinColors.mutedLight)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => onNavigateTab(3),
                  child: Container(
                    height: 144,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: MorfinColors.carbon,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${summary?.hematStreakDays ?? 25}', style: MorfinTheme.display(36, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(
                                'Hari Hemat\nTanpa Boncos',
                                style: MorfinTheme.body(11, color: MorfinColors.mutedLight, weight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Positioned(right: -6, bottom: -10, child: FlameStreakArt(size: 80)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bottom White Cashflow Board (Gantt style matching reference Task Board)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Arus Kas Mingguan', style: MorfinTheme.display(15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _legendDot(MorfinColors.lime, 'Pemasukan'),
                            const SizedBox(width: 12),
                            _legendDot(MorfinColors.carbon, 'Pengeluaran'),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: MorfinColors.carbon,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('Today', style: MorfinTheme.body(10.5, color: Colors.white, weight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ganttBar(leftFrac: 0.02, widthFrac: 0.36, isLime: true),
                _ganttBar(leftFrac: 0.14, widthFrac: 0.44, isLime: true),
                _ganttBar(leftFrac: 0.24, widthFrac: 0.54, isLime: false),
                _ganttBar(leftFrac: 0.06, widthFrac: 0.66, isLime: true),
                _ganttBar(leftFrac: 0.34, widthFrac: 0.56, isLime: false),
                _ganttBar(leftFrac: 0.10, widthFrac: 0.80, isLime: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: MorfinTheme.body(10.5, color: MorfinColors.muted, weight: FontWeight.w600)),
        ],
      );

  Widget _ganttBar({required double leftFrac, required double widthFrac, required bool isLime}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            children: [
              Container(height: 12, decoration: BoxDecoration(color: MorfinColors.pistachio, borderRadius: BorderRadius.circular(6))),
              Positioned(
                left: w * leftFrac,
                child: Container(
                  width: w * widthFrac,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isLime ? MorfinColors.lime : MorfinColors.carbon,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
