import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme/morfin_theme.dart';
import '../core/utils/file_downloader.dart';
import '../core/utils/report_exporter.dart';
import '../state/morfin_controller.dart';
import '../widgets/add_sheets.dart';

class SettingsScreen extends StatefulWidget {
  final MorfinController controller;
  final VoidCallback? onStartTour;

  const SettingsScreen({
    super.key,
    required this.controller,
    this.onStartTour,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey _pngCardKey = GlobalKey();
  late final TextEditingController _nameCtrl;
  bool _savingName = false;
  bool _exportingPng = false;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.controller.user?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportPng() async {
    setState(() => _exportingPng = true);
    try {
      final boundary = _pngCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Kartu laporan belum siap.');
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Gagal mengonversi gambar PNG.');
      final bytes = byteData.buffer.asUint8List();
      final fname = 'morfin-laporan-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.png';
      final saved = await saveExportFile(bytes: bytes, fileName: fname, mimeType: 'image/png');
      if (mounted) showMorfinToast(context, 'PNG diunduh: $saved');
    } catch (e) {
      if (mounted) showMorfinToast(context, 'Gagal ekspor PNG: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exportingPng = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _exportingPdf = true);
    try {
      final bytes = await ReportExporter.buildPdfBytes(
        user: widget.controller.user,
        dashboard: widget.controller.dashboard,
        palette: widget.controller.palette,
      );
      final fname = 'morfin-laporan-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
      final saved = await saveExportFile(bytes: bytes, fileName: fname, mimeType: 'application/pdf');
      if (mounted) showMorfinToast(context, 'PDF diunduh: $saved');
    } catch (e) {
      if (mounted) showMorfinToast(context, 'Gagal ekspor PDF: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _copyCsv() async {
    final txs = widget.controller.dashboard?.transactions ?? [];
    final buf = StringBuffer('Tanggal,Jenis,Kategori,Keterangan,Nominal\n');
    for (final t in txs) {
      buf.writeln('${DateFormat('yyyy-MM-dd').format(t.occurredAt)},${t.type},${t.category},"${t.title}",${t.amount}');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (mounted) showMorfinToast(context, 'Laporan CSV disalin ke clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final user = ctrl.user;
    final summary = ctrl.dashboard?.summary;
    final hide = user?.hideBalance ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 860;

        final profileAndTheme = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card (No login method shown!)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Profil Akun', style: MorfinTheme.display(16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [MorfinColors.lime, MorfinColors.limeDeep]),
                        ),
                        child: Center(
                          child: Text(
                            (user?.name.isNotEmpty == true ? user!.name[0] : 'M').toUpperCase(),
                            style: MorfinTheme.display(20, color: MorfinColors.ink),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? 'Pengguna MorFin', style: MorfinTheme.display(16)),
                            Text(user?.email ?? '', style: MorfinTheme.body(12, color: MorfinColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          style: MorfinTheme.body(13.5, weight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'Nama Tampilan',
                            isDense: true,
                            filled: true,
                            fillColor: MorfinColors.pistachio,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MorfinColors.carbon,
                            foregroundColor: MorfinColors.lime,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _savingName
                              ? null
                              : () async {
                                  if (_nameCtrl.text.trim().length < 2) return;
                                  setState(() => _savingName = true);
                                  try {
                                    await ctrl.updateProfileName(_nameCtrl.text.trim());
                                    if (context.mounted) showMorfinToast(context, 'Nama diperbarui');
                                  } finally {
                                    if (mounted) setState(() => _savingName = false);
                                  }
                                },
                          child: Text('Simpan', style: MorfinTheme.display(13, color: MorfinColors.lime)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Theme Palette Switcher (5 Neo-Flat Color Styles)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gaya Warna Aplikasi', style: MorfinTheme.display(16)),
                  const SizedBox(height: 4),
                  Text('Pilih tema warna yang paling nyaman untuk Anda.', style: MorfinTheme.body(12, color: MorfinColors.muted)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: MorfinPalettes.all.map((p) {
                      final active = ctrl.themeId == p.id;
                      return GestureDetector(
                        onTap: () {
                          ctrl.setThemePalette(p.id);
                          showMorfinToast(context, 'Tema diubah ke ${p.name}');
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? p.carbon : p.pistachio,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: active ? p.lime : MorfinColors.ink.withValues(alpha: 0.1),
                              width: active ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: p.lime,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: MorfinTheme.body(12, color: active ? Colors.white : MorfinColors.ink, weight: FontWeight.w700),
                                  ),
                                  Text(
                                    p.tagline,
                                    style: MorfinTheme.body(9.5, color: active ? p.lime : MorfinColors.muted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        );

        final exportAndAccount = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Export PNG & PDF Card with Live Preview
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Ekspor Laporan Keuangan', style: MorfinTheme.display(16)),
                  const SizedBox(height: 4),
                  Text('Unduh ringkasan kartu gambar (PNG) atau dokumen lengkap (PDF).', style: MorfinTheme.body(12, color: MorfinColors.muted)),
                  const SizedBox(height: 14),

                  // Capturable PNG Report Card Preview
                  RepaintBoundary(
                    key: _pngCardKey,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: MorfinColors.carbon,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('MorFin Report', style: MorfinTheme.display(16, color: MorfinColors.lime)),
                              Text(
                                DateFormat('dd MMM yyyy').format(DateTime.now()),
                                style: MorfinTheme.body(10.5, color: MorfinColors.mutedLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(user?.name ?? 'Pengguna MorFin', style: MorfinTheme.body(12, color: Colors.white70)),
                          const SizedBox(height: 14),
                          Text('Total Saldo Bersih', style: MorfinTheme.body(10.5, color: MorfinColors.mutedLight)),
                          const SizedBox(height: 2),
                          Text(
                            hide ? 'Rp •••••••••' : formatIdr(summary?.totalBalance ?? 0),
                            style: MorfinTheme.display(22, color: Colors.white),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Pemasukan', style: MorfinTheme.body(10, color: MorfinColors.mutedLight)),
                                      const SizedBox(height: 2),
                                      Text(formatIdrCompact(summary?.totalIncome ?? 0), style: MorfinTheme.display(13.5, color: MorfinColors.lime)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Pengeluaran', style: MorfinTheme.body(10, color: MorfinColors.mutedLight)),
                                      const SizedBox(height: 2),
                                      Text(formatIdrCompact(summary?.totalExpense ?? 0), style: MorfinTheme.display(13.5, color: MorfinColors.coralSoft)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(color: MorfinColors.lime, borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: [
                                    Text('Hemat', style: MorfinTheme.body(9.5, color: MorfinColors.ink, weight: FontWeight.w700)),
                                    Text('${summary?.savingsRate ?? 0}%', style: MorfinTheme.display(14, color: MorfinColors.ink)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MorfinColors.lime,
                              foregroundColor: MorfinColors.ink,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _exportingPng ? null : _exportPng,
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: Text(_exportingPng ? 'Membuat...' : 'Ekspor PNG', style: MorfinTheme.display(13)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MorfinColors.carbon,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _exportingPdf ? null : _exportPdf,
                            icon: Icon(Icons.picture_as_pdf_outlined, size: 18, color: MorfinColors.lime),
                            label: Text(_exportingPdf ? 'Membuat...' : 'Ekspor PDF', style: MorfinTheme.display(13, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MorfinColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _copyCsv,
                    icon: const Icon(Icons.table_chart_outlined, size: 17),
                    label: Text('Salin Data CSV', style: MorfinTheme.body(12.5, weight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Data & Session Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.onStartTour != null) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MorfinColors.ink,
                        side: BorderSide(color: MorfinColors.ink.withValues(alpha: 0.16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: Text('Ulangi Tour Panduan Fitur', style: MorfinTheme.body(13, weight: FontWeight.w700)),
                      onPressed: widget.onStartTour,
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MorfinColors.coral,
                      side: BorderSide(color: MorfinColors.coral.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: Text('Mulai dari Nol (Bersihkan Data)', style: MorfinTheme.body(13, color: MorfinColors.coral, weight: FontWeight.w700)),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Bersihkan Semua Data?'),
                          content: const Text('Semua transaksi, anggaran, kantong, dan target saat ini akan dihapus agar Anda bisa mulai dari Rp 0.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Batal')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: MorfinColors.coral, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text('Hapus Semua'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ctrl.resetAccountData();
                        if (context.mounted) showMorfinToast(context, 'Data dibersihkan — mulai dari Rp 0');
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: ctrl.logout,
                    icon: const Icon(Icons.logout_rounded, size: 18, color: MorfinColors.muted),
                    label: Text('Keluar Akun', style: MorfinTheme.body(13, color: MorfinColors.muted, weight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        );

        return ListView(
          padding: EdgeInsets.fromLTRB(isWide ? 28 : 18, 16, isWide ? 28 : 18, 28),
          children: [
            Text('Pengaturan', style: MorfinTheme.display(20)),
            const SizedBox(height: 16),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: profileAndTheme),
                  const SizedBox(width: 20),
                  Expanded(child: exportAndAccount),
                ],
              )
            else ...[
              profileAndTheme,
              const SizedBox(height: 16),
              exportAndAccount,
            ],
          ],
        );
      },
    );
  }
}
