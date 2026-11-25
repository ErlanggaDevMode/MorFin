import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';
import '../state/morfin_controller.dart';
import '../widgets/add_sheets.dart';
import '../widgets/morfin_tour_overlay.dart';
import 'budget_screen.dart';
import 'duolingo_splash_screen.dart';
import 'goals_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
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

  final GlobalKey _tourBalanceKey = GlobalKey();
  final GlobalKey _tourQuickAddKey = GlobalKey();
  final GlobalKey _tourWalletsKey = GlobalKey();
  final List<GlobalKey> _tourNavKeys = List.generate(5, (_) => GlobalKey());

  static const _navItems = [
    (Icons.grid_view_rounded, 'Beranda'),
    (Icons.pie_chart_rounded, 'Anggaran'),
    (Icons.swap_vert_rounded, 'Transaksi'),
    (Icons.emoji_events_rounded, 'Target'),
    (Icons.settings_rounded, 'Setting'),
  ];

  List<MorfinTourStep> _buildTourSteps() => [
        MorfinTourStep(
          targetKey: _tourBalanceKey,
          title: 'Total Saldo & Privasi',
          description: 'Pantau saldo bersih dan disiplin harianmu. Ketuk tombol mata di pojok kartu untuk menyembunyikan nominal kapan saja.',
          borderRadius: 24,
        ),
        MorfinTourStep(
          targetKey: _tourQuickAddKey,
          title: 'Catat Transaksi Cepat',
          description: 'Ketuk tombol + ini untuk mencatat pemasukan atau pengeluaran baru hanya dalam beberapa detik.',
          borderRadius: 99,
        ),
        MorfinTourStep(
          targetKey: _tourWalletsKey,
          title: 'Kantong & Dompet',
          description: 'Pisahkan uang ke beberapa kantong (Cash, Bank, E-Wallet) agar alokasi danamu selalu rapi dan terpantau.',
          borderRadius: 20,
        ),
        MorfinTourStep(
          targetKey: _tourNavKeys[1],
          title: 'Menu Anggaran',
          description: 'Atur batas pengeluaran harian, mingguan, atau bulanan supaya keuangan tetap aman tanpa boncos.',
          borderRadius: 16,
        ),
        MorfinTourStep(
          targetKey: _tourNavKeys[2],
          title: 'Riwayat Transaksi',
          description: 'Lihat catatan harian, grafik per kategori, serta kelola seluruh daftar transaksi dan kantongmu di sini.',
          borderRadius: 16,
        ),
        MorfinTourStep(
          targetKey: _tourNavKeys[3],
          title: 'Target Tabungan',
          description: 'Buat target impian seperti Dana Darurat atau beli barang, lalu pantau progres pencapaiannya.',
          borderRadius: 16,
        ),
        MorfinTourStep(
          targetKey: _tourNavKeys[4],
          title: 'Pengaturan & Ekspor',
          description: 'Ubah gaya warna aplikasi, ekspor laporan ke PNG atau PDF, hingga ulangi tur panduan ini kapan saja.',
          borderRadius: 16,
        ),
      ];

  void _selectTab(int idx) {
    setState(() {
      if (idx == 2 && _tab != 2) _txInitialSubTab = 0;
      _tab = idx;
    });
  }

  Widget _buildActivePage() {
    switch (_tab) {
      case 0:
        return HomeScreen(
          key: const ValueKey('tab_home'),
          controller: widget.controller,
          onNavigateTab: _selectTab,
          onJumpToWallets: () => setState(() {
            _txInitialSubTab = 1;
            _tab = 2;
          }),
          tourBalanceKey: _tourBalanceKey,
          tourQuickAddKey: _tourQuickAddKey,
          tourWalletsKey: _tourWalletsKey,
        );
      case 1:
        return BudgetScreen(
          key: const ValueKey('tab_budget'),
          controller: widget.controller,
        );
      case 2:
        return TransactionsScreen(
          key: ValueKey('tab_tx_$_txInitialSubTab'),
          controller: widget.controller,
          initialSubTab: _txInitialSubTab,
        );
      case 3:
        return GoalsScreen(
          key: const ValueKey('tab_goals'),
          controller: widget.controller,
          onJumpToWallets: () => setState(() {
            _txInitialSubTab = 1;
            _tab = 2;
          }),
        );
      default:
        return SettingsScreen(
          key: const ValueKey('tab_settings'),
          controller: widget.controller,
          onStartTour: () {
            setState(() => _tab = 0);
            widget.controller.startTour();
          },
        );
    }
  }

  Widget _animatedPageBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: _buildActivePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTab = _tab == 3;
    final bgColor = isDarkTab ? MorfinColors.darkBg : MorfinColors.pistachio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 860;

        if (isDesktop) {
          // True Responsive Web / Desktop Sidebar Shell
          final user = widget.controller.user;
          final desktopScaffold = Scaffold(
            backgroundColor: bgColor,
            body: Row(
              children: [
                // Left Carbon Navigation Sidebar
                Container(
                  width: 244,
                  color: MorfinColors.carbon,
                  padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          MorfinLogoBox(
                            size: 40,
                            boxColor: MorfinColors.lime,
                            strokeColor: MorfinColors.carbon,
                          ),
                          const SizedBox(width: 11),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('morfin', style: MorfinTheme.body(21, color: Colors.white, weight: FontWeight.w800)),
                              Text('Finance Tracker', style: MorfinTheme.body(10.5, color: MorfinColors.mutedLight)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MorfinColors.lime,
                            foregroundColor: MorfinColors.ink,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => showAddTransactionSheet(context, widget.controller),
                          icon: const Icon(Icons.add_rounded, size: 19),
                          label: Text('Catat Transaksi', style: MorfinTheme.display(13)),
                        ),
                      ),
                      const SizedBox(height: 22),
                      ...List.generate(_navItems.length, (i) {
                        final active = _tab == i;
                        final item = _navItems[i];
                        return Padding(
                          key: _tourNavKeys[i],
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _selectTab(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: active ? MorfinColors.lime : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(item.$1, size: 20, color: active ? MorfinColors.ink : Colors.white70),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.$2,
                                    style: MorfinTheme.body(
                                      13.5,
                                      color: active ? MorfinColors.ink : Colors.white70,
                                      weight: active ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _selectTab(4),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: MorfinColors.lime,
                                child: Text(
                                  (user?.name.isNotEmpty == true ? user!.name[0] : 'M').toUpperCase(),
                                  style: MorfinTheme.display(14, color: MorfinColors.ink),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.name ?? 'Pengguna',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: MorfinTheme.body(12.5, color: Colors.white, weight: FontWeight.w700),
                                    ),
                                    Text(
                                      user?.email ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: MorfinTheme.body(10, color: MorfinColors.mutedLight),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content Workspace (centered max 1180px for ultra-clean desktop readability)
                Expanded(
                  child: SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: _animatedPageBody(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
          return Stack(
            children: [
              desktopScaffold,
              if (widget.controller.shouldShowTour && _tab == 0)
                MorfinTourOverlay(
                  steps: _buildTourSteps(),
                  onFinished: widget.controller.completeTour,
                ),
            ],
          );
        }

        // Mobile & Compact Layout with sleek 5-tab floating Carbon Bottom Nav
        final mobileScaffold = Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(child: _animatedPageBody()),
          bottomNavigationBar: Container(
            color: bgColor,
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
            child: Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkTab ? const Color(0xFF1C201C) : MorfinColors.carbon,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(_navItems.length, (i) {
                  final active = _tab == i;
                  final item = _navItems[i];
                  return Expanded(
                    child: GestureDetector(
                      key: _tourNavKeys[i],
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _selectTab(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                        decoration: BoxDecoration(
                          color: active ? MorfinColors.lime : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.$1,
                              size: 20,
                              color: active ? MorfinColors.ink : Colors.white70,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item.$2,
                                maxLines: 1,
                                style: MorfinTheme.body(
                                  10,
                                  color: active ? MorfinColors.ink : Colors.white70,
                                  weight: active ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
        return Stack(
          children: [
            mobileScaffold,
            if (widget.controller.shouldShowTour && _tab == 0)
              MorfinTourOverlay(
                steps: _buildTourSteps(),
                onFinished: widget.controller.completeTour,
              ),
          ],
        );
      },
    );
  }
}
