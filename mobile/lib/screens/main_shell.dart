import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';
import '../state/morfin_controller.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';

class MainShell extends StatefulWidget {
  final MorfinController controller;
  const MainShell({super.key, required this.controller});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  int _txInitialSubTab = 0;

  @override
  Widget build(BuildContext context) {
    final isDarkTab = _tab == 3;
    final pages = [
      HomeScreen(
        controller: widget.controller,
        onNavigateTab: (idx) => setState(() => _tab = idx),
      ),
      BudgetScreen(controller: widget.controller),
      TransactionsScreen(
        key: ValueKey('tx-$_txInitialSubTab'),
        controller: widget.controller,
        initialSubTab: _txInitialSubTab,
      ),
      GoalsScreen(
        controller: widget.controller,
        onJumpToWallets: () => setState(() {
          _txInitialSubTab = 1;
          _tab = 2;
        }),
      ),
    ];

    return Scaffold(
      backgroundColor: isDarkTab ? MorfinColors.darkBg : MorfinColors.pistachio,
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: Container(
        color: isDarkTab ? MorfinColors.darkBg : MorfinColors.pistachio,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isDarkTab ? const Color(0xFF1C201C) : MorfinColors.carbon,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navBtn(0, Icons.grid_view_rounded, 'Beranda'),
              _navBtn(1, Icons.pie_chart_rounded, 'Anggaran'),
              _navBtn(2, Icons.swap_vert_rounded, 'Transaksi'),
              _navBtn(3, Icons.emoji_events_rounded, 'Target'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(int idx, IconData icon, String label) {
    final active = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() {
        if (idx == 2) _txInitialSubTab = 0;
        _tab = idx;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: active ? 14 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? MorfinColors.lime : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: active ? MorfinColors.ink : Colors.white70),
            if (active) ...[
              const SizedBox(width: 6),
              Text(label, style: MorfinTheme.body(12, color: MorfinColors.ink, weight: FontWeight.w800)),
            ],
          ],
        ),
      ),
    );
  }
}
