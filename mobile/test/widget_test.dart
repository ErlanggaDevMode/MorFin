import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morfin/main.dart';
import 'package:morfin/state/morfin_controller.dart';
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

    // Duolingo-style loading splash visible initially
    expect(find.text('MorFin'), findsOneWidget);
    expect(find.text('SMART FINANCE TRACKER'), findsOneWidget);

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
}
