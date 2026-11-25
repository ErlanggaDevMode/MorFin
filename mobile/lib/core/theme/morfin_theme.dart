import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MorfinColors {
  static const Color canvas = Color(0xFF9BC352);
  static const Color lime = Color(0xFFA5CB53);
  static const Color limeSoft = Color(0xFFCDE290);
  static const Color limeDeep = Color(0xFF7B9E34);
  static const Color pistachio = Color(0xFFF2F8E9);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color carbon = Color(0xFF181A18);
  static const Color darkBg = Color(0xFF101210);
  static const Color ink = Color(0xFF161916);
  static const Color muted = Color(0xFF768072);
  static const Color mutedLight = Color(0xFF9EA89A);
  static const Color coral = Color(0xFFE75C34);
  static const Color coralSoft = Color(0xFFFF8A6B);
  static const Color gold = Color(0xFFF5C049);
}

class MorfinTheme {
  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: MorfinColors.pistachio,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MorfinColors.lime,
        primary: MorfinColors.lime,
        onPrimary: MorfinColors.ink,
        secondary: MorfinColors.carbon,
        surface: MorfinColors.pistachio,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: MorfinColors.ink,
        displayColor: MorfinColors.ink,
      ),
    );
  }

  static TextStyle display(double size, {Color color = MorfinColors.ink, FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.02 * size,
    );
  }

  static TextStyle body(double size, {Color color = MorfinColors.ink, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }
}

final NumberFormat _idrFmt = NumberFormat.decimalPattern('id_ID');

String formatIdr(int amount) {
  final prefix = amount < 0 ? '-Rp ' : 'Rp ';
  return '$prefix${_idrFmt.format(amount.abs())}';
}

String formatIdrCompact(int amount) {
  final abs = amount.abs();
  final sign = amount < 0 ? '-' : '';
  if (abs >= 1000000) {
    final val = abs / 1000000.0;
    final str = val == val.roundToDouble() ? val.toInt().toString() : val.toStringAsFixed(1).replaceAll('.', ',');
    return '${sign}Rp $str jt';
  }
  if (abs >= 1000) {
    final val = (abs / 1000.0).round();
    return '${sign}Rp $val rb';
  }
  return '${sign}Rp $abs';
}
