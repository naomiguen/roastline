import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'widgets/auth_header.dart';

/// Layar "buat password baru" — muncul setelah user membuka link reset
/// password dari email (event `passwordRecovery`).
class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await auth.changePassword(_passC.text);
    if (!mounted) return;

    if (ok) {
      await auth.logout();
      auth.exitRecoveryMode();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diubah. Silakan login.'),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Gagal mengubah password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHeader(height: 210),
            Transform.translate(
              offset: const Offset(0, -36),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buat Password Baru',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Masukkan password baru untuk akunmu. Jangan lupa '
                        'lagi ya kali ini.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 22),
                      CustomTextField(
                        label: 'Password Baru',
                        hint: 'Minimal 6 karakter',
                        controller: _passC,
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscure,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Minimal 6 karakter'
                            : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Konfirmasi Password',
                        hint: 'Ulangi password baru',
                        controller: _confirmC,
                        prefixIcon: Icons.verified_user_outlined,
                        obscureText: _obscure,
                        validator: (v) =>
                            v != _passC.text ? 'Password tidak sama' : null,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: 'Simpan Password',
                        loading: loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final auth = context.read<AuthController>();
                            await auth.logout();
                            auth.exitRecoveryMode();
                          },
                          child: const Text(
                            'Batal, kembali ke Login',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.maroon,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
