import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morfin/core/theme/morfin_theme.dart';
import 'package:morfin/core/utils/report_exporter.dart';
import 'package:morfin/main.dart';
import 'package:morfin/models/morfin_models.dart';
import 'package:morfin/screens/duolingo_splash_screen.dart';
import 'package:morfin/screens/transactions_screen.dart';
import 'package:morfin/state/morfin_controller.dart';
import 'package:morfin/widgets/morfin_status_notify.dart';
import 'package:morfin/widgets/morfin_tour_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('MorFin renders Duolingo Loading Splash -> Welcome -> Auth cleanly', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final ctrl = MorfinController();

    await tester.pumpWidget(
      MorfinApp(
        controller: ctrl,
        minSplashDuration: const Duration(milliseconds: 600),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    // Kinetic MorFin loading splash visible initially
    expect(find.text('morfin'), findsOneWidget);
    expect(find.byType(MorfinLogoBox), findsOneWidget);

    // Advance past minimum loading splash duration
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Welcome screen visible
    expect(find.text('MorFin'), findsOneWidget);
    expect(find.text("Let's Start"), findsOneWidget);

    // Tap Let's Start arrow to enter Auth Screen
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();

    // Verify Email Login, Register tab, and Google OAuth button exist
    expect(find.text('Masuk ke MorFin'), findsOneWidget);
    expect(find.text('Daftar Baru'), findsOneWidget);
    expect(find.text('Lanjutkan dengan Akun Google'), findsOneWidget);

    // Switch to Daftar Baru tab
    await tester.tap(find.text('Daftar Baru'));
    await tester.pumpAndSettle();
    expect(find.text('Buat Akun MorFin'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
  });

  testWidgets('MorFin status notify shows success/error and dismisses on tap anywhere', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => showMorfinStatusNotify(
                  ctx,
                  isSuccess: true,
                  title: 'Tersimpan!',
                  message: 'Transaksi berhasil dicatat.',
                ),
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trigger'));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Tersimpan!'), findsOneWidget);
    expect(find.text('Transaksi berhasil dicatat.'), findsOneWidget);

    // Tap anywhere on screen (top-left backdrop corner) dismisses notify cleanly
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Tersimpan!'), findsNothing);
  });

  testWidgets('MorFin onboarding tour shows Ikuti Tour / Skip Tour and steps through features', (tester) async {
    final targetKey = GlobalKey();
    bool finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Center(
                child: Container(
                  key: targetKey,
                  width: 180,
                  height: 60,
                  color: Colors.green,
                  child: const Center(child: Text('Kartu Saldo')),
                ),
              ),
              MorfinTourOverlay(
                steps: [
                  MorfinTourStep(
                    targetKey: targetKey,
                    title: 'Total Saldo & Privasi',
                    description: 'Pantau saldo bersihmu di sini.',
                  ),
                ],
                onFinished: () => finished = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Welcome choice modal visible with Ikuti Tour and Skip Tour
    expect(find.text('Ikuti Tour'), findsOneWidget);
    expect(find.text('Skip Tour'), findsOneWidget);

    // Start tour -> focuses step 1 with speech bubble
    await tester.tap(find.text('Ikuti Tour'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('Total Saldo & Privasi'), findsOneWidget);
    expect(find.text('Mulai Pakai'), findsOneWidget);

    // Finish tour
    await tester.tap(find.text('Mulai Pakai'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });

  test('MorfinBudget computes uncapped over-budget percentage and PDF prints Over label', () async {
    const budget = MorfinBudget(
      id: 'b1',
      name: 'Kopi Harian',
      category: 'Makan',
      period: 'daily',
      limitAmount: 25000,
      spentAmount: 50000,
    );

    expect(budget.usedPercent, 200);
    expect(budget.progressRatio, 1.0);
    expect(budget.isOverBudget, isTrue);
    expect(budget.overAmount, 25000);

    final pdfBytes = await ReportExporter.buildPdfBytes(
      user: const MorfinUser(
        id: 'u1',
        email: 'test@morfin.app',
        name: 'Tester',
        authProvider: 'email',
        hideBalance: false,
        currency: 'IDR',
      ),
      dashboard: const DashboardPayload(
        summary: DashboardSummary(
          totalBalance: 0,
          totalIncome: 50000,
          totalExpense: 50000,
          savingsRate: 0,
          hematStreakDays: 0,
          budgetRemaining: 0,
          budgetHealthPercent: 0,
          weeklyDays: [],
          weeklySeries: [],
          weeklyCashflowBars: [],
          categoryBars: [],
          completedGoals: 0,
          activeGoals: 0,
          pausedGoals: 0,
        ),
        transactions: [],
        budgets: [budget],
        wallets: [],
        goals: [],
      ),
      palette: MorfinPalettes.all.first,
    );

    final pdfText = latin1.decode(pdfBytes);
    expect(pdfText, contains(r'200% \(Over Rp 25.000\)'));
  });

  testWidgets('TransactionsScreen defaults to Chat AI on left and slides to Manual on right', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final ctrl = MorfinController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionsScreen(controller: ctrl),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Slider tabs present, Chat AI active by default with mic & receipt scanner buttons
    expect(find.text('Chat AI'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.byIcon(Icons.document_scanner_rounded), findsOneWidget);

    // Slide to Manual on the right
    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();
    expect(find.text('Cari transaksi...'), findsOneWidget);
  });

  test('MorfinController defaults to system ThemeMode and persists dark/light changes', () async {
    SharedPreferences.setMockInitialValues({});
    final ctrl = MorfinController();
    expect(ctrl.themeMode, ThemeMode.system);
    expect(ctrl.themeModeKey, 'system');

    await ctrl.setThemeMode('dark');
    expect(ctrl.themeMode, ThemeMode.dark);
    expect(ctrl.themeModeKey, 'dark');

    await ctrl.setThemeMode('light');
    expect(ctrl.themeMode, ThemeMode.light);
    expect(ctrl.themeModeKey, 'light');
  });
}
