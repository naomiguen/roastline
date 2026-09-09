import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/task_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/task_model.dart';
import '../task_detail/task_detail_page.dart';
import 'widgets/task_card.dart';

/// Use case: Melihat Daftar Tugas — semua tugas dikelompokkan per waktu.
/// Dipakai sebagai tab "Jadwal" ([embedded] = true) dan halaman "Lihat Semua".
class TaskListPage extends StatelessWidget {
  final bool embedded;
  const TaskListPage({super.key, this.embedded = false});

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final taskC = context.watch<TaskController>();
    final now = DateTime.now();
    final today = _dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));

    final terlambat = <Task>[];
    final hariIni = <Task>[];
    final besok = <Task>[];
    final akanDatang = <Task>[];
    final selesai = <Task>[];

    for (final t in taskC.tasks) {
      if (t.isCompleted) {
        selesai.add(t);
      } else if (t.deadline.isBefore(now)) {
        terlambat.add(t);
      } else {
        final d = _dateOnly(t.deadline);
        if (d == today) {
          hariIni.add(t);
        } else if (d == tomorrow) {
          besok.add(t);
        } else {
          akanDatang.add(t);
        }
      }
    }

    final body = RefreshIndicator(
      onRefresh: () => taskC.loadTasks(),
      child: (taskC.isLoading && taskC.tasks.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : taskC.tasks.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.event_available,
                        size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Belum ada tugas.\nSantai dulu, atau mau di-roast?',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                  children: [
                    _section(context, 'Terlambat', terlambat, AppColors.danger),
                    _section(context, 'Hari Ini', hariIni, AppColors.maroon),
                    _section(context, 'Besok', besok, AppColors.warning),
                    _section(context, 'Akan Datang', akanDatang,
                        AppColors.textSecondary),
                    _section(context, 'Selesai', selesai, AppColors.success),
                  ],
                ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(embedded ? 'Jadwal' : 'Semua Tugas'),
        automaticallyImplyLeading: !embedded,
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<Task> items,
    Color color,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    items.sort((a, b) => a.deadline.compareTo(b.deadline));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Container(width: 4, height: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${items.length})',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        for (final t in items)
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
              onDelete: () => _confirmDelete(context, t),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Task task) async {
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
    if (yes == true && context.mounted) {
      await context.read<TaskController>().deleteTask(task);
    }
  }
}
