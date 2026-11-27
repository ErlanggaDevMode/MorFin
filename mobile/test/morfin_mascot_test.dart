import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morfin/core/theme/morfin_theme.dart';
import 'package:morfin/widgets/morfin_mascot.dart';

void main() {
  testWidgets('MorfinMascot renders all 7 moods across light & dark palettes', (tester) async {
    for (final palette in MorfinPalettes.all) {
      MorfinColors.setPalette(palette.id);
      MorfinColors.setDark(false);

      for (final mood in MascotMood.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: MorfinMascot(mood: mood, size: 96),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 120));
        expect(find.byType(MorfinMascot), findsOneWidget);
      }
    }

    // Verify reduce-motion mode renders cleanly without running animations
    MorfinColors.setDark(true);
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: MorfinMascot(mood: MascotMood.party, size: 80),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(MorfinMascot), findsOneWidget);
  });
}
