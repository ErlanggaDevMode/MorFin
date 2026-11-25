import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/morfin_models.dart';
import '../theme/morfin_theme.dart';

class ReportExporter {
  static Future<Uint8List> buildPdfBytes({
    required MorfinUser? user,
    required DashboardPayload? dashboard,
    required MorfinPalette palette,
  }) async {
    final doc = pw.Document(title: 'Laporan Keuangan MorFin');
    final accent = PdfColor.fromInt(palette.lime.toARGB32());
    final dark = PdfColor.fromInt(palette.carbon.toARGB32());
    final softBg = PdfColor.fromInt(palette.pistachio.toARGB32());
    final summary = dashboard?.summary;
    final txs = dashboard?.transactions ?? [];
    final budgets = dashboard?.budgets ?? [];
    final wallets = dashboard?.wallets ?? [];
    final goals = dashboard?.goals ?? [];
    final dateLabel = DateFormat('dd MMM yyyy · HH:mm').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          // Header Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: dark,
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MorFin — Laporan Keuangan',
                      style: pw.TextStyle(color: accent, fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${user?.name ?? "Pengguna MorFin"} (${user?.email ?? "-"})',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                    ),
                  ],
                ),
                pw.Text(dateLabel, style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // KPI Strip
          pw.Row(
            children: [
              _kpiBox('Saldo Bersih', formatIdr(summary?.totalBalance ?? 0), accent, dark),
              pw.SizedBox(width: 8),
              _kpiBox('Pemasukan', formatIdr(summary?.totalIncome ?? 0), softBg, dark),
              pw.SizedBox(width: 8),
              _kpiBox('Pengeluaran', formatIdr(summary?.totalExpense ?? 0), softBg, dark),
              pw.SizedBox(width: 8),
              _kpiBox('Rasio Hemat', '${summary?.savingsRate ?? 0}%', softBg, dark),
            ],
          ),
          pw.SizedBox(height: 18),

          // Budgets Table
          if (budgets.isNotEmpty) ...[
            pw.Text('Ringkasan Anggaran', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: dark)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: pw.BoxDecoration(color: dark),
              cellStyle: const pw.TextStyle(fontSize: 9.5),
              headers: const ['Anggaran', 'Kategori', 'Periode', 'Terpakai', 'Batas', 'Progres'],
              data: budgets
                  .map((b) => [
                        b.name,
                        b.category,
                        b.period,
                        formatIdr(b.spentAmount),
                        formatIdr(b.limitAmount),
                        '${b.usedPercent}%',
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 16),
          ],

          // Wallets & Goals summary
          if (wallets.isNotEmpty) ...[
            pw.Text('Kantong Tabungan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: dark)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: pw.BoxDecoration(color: dark),
              cellStyle: const pw.TextStyle(fontSize: 9.5),
              headers: const ['Nama Kantong', 'Terkumpul', 'Target', 'Progres'],
              data: wallets
                  .map((w) => [w.name, formatIdr(w.currentAmount), formatIdr(w.targetAmount), '${w.progressPercent}%'])
                  .toList(),
            ),
            pw.SizedBox(height: 16),
          ],

          if (goals.isNotEmpty) ...[
            pw.Text('Target Keuangan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: dark)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: pw.BoxDecoration(color: dark),
              cellStyle: const pw.TextStyle(fontSize: 9.5),
              headers: const ['Target', 'Status', 'Terkumpul', 'Nominal Target'],
              data: goals
                  .map((g) => [g.title, g.status, formatIdr(g.savedAmount), formatIdr(g.targetAmount)])
                  .toList(),
            ),
            pw.SizedBox(height: 16),
          ],

          // Transactions Table
          pw.Text('Riwayat Transaksi (${txs.length})', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: dark)),
          pw.SizedBox(height: 8),
          if (txs.isEmpty)
            pw.Text('Belum ada transaksi tercatat.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: pw.BoxDecoration(color: dark),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: const ['Tanggal', 'Keterangan', 'Kategori', 'Jenis', 'Nominal'],
              data: txs
                  .take(40)
                  .map((t) => [
                        DateFormat('dd/MM/yy HH:mm').format(t.occurredAt),
                        t.title,
                        t.category,
                        t.isIncome ? 'Masuk' : 'Keluar',
                        '${t.isIncome ? '+' : '-'}${formatIdr(t.amount)}',
                      ])
                  .toList(),
            ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _kpiBox(String label, String value, PdfColor bg, PdfColor ink) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(10)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: ink)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: ink)),
          ],
        ),
      ),
    );
  }
}
