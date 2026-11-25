import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/morfin_theme.dart';
import '../models/morfin_models.dart';
import '../state/morfin_controller.dart';
import '../widgets/add_sheets.dart';
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
    final cashflowBars = summary?.weeklyCashflowBars ?? [];
    final monthLabel = DateFormat('MMM yyyy').format(DateTime.now());

    return RefreshIndicator(
      color: MorfinColors.carbon,
      backgroundColor: MorfinColors.lime,
      onRefresh: controller.refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          // Top User Row (tap to open Profile & Export/Reset Sheet)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => showProfileSheet(context, controller),
                  child: Row(
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
                              'Keuangan Sehat · $monthLabel',
                              style: MorfinTheme.body(11.5, color: MorfinColors.muted, weight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Catat Cepat',
                onPressed: () => showAddTransactionSheet(context, controller),
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: MorfinColors.carbon, shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded, size: 18, color: MorfinColors.lime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notched Dark Balance & Weekly Budget Check Card
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                          child: GestureDetector(
                            onTap: () => showMorfinToast(
                              context,
                              isDone
                                  ? '${d.label}: Pengeluaran dalam batas aman'
                                  : isToday
                                      ? '${d.label} (Hari ini): Pantau anggaran harianmu'
                                      : '${d.label}: Belum dimulai',
                            ),
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
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
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
                                  Text('${summary?.budgetHealthPercent ?? 100}%', style: MorfinTheme.display(16, color: MorfinColors.lime)),
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

          // Live Cashflow Board (driven by actual transactions!)
          GestureDetector(
            onTap: () => onNavigateTab(2),
            child: Container(
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
                          Text('Arus Kas Terbaru', style: MorfinTheme.display(15)),
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
                        child: Text(DateFormat('dd MMM').format(DateTime.now()), style: MorfinTheme.body(10.5, color: Colors.white, weight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (cashflowBars.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text('Belum ada arus kas. Tekan + untuk mulai mencatat.', style: MorfinTheme.body(12, color: MorfinColors.muted)),
                      ),
                    )
                  else
                    ...cashflowBars.map((bar) => _ganttBar(context, bar, hide)),
                ],
              ),
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

  Widget _ganttBar(BuildContext context, CashflowBarItem bar, bool hide) {
    return GestureDetector(
      onTap: () {
        if (bar.amount > 0) {
          showMorfinToast(
            context,
            '${bar.label}: ${bar.isIncome ? '+' : '-'}${hide ? 'Rp •••' : formatIdr(bar.amount)}',
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              children: [
                Container(height: 12, decoration: BoxDecoration(color: MorfinColors.pistachio, borderRadius: BorderRadius.circular(6))),
                Positioned(
                  left: w * bar.leftFrac,
                  child: Container(
                    width: w * bar.widthFrac,
                    height: 12,
                    decoration: BoxDecoration(
                      color: bar.isIncome ? MorfinColors.lime : MorfinColors.carbon,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
