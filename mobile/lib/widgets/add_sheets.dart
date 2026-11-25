import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';
import '../models/morfin_models.dart';
import '../state/morfin_controller.dart';

InputDecoration _fieldDeco(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      labelStyle: MorfinTheme.body(13, color: MorfinColors.muted, weight: FontWeight.w600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: MorfinColors.ink.withValues(alpha: 0.14)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: MorfinColors.ink.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MorfinColors.carbon, width: 1.8),
      ),
    );

Future<void> showAddTransactionSheet(BuildContext context, MorfinController ctrl) async {
  final titleCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  String type = 'expense';
  String category = 'Makan';
  String method = 'QRIS · E-Wallet';
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MorfinColors.pistachio,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: MorfinColors.ink.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Catat Transaksi Baru', style: MorfinTheme.display(20)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Pengeluaran (-)')),
                      selected: type == 'expense',
                      selectedColor: MorfinColors.carbon,
                      labelStyle: TextStyle(color: type == 'expense' ? Colors.white : MorfinColors.ink, fontWeight: FontWeight.w700),
                      onSelected: (_) => setState(() => type = 'expense'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Pemasukan (+)')),
                      selected: type == 'income',
                      selectedColor: MorfinColors.lime,
                      labelStyle: const TextStyle(color: MorfinColors.ink, fontWeight: FontWeight.w700),
                      onSelected: (_) => setState(() {
                        type = 'income';
                        category = 'Gaji / Proyek';
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: _fieldDeco('Keterangan', hint: 'Contoh: Kopi Susu / Proyek Web')),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: _fieldDeco('Nominal (Rp)', hint: '50000'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: _fieldDeco('Kategori'),
                items: const ['Makan', 'Transport', 'Tagihan', 'Cloud AI', 'Edukasi', 'Hiburan', 'Tabungan', 'Gaji / Proyek', 'Lainnya']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => category = v ?? 'Makan'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: _fieldDeco('Metode Pembayaran'),
                items: const ['QRIS · E-Wallet', 'Transfer · BCA', 'Kartu Debit', 'Tunai']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => method = v ?? 'QRIS · E-Wallet'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MorfinColors.carbon,
                    foregroundColor: MorfinColors.lime,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final amount = int.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          if (titleCtrl.text.trim().isEmpty || amount <= 0) return;
                          setState(() => saving = true);
                          try {
                            await ctrl.addTransaction(
                              title: titleCtrl.text.trim(),
                              category: category,
                              type: type,
                              amount: amount,
                              paymentMethod: method,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } finally {
                            if (ctx.mounted) setState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: MorfinColors.lime))
                      : Text('Simpan ke Database VPS', style: MorfinTheme.display(15, color: MorfinColors.lime)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showAddBudgetSheet(BuildContext context, MorfinController ctrl) async {
  final nameCtrl = TextEditingController();
  final limitCtrl = TextEditingController();
  String category = 'Makan';
  String period = ctrl.selectedBudgetPeriod;
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MorfinColors.pistachio,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Buat Anggaran Baru', style: MorfinTheme.display(20)),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, decoration: _fieldDeco('Nama Anggaran', hint: 'Contoh: Belanja Mingguan')),
              const SizedBox(height: 12),
              TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: _fieldDeco('Batas Nominal (Rp)', hint: '500000')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: period,
                decoration: _fieldDeco('Periode'),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Harian')),
                  DropdownMenuItem(value: 'weekly', child: Text('Mingguan')),
                  DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
                  DropdownMenuItem(value: 'yearly', child: Text('Tahunan')),
                ],
                onChanged: (v) => setState(() => period = v ?? 'monthly'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: _fieldDeco('Kategori'),
                items: const ['Makan', 'Transport', 'Tagihan', 'Cloud AI', 'Edukasi', 'Hiburan', 'Tabungan']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => category = v ?? 'Makan'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MorfinColors.carbon,
                    foregroundColor: MorfinColors.lime,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final limit = int.tryParse(limitCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          if (nameCtrl.text.trim().isEmpty || limit <= 0) return;
                          setState(() => saving = true);
                          try {
                            await ctrl.addBudget(
                              name: nameCtrl.text.trim(),
                              category: category,
                              period: period,
                              limitAmount: limit,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } finally {
                            if (ctx.mounted) setState(() => saving = false);
                          }
                        },
                  child: Text('Simpan Anggaran', style: MorfinTheme.display(15, color: MorfinColors.lime)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showAddGoalSheet(BuildContext context, MorfinController ctrl) async {
  final titleCtrl = TextEditingController();
  final targetCtrl = TextEditingController();
  final savedCtrl = TextEditingController(text: '0');
  String icon = 'shield';
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MorfinColors.pistachio,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Target Keuangan Baru', style: MorfinTheme.display(20)),
              const SizedBox(height: 14),
              TextField(controller: titleCtrl, decoration: _fieldDeco('Nama Target', hint: 'Contoh: Dana Nikah / Laptop Baru')),
              const SizedBox(height: 12),
              TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: _fieldDeco('Target Nominal (Rp)', hint: '10000000')),
              const SizedBox(height: 12),
              TextField(controller: savedCtrl, keyboardType: TextInputType.number, decoration: _fieldDeco('Sudah Terkumpul (Rp)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: icon,
                decoration: _fieldDeco('Ikon Lencana'),
                items: const [
                  DropdownMenuItem(value: 'shield', child: Text('Perisai (Dana Darurat)')),
                  DropdownMenuItem(value: 'coin', child: Text('Koin (Bebas Utang)')),
                  DropdownMenuItem(value: 'coffee', child: Text('Gelas (Hemat Harian)')),
                  DropdownMenuItem(value: 'chart', child: Text('Grafik (Investasi)')),
                  DropdownMenuItem(value: 'plane', child: Text('Pesawat (Liburan)')),
                  DropdownMenuItem(value: 'home', child: Text('Rumah (Properti)')),
                ],
                onChanged: (v) => setState(() => icon = v ?? 'shield'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MorfinColors.carbon,
                    foregroundColor: MorfinColors.lime,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final target = int.tryParse(targetCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          final saved = int.tryParse(savedCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          if (titleCtrl.text.trim().isEmpty || target <= 0) return;
                          setState(() => saving = true);
                          try {
                            await ctrl.addGoal(
                              title: titleCtrl.text.trim(),
                              icon: icon,
                              targetAmount: target,
                              savedAmount: saved,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } finally {
                            if (ctx.mounted) setState(() => saving = false);
                          }
                        },
                  child: Text('Simpan Target', style: MorfinTheme.display(15, color: MorfinColors.lime)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showTopUpWalletSheet(BuildContext context, MorfinController ctrl, MorfinWallet wallet) async {
  final amtCtrl = TextEditingController(text: '500000');
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MorfinColors.pistachio,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Top Up ${wallet.name}', style: MorfinTheme.display(19)),
            const SizedBox(height: 6),
            Text(
              'Saat ini: ${formatIdr(wallet.currentAmount)} / ${formatIdr(wallet.targetAmount)}',
              style: MorfinTheme.body(13, color: MorfinColors.muted),
            ),
            const SizedBox(height: 14),
            TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: _fieldDeco('Tambah Tabungan (Rp)')),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MorfinColors.carbon,
                  foregroundColor: MorfinColors.lime,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        final add = int.tryParse(amtCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                        if (add <= 0) return;
                        setState(() => saving = true);
                        try {
                          await ctrl.topUpWallet(wallet, add);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } finally {
                          if (ctx.mounted) setState(() => saving = false);
                        }
                      },
                child: Text('Tambah ke Kantong', style: MorfinTheme.display(15, color: MorfinColors.lime)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
