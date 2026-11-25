import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/morfin_theme.dart';
import '../models/morfin_models.dart';
import '../state/morfin_controller.dart';
import '../widgets/add_sheets.dart';
import '../widgets/neo_flat_art.dart';

class HomeScreen extends StatefulWidget {
  final MorfinController controller;
  final ValueChanged<int> onNavigateTab;

  const HomeScreen({
    super.key,
    required this.controller,
    required this.onNavigateTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedDayIndex;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final user = controller.user;
    final dash = controller.dashboard;
    final summary = dash?.summary;
    final hide = user?.hideBalance ?? false;

    final balanceText = hide ? 'Rp •••••••••' : formatIdr(summary?.totalBalance ?? 0);
    final budgetRem = hide ? 'Rp •••' : formatIdrCompact(summary?.budgetRemaining ?? 0);
    final days = summary?.weeklyDays ?? [];
    final series = summary?.weeklySeries ?? [];
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 820;

        final header = _buildHeader(context, user, summary, monthLabel);
        final leftColumn = Column(
          children: [
            _buildNotchedBalanceCard(context, controller, balanceText, days, hide),
            const SizedBox(height: 14),
            _buildBentoCards(budgetRem, summary),
          ],
        );
        final rightColumn = _buildWeeklyCashflowChart(context, series, summary, hide);

        return RefreshIndicator(
          color: MorfinColors.carbon,
          backgroundColor: MorfinColors.lime,
          onRefresh: controller.refreshDashboard,
          child: ListView(
            padding: EdgeInsets.fromLTRB(isWide ? 28 : 18, 16, isWide ? 28 : 18, 28),
            children: [
              header,
              const SizedBox(height: 18),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 11, child: leftColumn),
                    const SizedBox(width: 20),
                    Expanded(flex: 12, child: rightColumn),
                  ],
                )
              else ...[
                leftColumn,
                const SizedBox(height: 14),
                rightColumn,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, MorfinUser? user, DashboardSummary? summary, String monthLabel) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => widget.onNavigateTab(4),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [MorfinColors.lime, MorfinColors.limeDeep]),
                    border: Border.all(color: Colors.white, width: 2.2),
                  ),
                  child: Center(
                    child: Text(
                      (user?.name.isNotEmpty == true ? user!.name[0] : 'M').toUpperCase(),
                      style: MorfinTheme.display(18, color: MorfinColors.ink),
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
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Catat Transaksi',
          onPressed: () => showAddTransactionSheet(context, widget.controller),
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: MorfinColors.carbon, shape: BoxShape.circle),
            child: Icon(Icons.add_rounded, size: 19, color: MorfinColors.lime),
          ),
        ),
      ],
    );
  }

  Widget _buildNotchedBalanceCard(
    BuildContext context,
    MorfinController controller,
    String balanceText,
    List<WeeklyDayStatus> days,
    bool hide,
  ) {
    return Stack(
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  balanceText,
                  key: ValueKey(balanceText),
                  style: MorfinTheme.display(23, color: Colors.white),
                ),
              ),
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
                                        decoration: BoxDecoration(color: MorfinColors.carbon, shape: BoxShape.circle),
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
            decoration: BoxDecoration(
              color: MorfinColors.pistachio,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)),
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
    );
  }

  Widget _buildBentoCards(String budgetRem, DashboardSummary? summary) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => widget.onNavigateTab(1),
            child: Container(
              height: 148,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MorfinColors.lime,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Anggaran', style: MorfinTheme.display(15)),
                          Text('Sisa $budgetRem', style: MorfinTheme.body(11, color: MorfinColors.ink.withValues(alpha: 0.75), weight: FontWeight.w700)),
                        ],
                      ),
                      Icon(Icons.edit_outlined, size: 16, color: MorfinColors.ink.withValues(alpha: 0.7)),
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
            onTap: () => widget.onNavigateTab(3),
            child: Container(
              height: 148,
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
    );
  }

  /// Upgraded 7-Day Interactive Vertical Bar Chart (Sen..Min) with real daily totals & day detail panel!
  Widget _buildWeeklyCashflowChart(
    BuildContext context,
    List<WeeklyDayFlow> rawSeries,
    DashboardSummary? summary,
    bool hide,
  ) {
    final series = rawSeries.isNotEmpty
        ? rawSeries
        : const [
            WeeklyDayFlow(label: 'Sen', date: '', income: 0, expense: 0, isToday: false),
            WeeklyDayFlow(label: 'Sel', date: '', income: 0, expense: 0, isToday: false),
            WeeklyDayFlow(label: 'Rab', date: '', income: 0, expense: 0, isToday: false),
            WeeklyDayFlow(label: 'Kam', date: '', income: 0, expense: 0, isToday: false),
            WeeklyDayFlow(label: 'Jum', date: '', income: 0, expense: 0, isToday: false),
            WeeklyDayFlow(label: 'Sab', date: '', income: 0, expense: 0, isToday: false),
            WeeklyDayFlow(label: 'Min', date: '', income: 0, expense: 0, isToday: false),
          ];

    final todayIdx = series.indexWhere((d) => d.isToday);
    final activeIdx = _selectedDayIndex != null && _selectedDayIndex! < series.length
        ? _selectedDayIndex!
        : (todayIdx >= 0 ? todayIdx : 0);
    final selectedDay = series[activeIdx];

    final weekIncome = series.fold<int>(0, (s, d) => s + d.income);
    final weekExpense = series.fold<int>(0, (s, d) => s + d.expense);
    final maxVal = math.max(
      1,
      series.fold<int>(0, (m, d) => math.max(m, math.max(d.income, d.expense))),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: MorfinColors.ink.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
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
                  Text('Arus Kas Mingguan', style: MorfinTheme.display(16)),
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
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: MorfinColors.carbon,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  DateFormat('dd MMM').format(DateTime.now()),
                  style: MorfinTheme.body(10.5, color: MorfinColors.lime, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Weekly Total Pills
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: MorfinColors.pistachio,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Masuk Minggu Ini', style: MorfinTheme.body(10, color: MorfinColors.muted, weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        hide ? 'Rp •••' : '+${formatIdrCompact(weekIncome)}',
                        style: MorfinTheme.display(13.5, color: MorfinColors.limeDeep),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: MorfinColors.pistachio,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Keluar Minggu Ini', style: MorfinTheme.body(10, color: MorfinColors.muted, weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        hide ? 'Rp •••' : '-${formatIdrCompact(weekExpense)}',
                        style: MorfinTheme.display(13.5, color: MorfinColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 7-Day Paired Vertical Bar Chart
          SizedBox(
            height: 148,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(series.length, (i) {
                final day = series[i];
                final isSelected = i == activeIdx;
                final incH = day.income > 0 ? math.max(12.0, (day.income / maxVal) * 104.0) : 6.0;
                final expH = day.expense > 0 ? math.max(12.0, (day.expense / maxVal) * 104.0) : 6.0;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedDayIndex = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              width: 11,
                              height: incH,
                              decoration: BoxDecoration(
                                color: day.income > 0 ? MorfinColors.lime : MorfinColors.pistachio,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 3),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              width: 11,
                              height: expH,
                              decoration: BoxDecoration(
                                color: day.expense > 0 ? MorfinColors.carbon : MorfinColors.ink.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected ? MorfinColors.carbon : Colors.transparent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            day.label,
                            style: MorfinTheme.body(
                              10,
                              color: isSelected ? MorfinColors.lime : MorfinColors.muted,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Selected Day Detail Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: MorfinColors.carbon,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedDay.label}${selectedDay.isToday ? " · Hari Ini" : ""}',
                  style: MorfinTheme.display(12, color: Colors.white),
                ),
                Row(
                  children: [
                    Text(
                      hide ? '+Rp •••' : '+${formatIdrCompact(selectedDay.income)}',
                      style: MorfinTheme.body(11.5, color: MorfinColors.lime, weight: FontWeight.w700),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      hide ? '-Rp •••' : '-${formatIdrCompact(selectedDay.expense)}',
                      style: MorfinTheme.body(11.5, color: MorfinColors.coralSoft, weight: FontWeight.w700),
                    ),
                  ],
                ),
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
}
