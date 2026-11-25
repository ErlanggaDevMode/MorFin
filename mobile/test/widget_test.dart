import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morfin/main.dart';
import 'package:morfin/screens/duolingo_splash_screen.dart';
import 'package:morfin/state/morfin_controller.dart';
import 'package:morfin/widgets/morfin_status_notify.dart';
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
}
