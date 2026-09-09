import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/notification_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/task_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/roast_generator.dart';
import '../../data/models/task_model.dart';
import '../profile/profile_page.dart';
import '../task_detail/task_detail_page.dart';
import '../task_list/task_list_page.dart';
import '../task_list/widgets/task_card.dart';
import 'widgets/week_strip.dart';

/// Layar "Utama" — sesuai desain home-dashboard.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime? _selectedDay;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Urutan "Tugas Terdekat": yang paling telat di atas, lalu menuju
  /// deadline paling jauh di bawah.
  static int _byUrgency(Task a, Task b) {
    if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
    return a.deadline.compareTo(b.deadline);
  }

  Future<void> _confirmDelete(Task task) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tugas?'),
        content: Text('"${task.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await context.read<TaskController>().deleteTask(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskC = context.watch<TaskController>();
    final profileC = context.watch<ProfileController>();
    final firstName = (profileC.profile?.fullName.trim().isNotEmpty ?? false)
        ? profileC.profile!.fullName.trim().split(RegExp(r'\s+')).first
        : 'Kamu';

    final upcoming = taskC.upcoming;
    final deadlineDays =
        taskC.tasks.map((t) => _dateOnly(t.deadline)).toSet();

    final roast = upcoming.isEmpty
        ? 'SANTAI BOLEH, MALES JANGAN.'
        : RoastGenerator.forRemaining(
            upcoming.map((t) => t.remaining).reduce((a, b) => a < b ? a : b),
          );

    // Daftar yang ditampilkan: kalau ada tanggal dipilih -> semua tugas di
    // tanggal itu (urut jam); kalau tidak -> tugas aktif, telat dulu lalu
    // deadline terdekat sampai terjauh.
    final List<Task> shown;
    if (_selectedDay != null) {
      shown = taskC.tasks
          .where((t) => _dateOnly(t.deadline) == _selectedDay)
          .toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));
    } else {
      shown = [...upcoming]..sort(_byUrgency);
    }
    final display = _selectedDay != null ? shown : shown.take(5).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => taskC.loadTasks(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hai, $firstName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _AvatarButton(
                    initials: profileC.profile?.initials ?? '?',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Kalimat roast harian
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.roastBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.roastBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: AppColors.maroon, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        roast,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.maroon,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ringkasan singkat
              Row(
                children: [
                  _StatCell(
                    label: 'Aktif',
                    value: upcoming.length,
                    color: AppColors.maroon,
                  ),
                  const SizedBox(width: 10),
                  _StatCell(
                    label: 'Telat',
                    value: taskC.tasks.where((t) => t.isOverdue).length,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 10),
                  _StatCell(
                    label: 'Selesai',
                    value: taskC.completed.length,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              WeekStrip(
                deadlineDays: deadlineDays,
                selectedDay: _selectedDay,
                onSelect: (d) => setState(() => _selectedDay = d),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDay != null
                          ? 'Tugas • ${DateFormatter.tanggalPendek(_selectedDay!)}'
                          : 'Tugas Terdekat',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_selectedDay != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedDay = null),
                      child: const Text(
                        'Semua',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.maroon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TaskListPage(),
                        ),
                      ),
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.maroon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (taskC.isLoading && taskC.tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (taskC.error != null && taskC.tasks.isEmpty)
                _InfoBox(
                  icon: Icons.cloud_off,
                  text: taskC.error!,
                  action: TextButton(
                    onPressed: taskC.loadTasks,
                    child: const Text('Coba lagi'),
                  ),
                )
              else if (display.isEmpty)
                _InfoBox(
                  icon: Icons.inbox_outlined,
                  text: _selectedDay != null
                      ? 'Nggak ada tugas di tanggal ini.'
                      : 'Belum ada tugas aktif.\nTambah lewat tombol + di bawah.',
                )
              else
                for (final Task t in display)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(
                      task: t,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailPage(taskId: t.idTasks!),
                        ),
                      ),
                      onToggle: () =>
                          context.read<TaskController>().toggleCompleted(t),
                      onDelete: () => _confirmDelete(t),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  final String initials;
  final VoidCallback onTap;
  const _AvatarButton({required this.initials, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationController>().unreadCount;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.maroon,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const _InfoBox({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (action != null) ...[const SizedBox(height: 4), action!],
        ],
      ),
    );
  }
}
