import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../../models/morfin_models.dart';
import '../theme/morfin_theme.dart';

/// Lightweight, standards-compliant pure-Dart PDF 1.4 generator for MorFin reports.
/// Produces crisp A4 financial reports using built-in Type1 Helvetica fonts with zero bloat.
class ReportExporter {
  static String _pdfEscape(String input) {
    final safe = input
        .replaceAll('•', '-')
        .replaceAll('·', '-')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    return safe.replaceAll('\\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');
  }

  static String _rgb(int argb) {
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;
    return '${r.toStringAsFixed(3)} ${g.toStringAsFixed(3)} ${b.toStringAsFixed(3)}';
  }

  static Future<Uint8List> buildPdfBytes({
    required MorfinUser? user,
    required DashboardPayload? dashboard,
    required MorfinPalette palette,
  }) async {
    final summary = dashboard?.summary;
    final txs = dashboard?.transactions ?? [];
    final budgets = dashboard?.budgets ?? [];
    final wallets = dashboard?.wallets ?? [];
    final goals = dashboard?.goals ?? [];
    final dateLabel = DateFormat('dd MMM yyyy - HH:mm').format(DateTime.now());

    final darkRgb = _rgb(palette.carbon.toARGB32());
    final accentRgb = _rgb(palette.lime.toARGB32());
    final softRgb = _rgb(palette.pistachio.toARGB32());

    final s = StringBuffer();

    void rect(double x, double y, double w, double h, String rgb) {
      s.writeln('$rgb rg ${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)} ${w.toStringAsFixed(1)} ${h.toStringAsFixed(1)} re f');
    }

    void text(double x, double y, String txt, {double size = 10, bool bold = false, String rgb = '0.09 0.10 0.09'}) {
      final font = bold ? '/F2' : '/F1';
      s.writeln('BT $rgb rg $font ${size.toStringAsFixed(1)} Tf ${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)} Td (${_pdfEscape(txt)}) Tj ET');
    }

    // A4 dimensions: 595 x 842 pt
    // Header banner
    rect(36, 738, 523, 68, darkRgb);
    text(54, 780, 'MorFin - Laporan Keuangan', size: 18, bold: true, rgb: accentRgb);
    text(54, 758, '${user?.name ?? "Pengguna MorFin"} (${user?.email ?? "-"})', size: 10.5, rgb: '1 1 1');
    text(420, 778, dateLabel, size: 9.5, rgb: '0.78 0.82 0.78');

    // 4 KPI Boxes
    final kpis = [
      ('Saldo Bersih', formatIdr(summary?.totalBalance ?? 0), accentRgb),
      ('Pemasukan', formatIdr(summary?.totalIncome ?? 0), softRgb),
      ('Pengeluaran', formatIdr(summary?.totalExpense ?? 0), softRgb),
      ('Rasio Hemat', '${summary?.savingsRate ?? 0}%', softRgb),
    ];
    for (int i = 0; i < kpis.length; i++) {
      final x = 36.0 + i * 133.0;
      rect(x, 672, 124, 52, kpis[i].$3);
      text(x + 10, 706, kpis[i].$1, size: 8.5, bold: true, rgb: '0.25 0.28 0.25');
      text(x + 10, 686, kpis[i].$2, size: 11, bold: true, rgb: '0.09 0.10 0.09');
    }

    double y = 646;

    // Budgets section
    text(36, y, 'Ringkasan Anggaran (${budgets.length})', size: 12.5, bold: true, rgb: darkRgb);
    y -= 18;
    rect(36, y - 4, 523, 18, darkRgb);
    text(44, y + 1, 'Anggaran', size: 9, bold: true, rgb: '1 1 1');
    text(188, y + 1, 'Periode', size: 9, bold: true, rgb: '1 1 1');
    text(248, y + 1, 'Terpakai', size: 9, bold: true, rgb: '1 1 1');
    text(338, y + 1, 'Batas', size: 9, bold: true, rgb: '1 1 1');
    text(426, y + 1, 'Pakai', size: 9, bold: true, rgb: '1 1 1');
    y -= 18;

    const overBgRgb = '1.000 0.930 0.930';
    const overTextRgb = '0.840 0.145 0.145';
    const periodLabels = {
      'daily': 'Harian',
      'weekly': 'Mingguan',
      'monthly': 'Bulanan',
      'yearly': 'Tahunan',
    };

    for (final b in budgets.take(6)) {
      if (y < 90) break;
      final isOver = b.isOverBudget;
      rect(36, y - 4, 523, 16, isOver ? overBgRgb : softRgb);
      text(44, y, b.name.length > 22 ? '${b.name.substring(0, 22)}...' : b.name, size: 9);
      text(188, y, periodLabels[b.period] ?? b.period, size: 9);
      text(248, y, formatIdr(b.spentAmount), size: 9, bold: isOver, rgb: isOver ? overTextRgb : '0.09 0.10 0.09');
      text(338, y, formatIdr(b.limitAmount), size: 9);
      final usageLabel = isOver ? '${b.usedPercent}% (Over ${formatIdr(b.overAmount)})' : '${b.usedPercent}%';
      text(426, y, usageLabel, size: 8.5, bold: true, rgb: isOver ? overTextRgb : '0.09 0.10 0.09');
      y -= 18;
    }

    y -= 12;
    // Wallets & Goals summary line
    if (wallets.isNotEmpty && y > 140) {
      text(36, y, 'Kantong Tabungan (${wallets.length})', size: 12.5, bold: true, rgb: darkRgb);
      y -= 18;
      for (final w in wallets.take(4)) {
        if (y < 90) break;
        text(44, y, '- ${w.name}: ${formatIdr(w.currentAmount)} / ${formatIdr(w.targetAmount)} (${w.progressPercent}%)', size: 9.5);
        y -= 15;
      }
      y -= 10;
    }

    if (goals.isNotEmpty && y > 130) {
      text(36, y, 'Target Keuangan (${goals.length})', size: 12.5, bold: true, rgb: darkRgb);
      y -= 18;
      for (final g in goals.take(5)) {
        if (y < 90) break;
        text(44, y, '- ${g.title} [${g.status}]: ${formatIdr(g.savedAmount)} / ${formatIdr(g.targetAmount)} (${g.progressPercent}%)', size: 9.5);
        y -= 15;
      }
      y -= 10;
    }

    // Transactions table
    if (y > 110) {
      text(36, y, 'Riwayat Transaksi Terbaru (${txs.length})', size: 12.5, bold: true, rgb: darkRgb);
      y -= 18;
      rect(36, y - 4, 523, 18, darkRgb);
      text(44, y + 1, 'Tanggal', size: 9, bold: true, rgb: '1 1 1');
      text(135, y + 1, 'Keterangan', size: 9, bold: true, rgb: '1 1 1');
      text(345, y + 1, 'Kategori', size: 9, bold: true, rgb: '1 1 1');
      text(445, y + 1, 'Nominal', size: 9, bold: true, rgb: '1 1 1');
      y -= 18;

      for (final t in txs.take(16)) {
        if (y < 52) break;
        final dStr = DateFormat('dd/MM/yy HH:mm').format(t.occurredAt);
        final title = t.title.length > 32 ? '${t.title.substring(0, 32)}...' : t.title;
        final amt = '${t.isIncome ? "+" : "-"}${formatIdr(t.amount)}';
        text(44, y, dStr, size: 8.5);
        text(135, y, title, size: 8.5);
        text(345, y, t.category, size: 8.5);
        text(445, y, amt, size: 8.5, bold: true);
        y -= 15;
      }
    }

    text(36, 28, 'Dibuat otomatis oleh MorFin Personal Finance Tracker', size: 8.5, rgb: '0.45 0.50 0.45');

    final streamBytes = latin1.encode(s.toString());

    // Assemble PDF 1.4 objects with exact xref byte offsets
    final out = BytesBuilder();
    void writeStr(String str) => out.add(latin1.encode(str));
    final offsets = <int>[0];

    writeStr('%PDF-1.4\n');

    void addObj(int num, String body) {
      offsets.add(out.length);
      writeStr('$num 0 obj\n$body\nendobj\n');
    }

    addObj(1, '<< /Type /Catalog /Pages 2 0 R >>');
    addObj(2, '<< /Type /Pages /Kids [3 0 R] /Count 1 >>');
    addObj(3, '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> /Contents 6 0 R >>');
    addObj(4, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');
    addObj(5, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>');

    offsets.add(out.length);
    writeStr('6 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n');
    out.add(streamBytes);
    writeStr('\nendstream\nendobj\n');

    final xrefPos = out.length;
    writeStr('xref\n0 ${offsets.length}\n');
    writeStr('0000000000 65535 f \n');
    for (int i = 1; i < offsets.length; i++) {
      writeStr('${offsets[i].toString().padLeft(10, '0')} 00000 n \n');
    }
    writeStr('trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n$xrefPos\n%%EOF\n');

    return out.toBytes();
  }
}
