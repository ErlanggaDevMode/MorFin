import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MorfinPalette {
  final String id;
  final String name;
  final String tagline;
  final Color canvas;
  final Color lime;
  final Color limeSoft;
  final Color limeDeep;
  final Color pistachio;
  final Color carbon;
  final Color darkBg;

  const MorfinPalette({
    required this.id,
    required this.name,
    required this.tagline,
    required this.canvas,
    required this.lime,
    required this.limeSoft,
    required this.limeDeep,
    required this.pistachio,
    required this.carbon,
    required this.darkBg,
  });
}

class MorfinPalettes {
  static const List<MorfinPalette> all = [
    MorfinPalette(
      id: 'matcha',
      name: 'Matcha Lime',
      tagline: 'Segar & Ikonik',
      canvas: Color(0xFF9BC352),
      lime: Color(0xFFA5CB53),
      limeSoft: Color(0xFFCDE290),
      limeDeep: Color(0xFF7B9E34),
      pistachio: Color(0xFFF2F8E9),
      carbon: Color(0xFF181A18),
      darkBg: Color(0xFF101210),
    ),
    MorfinPalette(
      id: 'ocean',
      name: 'Ocean Mint',
      tagline: 'Tenang & Modern',
      canvas: Color(0xFF28B7A6),
      lime: Color(0xFF2DD4BF),
      limeSoft: Color(0xFF99F6E4),
      limeDeep: Color(0xFF0F766E),
      pistachio: Color(0xFFECFDF9),
      carbon: Color(0xFF0F1C1E),
      darkBg: Color(0xFF0A1315),
    ),
    MorfinPalette(
      id: 'sunset',
      name: 'Sunset Coral',
      tagline: 'Hangat & Berani',
      canvas: Color(0xFFE96A7E),
      lime: Color(0xFFFB7185),
      limeSoft: Color(0xFFFECDD3),
      limeDeep: Color(0xFFBE123C),
      pistachio: Color(0xFFFFF1F3),
      carbon: Color(0xFF1F1418),
      darkBg: Color(0xFF140D10),
    ),
    MorfinPalette(
      id: 'lavender',
      name: 'Royal Violet',
      tagline: 'Futuristik & Rapi',
      canvas: Color(0xFF8B6FE8),
      lime: Color(0xFFA78BFA),
      limeSoft: Color(0xFFDDD6FE),
      limeDeep: Color(0xFF6D28D9),
      pistachio: Color(0xFFF5F3FF),
      carbon: Color(0xFF171324),
      darkBg: Color(0xFF0F0C18),
    ),
    MorfinPalette(
      id: 'gold',
      name: 'Midnight Gold',
      tagline: 'Elegan & Eksekutif',
      canvas: Color(0xFFD9A93B),
      lime: Color(0xFFF5C049),
      limeSoft: Color(0xFFFDE68A),
      limeDeep: Color(0xFFB45309),
      pistachio: Color(0xFFFAF7EE),
      carbon: Color(0xFF171612),
      darkBg: Color(0xFF0F0E0B),
    ),
  ];

  static MorfinPalette byId(String id) {
    return all.firstWhere((p) => p.id == id, orElse: () => all.first);
  }
}

class MorfinColors {
  static MorfinPalette active = MorfinPalettes.all.first;
  static bool isDark = false;

  static void setPalette(String id) {
    active = MorfinPalettes.byId(id);
  }

  static void setDark(bool dark) {
    isDark = dark;
  }

  static Color get canvas => active.canvas;
  static Color get lime => active.lime;
  static Color get limeSoft => active.limeSoft;
  static Color get limeDeep => active.limeDeep;
  static Color get carbon => active.carbon;
  static Color get darkBg => active.darkBg;

  /// Main page background: soft pastel in light mode, rich dark canvas in dark mode
  static Color get pistachio => isDark ? active.darkBg : active.pistachio;

  /// Elevated card & surface background
  static Color get surfaceWhite => isDark ? const Color(0xFF1B1F1C) : const Color(0xFFFFFFFF);

  /// Nested subtle fill inside cards (inputs, pills, drafts)
  static Color get surfaceAlt => isDark ? const Color(0xFF252B26) : active.pistachio;

  /// Primary text color adapting to light/dark surfaces
  static Color get ink => isDark ? const Color(0xFFF2F5F0) : const Color(0xFF161916);

  /// Always-dark ink for text/icons rendered ON TOP of bright lime accent fills
  static const Color onLime = Color(0xFF161916);

  /// Secondary text color
  static Color get muted => isDark ? const Color(0xFFA0AA9C) : const Color(0xFF768072);

  static const Color mutedLight = Color(0xFF9EA89A);
  static const Color coral = Color(0xFFE75C34);
  static const Color coralSoft = Color(0xFFFF8A6B);
  static const Color gold = Color(0xFFF5C049);
}

class MorfinTheme {
  static ThemeData build(MorfinPalette palette, {bool dark = false}) {
    final bg = dark ? palette.darkBg : palette.pistachio;
    final fg = dark ? const Color(0xFFF2F5F0) : const Color(0xFF161916);
    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.lime,
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: palette.lime,
        onPrimary: MorfinColors.onLime,
        secondary: palette.carbon,
        surface: dark ? const Color(0xFF1B1F1C) : palette.pistachio,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: fg,
        displayColor: fg,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF1B1F1C) : Colors.white,
        titleTextStyle: display(18, color: fg),
        contentTextStyle: body(13.5, color: dark ? const Color(0xFFA0AA9C) : const Color(0xFF768072)),
      ),
    );
  }

  static TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color ?? MorfinColors.ink,
      letterSpacing: -0.02 * size,
    );
  }

  static TextStyle body(double size, {Color? color, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? MorfinColors.ink,
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
