import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/morfin_theme.dart';
import '../models/morfin_models.dart';
import '../state/morfin_controller.dart';
import '../widgets/add_sheets.dart';
import '../widgets/morfin_status_notify.dart';
import '../widgets/tx_chatbot_view.dart';

class TransactionsScreen extends StatefulWidget {
  final MorfinController controller;
  final int initialSection; // 0 = Chat AI (default), 1 = Manual (kanan)
  final int initialSubTab;
  const TransactionsScreen({
    super.key,
    required this.controller,
    this.initialSection = 0,
    this.initialSubTab = 0,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late int _section;
  late int subTab;
  late final PageController _pageCtrl;
  int? frontWalletIdx;
  String _search = '';
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    subTab = widget.initialSubTab;
    _pageCtrl = PageController(initialPage: _section);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _slideToSection(int target) {
    if (_section == target) return;
    setState(() => _section = target);
    _pageCtrl.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildModeSlider() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MorfinColors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: _section == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: MorfinColors.carbon,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: MorfinColors.carbon.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _slideToSection(0),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: _section == 0 ? MorfinColors.lime : MorfinColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Chat AI',
                          style: MorfinTheme.display(
                            12.5,
                            color: _section == 0 ? Colors.white : MorfinColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _slideToSection(1),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.view_list_rounded,
                          size: 15,
                          color: _section == 1 ? MorfinColors.lime : MorfinColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Manual',
                          style: MorfinTheme.display(
                            12.5,
                            color: _section == 1 ? Colors.white : MorfinColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dash = widget.controller.dashboard;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 28 : 18, 14, isWide ? 28 : 18, 0),
          child: Column(
            children: [
              if (isWide)
                Row(
                  children: [
                    Text(
                      _section == 0 ? 'Chat AI Pencatat' : 'Transaksi & Kantong Tabungan',
                      style: MorfinTheme.display(20),
                    ),
                    const Spacer(),
                    SizedBox(width: 280, child: _buildModeSlider()),
                  ],
                )
              else ...[
                Center(child: Text('Transaksi', style: MorfinTheme.display(18))),
                const SizedBox(height: 12),
                _buildModeSlider(),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  onPageChanged: (idx) => setState(() => _section = idx),
                  children: [
                    // Slide 0 (Kiri - Default): Chat AI + Voice Recording + Photo Receipt Scanner
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isWide ? 760 : double.infinity),
                        child: TxChatbotView(controller: widget.controller),
                      ),
                    ),

                    // Slide 1 (Kanan): Manual Transaksi (Harian + Kategori + Kantong Tabungan)
                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 12,
                                child: _buildDailyTimeline(context, dash?.transactions ?? []),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 10,
                                child: _buildCategoryAndWallets(
                                  context,
                                  dash?.summary.categoryBars ?? [],
                                  dash?.wallets ?? [],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
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
                              const SizedBox(height: 12),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  switchInCurve: Curves.easeOutCubic,
                                  child: subTab == 0
                                      ? KeyedSubtree(
                                          key: const ValueKey('tx_daily'),
                                          child: _buildDailyTimeline(context, dash?.transactions ?? []),
                                        )
                                      : KeyedSubtree(
                                          key: const ValueKey('tx_cat'),
                                          child: _buildCategoryAndWallets(
                                            context,
                                            dash?.summary.categoryBars ?? [],
                                            dash?.wallets ?? [],
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _segTab(String label, int idx) {
    final active = subTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => subTab = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: MorfinTheme.body(12.5),
                decoration: InputDecoration(
                  hintText: 'Cari transaksi...',
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: MorfinColors.muted),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  filled: true,
                  fillColor: MorfinColors.surfaceWhite,
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
                        : 'Tidak ada transaksi yang cocok.',
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
                      onDismissed: (_) async {
                        try {
                          await widget.controller.deleteTransaction(tx.id);
                          if (context.mounted) {
                            showMorfinStatusNotify(
                              context,
                              isSuccess: true,
                              title: 'Dihapus!',
                              message: 'Transaksi "${tx.title}" berhasil dihapus.',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showMorfinStatusNotify(
                              context,
                              isSuccess: false,
                              title: 'Gagal Menghapus!',
                              message: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
                            );
                          }
                        }
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
                                    decoration: BoxDecoration(color: MorfinColors.carbon, shape: BoxShape.circle),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: active ? MorfinColors.carbon : MorfinColors.surfaceWhite,
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
                          decoration: BoxDecoration(color: MorfinColors.lime, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, size: 12, color: MorfinColors.onLime),
                        )
                      : null,
                ),
              ],
            ),
          );
        }),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: MorfinColors.carbon,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                      child: Text('+ Kantong', style: MorfinTheme.body(11, color: MorfinColors.onLime, weight: FontWeight.w800)),
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
          ? [MorfinColors.limeDeep, MorfinColors.lime]
          : i == 1
              ? [const Color(0xFF2D332D), const Color(0xFF444F40)]
              : [MorfinColors.limeDeep.withValues(alpha: 0.9), MorfinColors.lime];

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
