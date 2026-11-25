import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/morfin_theme.dart';
import '../models/morfin_models.dart';
import '../state/morfin_controller.dart';
import '../widgets/add_sheets.dart';

class TransactionsScreen extends StatefulWidget {
  final MorfinController controller;
  final int initialSubTab;
  const TransactionsScreen({super.key, required this.controller, this.initialSubTab = 0});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late int subTab;
  int? frontWalletIdx;
  String _search = '';
  String _typeFilter = 'all'; // all | income | expense

  @override
  void initState() {
    super.initState();
    subTab = widget.initialSubTab;
  }

  @override
  Widget build(BuildContext context) {
    final dash = widget.controller.dashboard;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        children: [
          Center(child: Text('Transaksi', style: MorfinTheme.display(18))),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: MorfinColors.ink.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                _segTab('Harian', 0),
                _segTab('Kategori', 1),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: subTab == 0
                ? _buildDailyTimeline(context, dash?.transactions ?? [])
                : _buildCategoryAndWallets(context, dash?.summary.categoryBars ?? [], dash?.wallets ?? []),
          ),
        ],
      ),
    );
  }

  Widget _segTab(String label, int idx) {
    final active = subTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => subTab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? MorfinColors.carbon : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: MorfinTheme.body(12.5, color: active ? Colors.white : MorfinColors.muted, weight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTimeline(BuildContext context, List<MorfinTransaction> allTxs) {
    final q = _search.trim().toLowerCase();
    final txs = allTxs.where((t) {
      if (_typeFilter != 'all' && t.type != _typeFilter) return false;
      if (q.isNotEmpty) {
        return t.title.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q) ||
            t.paymentMethod.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final timeFmt = DateFormat('dd MMM · HH:mm');
    return Column(
      children: [
        // Compact Search & Filter Row
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: MorfinTheme.body(12.5),
                decoration: InputDecoration(
                  hintText: 'Cari transaksi...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: MorfinColors.muted),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _filterPill('Semua', 'all'),
            const SizedBox(width: 4),
            _filterPill('+', 'income'),
            const SizedBox(width: 4),
            _filterPill('-', 'expense'),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: txs.isEmpty
              ? Center(
                  child: Text(
                    allTxs.isEmpty
                        ? 'Belum ada transaksi.\nTekan tombol + di bawah untuk mencatat.'
                        : 'Tidak ada transaksi yang cocok dengan pencarian.',
                    textAlign: TextAlign.center,
                    style: MorfinTheme.body(13, color: MorfinColors.muted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: txs.length + 1,
                  itemBuilder: (_, idx) {
                    if (idx == txs.length) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                        child: Text(
                          'Ketuk kartu untuk edit · Geser kiri untuk hapus',
                          style: MorfinTheme.body(11, color: MorfinColors.muted, weight: FontWeight.w600),
                        ),
                      );
                    }
                    final tx = txs[idx];
                    return Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        widget.controller.deleteTransaction(tx.id);
                        showMorfinToast(context, 'Transaksi dihapus');
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: MorfinColors.coral, borderRadius: BorderRadius.circular(18)),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 18,
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: MorfinColors.carbon, shape: BoxShape.circle),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => showAddTransactionSheet(context, widget.controller, existing: tx),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                                  decoration: BoxDecoration(
                                    color: MorfinColors.carbon,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  timeFmt.format(tx.occurredAt),
                                                  style: MorfinTheme.body(10.5, color: const Color(0xFFB5BFB2), weight: FontWeight.w700),
                                                ),
                                                Text(
                                                  '${tx.isIncome ? '+' : '-'}${formatIdr(tx.amount)}',
                                                  style: MorfinTheme.display(
                                                    13,
                                                    color: tx.isIncome ? MorfinColors.lime : MorfinColors.coralSoft,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              tx.title,
                                              style: MorfinTheme.body(12.5, color: const Color(0xFFEEF3EA), weight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${tx.category} · ${tx.paymentMethod}',
                                              style: MorfinTheme.body(10, color: MorfinColors.mutedLight),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () => widget.controller.toggleTxVerified(tx),
                                        child: Container(
                                          width: 28,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: tx.verified ? MorfinColors.lime : const Color(0xFF333833),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: tx.verified ? MorfinColors.ink : MorfinColors.mutedLight,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 6),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MorfinColors.carbon,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => showAddTransactionSheet(context, widget.controller),
              child: const Icon(Icons.add_rounded, size: 26),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterPill(String label, String key) {
    final active = _typeFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _typeFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: active ? MorfinColors.carbon : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: MorfinTheme.body(11.5, color: active ? MorfinColors.lime : MorfinColors.ink, weight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildCategoryAndWallets(BuildContext context, List<CategoryBarItem> bars, List<MorfinWallet> wallets) {
    return Column(
      children: [
        ...bars.take(7).map((bar) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 68,
                  child: Text(
                    bar.name,
                    textAlign: TextAlign.right,
                    style: MorfinTheme.body(11, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: MorfinColors.ink.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (bar.percent / 100.0).clamp(0.10, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bar.healthy ? MorfinColors.lime : MorfinColors.carbon,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  child: bar.healthy
                      ? Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(color: MorfinColors.lime, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, size: 12, color: MorfinColors.ink),
                        )
                      : null,
                ),
              ],
            ),
          );
        }),
        const Spacer(),

        // Bottom Dark Sheet with Interactive Stacked Overlapping Wallet Cards + Add Wallet button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: MorfinColors.carbon,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kantong Tabungan', style: MorfinTheme.display(13.5, color: Colors.white)),
                  GestureDetector(
                    onTap: () => showAddWalletSheet(context, widget.controller),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MorfinColors.lime,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('+ Kantong', style: MorfinTheme.body(11, color: MorfinColors.ink, weight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 224,
                child: wallets.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada kantong tabungan.\nTekan "+ Kantong" untuk membuat.',
                          textAlign: TextAlign.center,
                          style: MorfinTheme.body(12.5, color: MorfinColors.mutedLight),
                        ),
                      )
                    : Stack(
                        clipBehavior: Clip.none,
                        children: _orderedWalletWidgets(context, wallets),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _orderedWalletWidgets(BuildContext context, List<MorfinWallet> wallets) {
    final visible = wallets.take(3).toList();
    final indices = List<int>.generate(visible.length, (i) => i);
    if (frontWalletIdx != null && frontWalletIdx! < visible.length) {
      indices.remove(frontWalletIdx);
      indices.add(frontWalletIdx!);
    }

    return indices.map((i) {
      final w = visible[i];
      final isFront = frontWalletIdx == i;
      final topOffset = i * 54.0 - (isFront ? 10.0 : 0.0);
      final colors = i == 0
          ? [const Color(0xFF88AA3C), const Color(0xFFA4CA52)]
          : i == 1
              ? [const Color(0xFF2D332D), const Color(0xFF48543D)]
              : [const Color(0xFF749630), const Color(0xFF9CC24B)];

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        top: topOffset,
        left: 0,
        right: 0,
        child: GestureDetector(
          onTap: () => setState(() => frontWalletIdx = isFront ? null : i),
          onDoubleTap: () => showTopUpWalletSheet(context, widget.controller, w),
          child: Container(
            height: 116,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
              borderRadius: BorderRadius.circular(20),
              border: i == 1 ? Border.all(color: MorfinColors.lime.withValues(alpha: 0.35)) : null,
              boxShadow: isFront
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.42), blurRadius: 20, offset: const Offset(0, 8))]
                  : null,
            ),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.24), shape: BoxShape.circle),
                      child: Icon(_walletIcon(w.icon), size: 17, color: i == 1 ? MorfinColors.lime : Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.name, style: MorfinTheme.display(14, color: Colors.white)),
                          Text(
                            'Target: ${formatIdrCompact(w.targetAmount)} · ${formatIdrCompact(w.currentAmount)}',
                            style: MorfinTheme.body(10.5, color: Colors.white.withValues(alpha: 0.88)),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => showTopUpWalletSheet(context, widget.controller, w),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('Kelola', style: MorfinTheme.body(10, color: Colors.white, weight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 2,
                  bottom: -4,
                  child: Text(
                    '${w.progressPercent}%',
                    style: MorfinTheme.display(36, color: Colors.white.withValues(alpha: 0.92)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  IconData _walletIcon(String icon) {
    switch (icon) {
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'chart':
        return Icons.trending_up_rounded;
      default:
        return Icons.verified_user_rounded;
    }
  }
}
