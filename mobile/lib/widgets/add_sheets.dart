import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme/morfin_theme.dart';
import '../models/morfin_models.dart';
import '../state/morfin_controller.dart';

void showMorfinToast(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: MorfinTheme.body(13, color: isError ? Colors.white : MorfinColors.lime, weight: FontWeight.w700),
        ),
        backgroundColor: isError ? MorfinColors.coral : MorfinColors.carbon,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
}

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
        borderSide: BorderSide(color: MorfinColors.carbon, width: 1.8),
      ),
    );

Widget _sheetHandle() => Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: MorfinColors.ink.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );

Widget _quickAmountChips(TextEditingController ctrl, VoidCallback refresh) {
  const presets = [
    (25000, '+25rb'),
    (50000, '+50rb'),
    (100000, '+100rb'),
    (500000, '+500rb'),
  ];
  return Wrap(
    spacing: 8,
    runSpacing: 6,
    children: presets.map((p) {
      return ActionChip(
        label: Text(p.$2, style: MorfinTheme.body(11.5, weight: FontWeight.w700)),
        backgroundColor: Colors.white,
        side: BorderSide(color: MorfinColors.ink.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        onPressed: () {
          final current = int.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          ctrl.text = (current + p.$1).toString();
          refresh();
        },
      );
    }).toList(),
  );
}

Future<void> showAddTransactionSheet(
  BuildContext context,
  MorfinController ctrl, {
  MorfinTransaction? existing,
}) async {
  final isEdit = existing != null;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final amountCtrl = TextEditingController(text: existing != null ? existing.amount.toString() : '');
  String type = existing?.type ?? 'expense';
  String category = existing?.category ?? 'Makan';
  String method = existing?.paymentMethod ?? 'QRIS · E-Wallet';
  String? selectedWalletId = existing?.walletId;
  DateTime selectedDate = existing?.occurredAt ?? DateTime.now();
  bool saving = false;
  String? errorMsg;

  const categories = ['Makan', 'Transport', 'Tagihan', 'Cloud AI', 'Edukasi', 'Hiburan', 'Tabungan', 'Gaji / Proyek', 'Lainnya'];
  if (!categories.contains(category)) category = 'Lainnya';
  const methods = ['QRIS · E-Wallet', 'Transfer · BCA', 'Kartu Debit', 'Tunai'];
  if (!methods.contains(method)) method = 'QRIS · E-Wallet';
  final wallets = ctrl.dashboard?.wallets ?? [];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MorfinColors.pistachio,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? 'Edit Transaksi' : 'Catat Transaksi Baru', style: MorfinTheme.display(20)),
                  if (isEdit)
                    IconButton(
                      tooltip: 'Hapus Transaksi',
                      icon: const Icon(Icons.delete_outline_rounded, color: MorfinColors.coral),
                      onPressed: saving
                          ? null
                          : () async {
                              setState(() => saving = true);
                              await ctrl.deleteTransaction(existing.id);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                showMorfinToast(context, 'Transaksi dihapus');
                              }
                            },
                    ),
                ],
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 8),
              _quickAmountChips(amountCtrl, () => setState(() {})),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: _fieldDeco('Kategori'),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => category = v ?? 'Makan'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: _fieldDeco('Metode Pembayaran'),
                items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => method = v ?? 'QRIS · E-Wallet'),
              ),
              if (!isEdit && wallets.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: selectedWalletId,
                  decoration: _fieldDeco('Hubungkan ke Kantong (Opsional)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Tanpa Kantong')),
                    ...wallets.map((w) => DropdownMenuItem<String?>(value: w.id, child: Text(w.name))),
                  ],
                  onChanged: (v) => setState(() => selectedWalletId = v),
                ),
              ],
              if (!isEdit) ...[
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          selectedDate.hour,
                          selectedDate.minute,
                        );
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: MorfinColors.ink.withValues(alpha: 0.14)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 17, color: MorfinColors.muted),
                        const SizedBox(width: 10),
                        Text(
                          'Tanggal: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                          style: MorfinTheme.body(13, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(errorMsg!, style: MorfinTheme.body(12, color: MorfinColors.coral, weight: FontWeight.w700)),
              ],
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
                          if (titleCtrl.text.trim().isEmpty) {
                            setState(() => errorMsg = 'Keterangan wajib diisi.');
                            return;
                          }
                          if (amount <= 0) {
                            setState(() => errorMsg = 'Masukkan nominal lebih dari Rp 0.');
                            return;
                          }
                          setState(() {
                            saving = true;
                            errorMsg = null;
                          });
                          try {
                            if (isEdit) {
                              await ctrl.editTransaction(
                                existing.id,
                                title: titleCtrl.text.trim(),
                                category: category,
                                type: type,
                                amount: amount,
                                paymentMethod: method,
                                verified: existing.verified,
                              );
                            } else {
                              await ctrl.addTransaction(
                                title: titleCtrl.text.trim(),
                                category: category,
                                type: type,
                                amount: amount,
                                paymentMethod: method,
                                walletId: selectedWalletId,
                                occurredAt: selectedDate,
                              );
                            }
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              showMorfinToast(context, isEdit ? 'Transaksi diperbarui' : 'Transaksi disimpan');
                            }
                          } catch (e) {
                            setState(() => errorMsg = e.toString());
                          } finally {
                            if (ctx.mounted) setState(() => saving = false);
                          }
                        },
                  child: saving
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: MorfinColors.lime))
                      : Text('Simpan', style: MorfinTheme.display(15, color: MorfinColors.lime)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showAddBudgetSheet(
  BuildContext context,
  MorfinController ctrl, {
  MorfinBudget? existing,
}) async {
  final isEdit = existing != null;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final limitCtrl = TextEditingController(text: existing != null ? existing.limitAmount.toString() : '');
  final spentCtrl = TextEditingController(text: existing != null ? existing.spentAmount.toString() : '0');
  String category = existing?.category ?? 'Makan';
  String period = existing?.period ?? ctrl.selectedBudgetPeriod;
  bool saving = false;
  String? errorMsg;

  const categories = ['Makan', 'Transport', 'Tagihan', 'Cloud AI', 'Edukasi', 'Hiburan', 'Tabungan', 'Lainnya'];
  if (!categories.contains(category)) category = 'Makan';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MorfinColors.pistachio,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? 'Edit Anggaran' : 'Buat Anggaran Baru', style: MorfinTheme.display(20)),
                  if (isEdit)
                    IconButton(
                      tooltip: 'Hapus Anggaran',
                      icon: const Icon(Icons.delete_outline_rounded, color: MorfinColors.coral),
                      onPressed: saving
                          ? null
                          : () async {
                              setState(() => saving = true);
                              await ctrl.deleteBudget(existing.id);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                showMorfinToast(context, 'Anggaran dihapus');
                              }
                            },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, decoration: _fieldDeco('Nama Anggaran', hint: 'Contoh: Belanja Mingguan')),
              const SizedBox(height: 12),
              TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: _fieldDeco('Batas Nominal (Rp)', hint: '500000')),
              const SizedBox(height: 8),
              _quickAmountChips(limitCtrl, () => setState(() {})),
              if (isEdit) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: spentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDeco('Sudah Terpakai (Rp)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => spentCtrl.text = '0'),
                      child: Text('Reset 0', style: MorfinTheme.body(12, color: MorfinColors.coral, weight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
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
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => category = v ?? 'Makan'),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(errorMsg!, style: MorfinTheme.body(12, color: MorfinColors.coral, weight: FontWeight.w700)),
              ],
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
                          if (nameCtrl.text.trim().isEmpty || limit <= 0) {
                            setState(() => errorMsg = 'Nama dan batas nominal wajib diisi.');
                            return;
                          }
                          setState(() => saving = true);
                          try {
                            if (isEdit) {
                              final spent = int.tryParse(spentCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                              await ctrl.editBudget(
                                existing.id,
                                name: nameCtrl.text.trim(),
                                category: category,
                                period: period,
                                limitAmount: limit,
                                spentAmount: spent,
                              );
                            } else {
                              await ctrl.addBudget(
                                name: nameCtrl.text.trim(),
                                category: category,
                                period: period,
                                limitAmount: limit,
                              );
                            }
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              showMorfinToast(context, isEdit ? 'Anggaran diperbarui' : 'Anggaran disimpan');
                            }
                          } finally {
                            if (ctx.mounted) setState(() => saving = false);
                          }
                        },
                  child: Text('Simpan', style: MorfinTheme.display(15, color: MorfinColors.lime)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showAddWalletSheet(BuildContext context, MorfinController ctrl) async {
  final nameCtrl = TextEditingController();
  final targetCtrl = TextEditingController();
  final currentCtrl = TextEditingController(text: '0');
  String icon = 'shield';
  String colorVariant = 'lime';
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MorfinColors.pistachio,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Text('Buat Kantong Tabungan', style: MorfinTheme.display(20)),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, decoration: _fieldDeco('Nama Kantong', hint: 'Contoh: Dana Nikah / Tabungan HP')),
              const SizedBox(height: 12),
              TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: _fieldDeco('Target (Rp)', hint: '10000000')),
              const SizedBox(height: 12),
              TextField(controller: currentCtrl, keyboardType: TextInputType.number, decoration: _fieldDeco('Saldo Awal (Rp)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: icon,
                decoration: _fieldDeco('Ikon'),
                items: const [
                  DropdownMenuItem(value: 'shield', child: Text('Perisai (Dana Darurat)')),
                  DropdownMenuItem(value: 'laptop', child: Text('Laptop / Gadget')),
                  DropdownMenuItem(value: 'chart', child: Text('Investasi / Saham')),
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
                          final current = int.tryParse(currentCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          if (nameCtrl.text.trim().isEmpty) return;
                          setState(() => saving = true);
                          try {
                            await ctrl.addWallet(
                              name: nameCtrl.text.trim(),
                              icon: icon,
                              colorVariant: colorVariant,
                              currentAmount: current,
                              targetAmount: target,
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              showMorfinToast(context, 'Kantong berhasil dibuat');
                            }
                          } finally {
                            if (ctx.mounted) setState(() => saving = false);
                          }
                        },
                  child: Text('Simpan', style: MorfinTheme.display(15, color: MorfinColors.lime)),
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
  bool isWithdraw = false;
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MorfinColors.pistachio,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(wallet.name, style: MorfinTheme.display(19)),
                IconButton(
                  tooltip: 'Hapus Kantong',
                  icon: const Icon(Icons.delete_outline_rounded, color: MorfinColors.coral),
                  onPressed: saving
                      ? null
                      : () async {
                          setState(() => saving = true);
                          await ctrl.deleteWallet(wallet.id);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            showMorfinToast(context, 'Kantong dihapus');
                          }
                        },
                ),
              ],
            ),
            Text(
              'Terkumpul: ${formatIdr(wallet.currentAmount)} / ${formatIdr(wallet.targetAmount)} (${wallet.progressPercent}%)',
              style: MorfinTheme.body(12.5, color: MorfinColors.muted, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Top Up (+)')),
                    selected: !isWithdraw,
                    selectedColor: MorfinColors.lime,
                    onSelected: (_) => setState(() => isWithdraw = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Tarik (-)')),
                    selected: isWithdraw,
                    selectedColor: MorfinColors.carbon,
                    labelStyle: TextStyle(color: isWithdraw ? Colors.white : MorfinColors.ink, fontWeight: FontWeight.w700),
                    onSelected: (_) => setState(() => isWithdraw = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: _fieldDeco('Nominal (Rp)')),
            const SizedBox(height: 8),
            _quickAmountChips(amtCtrl, () => setState(() {})),
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
                        final val = int.tryParse(amtCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                        if (val <= 0) return;
                        setState(() => saving = true);
                        try {
                          await ctrl.topUpWallet(wallet, isWithdraw ? -val : val);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            showMorfinToast(context, isWithdraw ? 'Saldo kantong ditarik' : 'Saldo kantong ditambahkan');
                          }
                        } finally {
                          if (ctx.mounted) setState(() => saving = false);
                        }
                      },
                child: Text('Simpan', style: MorfinTheme.display(15, color: MorfinColors.lime)),
              ),
            ),
          ],
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
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
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
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              showMorfinToast(context, 'Target berhasil disimpan');
                            }
                          } finally {
                            if (ctx.mounted) setState(() => saving = false);
                          }
                        },
                  child: Text('Simpan', style: MorfinTheme.display(15, color: MorfinColors.lime)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showGoalDetailSheet(BuildContext context, MorfinController ctrl, MorfinGoal goal) async {
  final addCtrl = TextEditingController();
  String status = goal.status;
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MorfinColors.pistachio,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(goal.title, style: MorfinTheme.display(20))),
                  IconButton(
                    tooltip: 'Hapus Target',
                    icon: const Icon(Icons.delete_outline_rounded, color: MorfinColors.coral),
                    onPressed: saving
                        ? null
                        : () async {
                            setState(() => saving = true);
                            await ctrl.deleteGoal(goal.id);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              showMorfinToast(context, 'Target dihapus');
                            }
                          },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${formatIdr(goal.savedAmount)} / ${formatIdr(goal.targetAmount)} (${goal.progressPercent}%)',
                style: MorfinTheme.body(13, color: MorfinColors.muted, weight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: (goal.progressPercent / 100.0).clamp(0.0, 1.0),
                  backgroundColor: MorfinColors.ink.withValues(alpha: 0.1),
                  color: MorfinColors.lime,
                ),
              ),
              const SizedBox(height: 14),
              Text('Status Target', style: MorfinTheme.body(12, color: MorfinColors.muted, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ('active', 'Berjalan'),
                  ('completed', 'Tercapai'),
                  ('paused', 'Tertunda'),
                ].map((opt) {
                  final sel = status == opt.$1;
                  return ChoiceChip(
                    label: Text(opt.$2),
                    selected: sel,
                    selectedColor: opt.$1 == 'completed' ? MorfinColors.lime : MorfinColors.carbon,
                    labelStyle: TextStyle(
                      color: sel && opt.$1 != 'completed' ? Colors.white : MorfinColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => status = opt.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addCtrl,
                keyboardType: TextInputType.number,
                decoration: _fieldDeco('Tambah Tabungan Target (Rp, Opsional)', hint: '250000'),
              ),
              const SizedBox(height: 8),
              _quickAmountChips(addCtrl, () => setState(() {})),
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
                          final extra = int.tryParse(addCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          final nextSaved = goal.savedAmount + extra;
                          final nextStatus = (goal.targetAmount > 0 && nextSaved >= goal.targetAmount) ? 'completed' : status;
                          setState(() => saving = true);
                          try {
                            await ctrl.updateGoalDetails(goal, savedAmount: nextSaved, status: nextStatus);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              showMorfinToast(context, 'Target diperbarui');
                            }
                          } finally {
                            if (ctx.mounted) setState(() => saving = false);
                          }
                        },
                  child: Text('Simpan', style: MorfinTheme.display(15, color: MorfinColors.lime)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showProfileSheet(BuildContext context, MorfinController ctrl) async {
  final user = ctrl.user;
  final summary = ctrl.dashboard?.summary;
  final nameCtrl = TextEditingController(text: user?.name ?? '');
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MorfinColors.pistachio,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Text('Profil & Ringkasan', style: MorfinTheme.display(20)),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: MorfinTheme.body(12.5, color: MorfinColors.muted, weight: FontWeight.w600)),
              const SizedBox(height: 14),

              // Income vs Expense Summary Strip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: MorfinColors.carbon, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Pemasukan', style: MorfinTheme.body(10.5, color: MorfinColors.mutedLight)),
                          const SizedBox(height: 3),
                          Text(formatIdrCompact(summary?.totalIncome ?? 0), style: MorfinTheme.display(15, color: MorfinColors.lime)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 34, color: Colors.white12),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Pengeluaran', style: MorfinTheme.body(10.5, color: MorfinColors.mutedLight)),
                          const SizedBox(height: 3),
                          Text(formatIdrCompact(summary?.totalExpense ?? 0), style: MorfinTheme.display(15, color: MorfinColors.coralSoft)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              TextField(controller: nameCtrl, decoration: _fieldDeco('Nama Tampilan')),
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MorfinColors.carbon,
                    foregroundColor: MorfinColors.lime,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().length < 2) return;
                          setState(() => saving = true);
                          try {
                            await ctrl.updateProfileName(nameCtrl.text.trim());
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              showMorfinToast(context, 'Nama profil disimpan');
                            }
                          } finally {
                            if (ctx.mounted) setState(() => saving = false);
                          }
                        },
                  child: Text('Simpan', style: MorfinTheme.display(14, color: MorfinColors.lime)),
                ),
              ),
              const SizedBox(height: 12),

              // Export Report to Clipboard
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: MorfinColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text('Salin Ringkasan Keuangan (CSV)', style: MorfinTheme.body(13, weight: FontWeight.w700)),
                onPressed: () async {
                  final txs = ctrl.dashboard?.transactions ?? [];
                  final buf = StringBuffer('Tanggal,Jenis,Kategori,Keterangan,Nominal\n');
                  for (final t in txs) {
                    buf.writeln('${DateFormat('yyyy-MM-dd').format(t.occurredAt)},${t.type},${t.category},"${t.title}",${t.amount}');
                  }
                  await Clipboard.setData(ClipboardData(text: buf.toString()));
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    showMorfinToast(context, 'Laporan CSV disalin ke clipboard');
                  }
                },
              ),
              const SizedBox(height: 8),

              // Reset Data to Rp 0 (Blank Slate)
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
                    context: ctx,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Bersihkan Semua Data?'),
                      content: const Text('Semua transaksi, anggaran, kantong, dan target saat ini akan dihapus agar Anda bisa mulai mencatat dari Rp 0.'),
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
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      showMorfinToast(context, 'Data dibersihkan — mulai dari Rp 0');
                    }
                  }
                },
              ),
              const SizedBox(height: 8),

              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ctrl.logout();
                },
                icon: const Icon(Icons.logout_rounded, size: 18, color: MorfinColors.muted),
                label: Text('Keluar Akun', style: MorfinTheme.body(13, color: MorfinColors.muted, weight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
