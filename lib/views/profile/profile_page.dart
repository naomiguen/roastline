import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/task_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/notification_service.dart';
import '../notifications/notification_page.dart';

/// Use case: Melihat Profil Pengguna (+ Logout).
/// Halaman ini di-push dari avatar pada dashboard (punya tombol back).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.roastBg,
                  border: Border.all(color: AppColors.roastBorder, width: 2),
                ),
                child: const Icon(Icons.priority_high_rounded,
                    color: AppColors.maroon, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Yakin mau log out?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Deadline-mu masih nunggu lho! Nanti dicariin RoastBot pas '
                'telat ngumpulin, baru tau rasa... \u{1F605}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.maroon,
                    side: const BorderSide(color: AppColors.maroon),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Batal (Lanjut Kerja)'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Keluar Saja'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (yes == true && context.mounted) {
      context.read<TaskController>().clear();
      context.read<ProfileController>().clear();
      context.read<NotificationController>().clear();
      await context.read<AuthController>().logout();
      // AuthGate akan otomatis kembali ke LoginPage.
    }
  }

  Future<void> _editName(BuildContext context) async {
    final profileC = context.read<ProfileController>();
    final controller =
        TextEditingController(text: profileC.profile?.fullName ?? '');
    final messenger = ScaffoldMessenger.of(context);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Nama'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nama lengkap'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;
    final ok = await profileC.updateName(newName);
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'Nama diperbarui' : (profileC.error ?? 'Gagal')),
    ));
  }

  Future<void> _changePassword(BuildContext context) async {
    final auth = context.read<AuthController>();
    final passC = TextEditingController();
    final confirmC = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passC,
                obscureText: true,
                decoration:
                    const InputDecoration(hintText: 'Password baru (min 6)'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmC,
                obscureText: true,
                decoration:
                    const InputDecoration(hintText: 'Ulangi password baru'),
                validator: (v) =>
                    v != passC.text ? 'Password tidak sama' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (submit != true) return;
    final ok = await auth.changePassword(passC.text);
    messenger.showSnackBar(SnackBar(
      content: Text(
        ok ? 'Password berhasil diganti' : (auth.error ?? 'Gagal ganti password'),
      ),
    ));
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Julidline',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.local_fire_department,
          color: AppColors.maroon, size: 36),
      children: const [
        SizedBox(height: 8),
        Text(
          'Aplikasi manajemen deadline yang nge-roast kamu kalau nunda tugas. '
          'Dibuat untuk tugas Pemrograman Aplikasi & Perangkat Bergerak.\n\n'
          'Tech stack: Flutter, Supabase, Firebase Cloud Messaging.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileC = context.watch<ProfileController>();
    final profile = profileC.profile;
    final unread = context.watch<NotificationController>().unreadCount;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profil Pengguna'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => profileC.loadProfile(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Kartu profil
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.maroon,
                    child: Text(
                      profile?.initials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (profile?.fullName.trim().isNotEmpty ?? false)
                              ? profile!.fullName
                              : 'Tanpa Nama',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile?.email ?? '-',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 20, color: AppColors.maroon),
                    tooltip: 'Edit nama',
                    onPressed: () => _editName(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.notifications_outlined,
              title: 'Notifikasi',
              badge: unread > 0 ? '$unread' : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              ),
            ),
            _MenuTile(
              icon: Icons.lock_outline,
              title: 'Ganti Password',
              onTap: () => _changePassword(context),
            ),
            _MenuTile(
              icon: Icons.info_outline,
              title: 'Tentang Aplikasi',
              onTap: () => _showAbout(context),
            ),
            _MenuTile(
              icon: Icons.notifications_active_outlined,
              title: 'Tes Notifikasi',
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final msg = await NotificationService.sendTest();
                messenger.showSnackBar(
                  SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
                );
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => _confirmLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.maroon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text('Keluar Akun'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: AppColors.maroon),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.maroon,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
