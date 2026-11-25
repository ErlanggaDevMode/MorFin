import 'package:flutter/material.dart';
import '../core/theme/morfin_theme.dart';
import '../state/morfin_controller.dart';

class AuthScreen extends StatefulWidget {
  final MorfinController controller;
  const AuthScreen({super.key, required this.controller});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isRegister = false;
  bool obscure = true;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final name = _nameCtrl.text.trim();

    if (isRegister) {
      await widget.controller.registerWithEmail(name: name, email: email, password: pass);
    } else {
      await widget.controller.loginWithEmail(email: email, password: pass);
    }
  }

  InputDecoration _inputDeco(String label, IconData icon, {Widget? suffix}) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: MorfinColors.muted),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        labelStyle: MorfinTheme.body(13, color: MorfinColors.muted, weight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: MorfinColors.ink.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: MorfinColors.ink.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MorfinColors.carbon, width: 1.8),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    return Scaffold(
      backgroundColor: MorfinColors.pistachio,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: MorfinColors.carbon,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: MorfinColors.lime, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MorFin', style: MorfinTheme.display(24)),
                        Text(
                          'Personal Finance Tracker',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MorfinTheme.body(12, color: MorfinColors.muted, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dark hero header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MorfinColors.carbon,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MorfinColors.lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isRegister ? 'AKUN BARU' : 'SELAMAT DATANG',
                        style: MorfinTheme.display(10, color: MorfinColors.ink),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isRegister ? 'Buat Akun MorFin' : 'Masuk ke MorFin',
                      style: MorfinTheme.display(22, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Akses data keuangan Anda secara real-time dengan Email atau OAuth Akun Google.',
                      style: MorfinTheme.body(12.5, color: MorfinColors.mutedLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Segmented Pill Switcher (Masuk | Daftar Baru)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: MorfinColors.ink.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ctrl.clearError();
                          setState(() => isRegister = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: !isRegister ? MorfinColors.carbon : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              'Masuk',
                              style: MorfinTheme.body(13, color: !isRegister ? Colors.white : MorfinColors.muted, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ctrl.clearError();
                          setState(() => isRegister = true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: isRegister ? MorfinColors.carbon : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              'Daftar Baru',
                              style: MorfinTheme.body(13, color: isRegister ? Colors.white : MorfinColors.muted, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (ctrl.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MorfinColors.coral.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: MorfinColors.coral.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    ctrl.errorMessage!,
                    style: MorfinTheme.body(12.5, color: MorfinColors.coral, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (isRegister) ...[
                TextField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDeco('Nama Lengkap', Icons.person_outline_rounded),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _inputDeco('Email', Icons.mail_outline_rounded),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: obscure,
                onSubmitted: (_) => _submitEmail(),
                decoration: _inputDeco(
                  'Password',
                  Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MorfinColors.carbon,
                    foregroundColor: MorfinColors.lime,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: ctrl.isLoading ? null : _submitEmail,
                  child: ctrl.isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: MorfinColors.lime))
                      : Text(
                          isRegister ? 'Daftar & Mulai MorFin' : 'Masuk dengan Email',
                          style: MorfinTheme.display(15, color: MorfinColors.lime),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: Divider(color: MorfinColors.ink.withValues(alpha: 0.15))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('atau', style: MorfinTheme.body(12, color: MorfinColors.muted, weight: FontWeight.w600)),
                  ),
                  Expanded(child: Divider(color: MorfinColors.ink.withValues(alpha: 0.15))),
                ],
              ),
              const SizedBox(height: 16),

              // Google OAuth Button
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: MorfinColors.ink,
                    side: BorderSide(color: MorfinColors.ink.withValues(alpha: 0.16), width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: ctrl.isLoading ? null : () => ctrl.loginWithGoogle(),
                  icon: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: MorfinColors.lime.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('G', style: MorfinTheme.display(14, color: MorfinColors.ink)),
                    ),
                  ),
                  label: Text(
                    'Lanjutkan dengan Akun Google',
                    style: MorfinTheme.body(14, weight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Backend VPS: PostgreSQL 17 · JWT + OAuth 2.0',
                  style: MorfinTheme.body(11, color: MorfinColors.muted, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
