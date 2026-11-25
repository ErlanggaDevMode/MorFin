import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';
import '../models/morfin_models.dart';
import '../state/morfin_controller.dart';
import '../widgets/add_sheets.dart';
import '../widgets/neo_flat_art.dart';

class BudgetScreen extends StatelessWidget {
  final MorfinController controller;
  const BudgetScreen({super.key, required this.controller});

  static const _periods = [
    ('daily', 'Harian'),
    ('weekly', 'Mingguan'),
    ('monthly', 'Bulanan'),
    ('yearly', 'Tahunan'),
  ];

  @override
  Widget build(BuildContext context) {
    final period = controller.selectedBudgetPeriod;
    final allBudgets = controller.dashboard?.budgets ?? [];
    final items = allBudgets.where((b) => b.period == period).toList();
    final totalLimit = items.fold<int>(0, (s, b) => s + b.limitAmount);
    final totalSpent = items.fold<int>(0, (s, b) => s + b.spentAmount);
    final savedPct = totalLimit > 0 ? (((totalLimit - totalSpent) / totalLimit) * 100).clamp(0, 100).round() : 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 780;

        return Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 28 : 18, 14, isWide ? 28 : 18, 18),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Anggaran', style: MorfinTheme.display(20)),
                  TextButton.icon(
                    onPressed: () => showAddBudgetSheet(context, controller),
                    style: TextButton.styleFrom(
                      backgroundColor: MorfinColors.carbon,
                      foregroundColor: MorfinColors.lime,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: Text('Tambah', style: MorfinTheme.body(12, color: MorfinColors.lime, weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4 Period Selector Chips
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _periods.map((entry) {
                    final active = period == entry.$1;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller.setBudgetPeriod(entry.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: isWide ? 48 : 66,
                          decoration: BoxDecoration(
                            shape: isWide ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius: isWide ? BorderRadius.circular(999) : null,
                            color: active ? MorfinColors.lime : Colors.white,
                            boxShadow: active
                                ? [BoxShadow(color: MorfinColors.lime.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 6))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              entry.$2,
                              style: MorfinTheme.body(11.5, color: active ? MorfinColors.ink : MorfinColors.muted, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Hero Dark Trophy Card
              Container(
                height: 144,
                width: double.infinity,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: MorfinColors.carbon,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(savedPct >= 20 ? 'Keep It Up!' : 'Hati-Hati!', style: MorfinTheme.display(20, color: Colors.white)),
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    width: isWide ? 360 : 175,
                                    child: Text(
                                      'Terpakai ${formatIdrCompact(totalSpent)} · Sisa $savedPct% batas periode ini',
                                      style: MorfinTheme.body(11.5, color: MorfinColors.mutedLight),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: MorfinColors.lime,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  formatIdrCompact(totalLimit),
                                  style: MorfinTheme.display(12, color: MorfinColors.ink),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _dot(MorfinColors.lime, 6),
                              _dot(MorfinColors.lime, 6),
                              _dot(MorfinColors.lime, 18),
                              _dot(Colors.white, 6),
                              _dot(Colors.white, 6),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Positioned(right: 6, bottom: -4, child: TrophyCupArt(size: 102)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Budget List / Responsive Grid (with obvious Edit pencil button on every card!)
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada anggaran untuk periode ini.\nTekan tombol + untuk membuat anggaran.',
                          textAlign: TextAlign.center,
                          style: MorfinTheme.body(13, color: MorfinColors.muted),
                        ),
                      )
                    : isWide
                        ? GridView.builder(
                            itemCount: items.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              mainAxisExtent: 106,
                            ),
                            itemBuilder: (_, idx) => _budgetCard(context, items[idx], idx),
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, idx) => _budgetCard(context, items[idx], idx),
                          ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ketuk anggaran atau ikon pensil untuk ubah batas, nominal terpakai, atau hapus',
                textAlign: TextAlign.center,
                style: MorfinTheme.body(10.5, color: MorfinColors.muted),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _budgetCard(BuildContext context, MorfinBudget b, int idx) {
    final tagOnLeft = idx.isOdd;
    final over = b.spentAmount > b.limitAmount;

    final inner = Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    b.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MorfinTheme.body(13, weight: FontWeight.w700),
                  ),
                ),
                InkWell(
                  onTap: () => showAddBudgetSheet(context, controller, existing: b),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.edit_rounded, size: 15, color: MorfinColors.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Terpakai ${b.usedPercent}% · ${formatIdrCompact(b.spentAmount)}',
              style: MorfinTheme.body(
                10.5,
                color: over ? MorfinColors.coral : MorfinColors.muted,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: (b.usedPercent / 100.0).clamp(0.0, 1.0),
                backgroundColor: MorfinColors.ink.withValues(alpha: 0.08),
                color: over ? MorfinColors.coral : MorfinColors.carbon,
              ),
            ),
          ],
        ),
      ),
    );

    final tag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MorfinColors.carbon,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        formatIdrCompact(b.limitAmount),
        style: MorfinTheme.display(12, color: Colors.white),
      ),
    );

    return GestureDetector(
      onTap: () => showAddBudgetSheet(context, controller, existing: b),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: MorfinColors.lime,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: tagOnLeft
              ? [tag, const SizedBox(width: 8), inner]
              : [inner, const SizedBox(width: 8), tag],
        ),
      ),
    );
  }

  Widget _dot(Color color, double w) => Container(
        margin: const EdgeInsets.only(right: 5),
        width: w,
        height: 6,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
      );
}
