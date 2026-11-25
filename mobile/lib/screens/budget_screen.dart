import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        children: [
          Center(child: Text('Anggaran', style: MorfinTheme.display(18))),
          const SizedBox(height: 16),

          // 4 Circular Period Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _periods.map((entry) {
              final active = period == entry.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.setBudgetPeriod(entry.$1),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? MorfinColors.lime : Colors.white,
                      boxShadow: active
                          ? [BoxShadow(color: MorfinColors.lime.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 6))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        entry.$2,
                        style: MorfinTheme.body(11, color: active ? MorfinColors.ink : MorfinColors.muted, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Hero Dark Trophy Card
          Container(
            height: 146,
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
                                width: 170,
                                child: Text(
                                  'Sisa $savedPct% ruang aman anggaran periode ini',
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
          const SizedBox(height: 16),

          // Alternating Matcha-Lime Budget Cards (tap to Edit / Delete)
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada anggaran untuk periode ini.\nTekan tombol + di bawah untuk membuat.',
                      textAlign: TextAlign.center,
                      style: MorfinTheme.body(13, color: MorfinColors.muted),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, idx) {
                      final b = items[idx];
                      final tagOnLeft = idx.isOdd;
                      final over = b.spentAmount > b.limitAmount;
                      final inner = Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6FAEF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.name, style: MorfinTheme.body(13, weight: FontWeight.w700)),
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
                    },
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MorfinColors.carbon,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => showAddBudgetSheet(context, controller),
              child: const Icon(Icons.add_rounded, size: 26),
            ),
          ),
        ],
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
