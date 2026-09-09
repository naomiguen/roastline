import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/task_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/roast_generator.dart';
import '../../data/models/task_model.dart';
import '../add_task/add_task_page.dart';

/// Use case: Melihat Detail Tugas, Menandai Tugas Selesai, Menghapus Tugas.
class TaskDetailPage extends StatefulWidget {
  final String taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  Timer? _timer;
  String? _roast;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int v) => v.toString().padLeft(2, '0');

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
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = context.watch<TaskController>().byId(widget.taskId);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tugas')),
        body: const Center(child: Text('Tugas tidak ditemukan.')),
      );
    }

    final remaining = task.deadline.difference(DateTime.now());
    final overdue = remaining.isNegative;
    final abs = remaining.abs();
    final days = abs.inDays;
    final hours = abs.inHours % 24;
    final minutes = abs.inMinutes % 60;
    final seconds = abs.inSeconds % 60;

    _roast ??= RoastGenerator.forRemaining(remaining);

    final urgency = urgencyOf(task.deadline);
    final critical = urgency == DeadlineUrgency.telat ||
        urgency == DeadlineUrgency.kritis;

    // Sisa waktu: Hari/Jam/Menit kalau masih >= 1 hari.
    // Kalau sudah telat, selalu tampilkan detik biar terlihat berjalan
    // (mis. telat di bawah 1 menit -> 00 : 00 : 42).
    final showDays = !overdue && days >= 1;
    final cells = showDays
        ? [
            (_two(days), 'Hari'),
            (_two(hours), 'Jam'),
            (_two(minutes), 'Menit'),
          ]
        : [
            (_two(overdue ? abs.inHours : hours), 'Jam'),
            (_two(minutes), 'Menit'),
            (_two(seconds), 'Detik'),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit tugas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddTaskPage(task: task)),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') _confirmDelete(task);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                    SizedBox(width: 8),
                    Text('Hapus Tugas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (!task.isCompleted && critical)
            Center(
              child: Text(
                overdue ? 'DEADLINE TERLEWAT' : 'CRITICAL DEADLINE',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            task.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            task.course,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Countdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: task.isCompleted
                    ? AppColors.success
                    : (critical ? AppColors.danger : const Color(0xFFE8E8E8)),
              ),
            ),
            child: Column(
              children: [
                Text(
                  task.isCompleted
                      ? 'TUGAS SELESAI'
                      : (overdue ? 'SUDAH TELAT' : 'SISA WAKTU KAMU'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: task.isCompleted
                        ? AppColors.success
                        : (overdue
                            ? AppColors.danger
                            : AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),
                if (task.isCompleted)
                  const Icon(Icons.verified, color: AppColors.success, size: 56)
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < cells.length; i++) ...[
                        _TimeCell(value: cells[i].$1, label: cells[i].$2),
                        if (i < cells.length - 1) _sep(),
                      ],
                    ],
                  ),
                const SizedBox(height: 14),
                Text(
                  'Deadline: ${DateFormatter.format(task.deadline)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!task.isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.maroon,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _roast!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          const SizedBox(height: 18),

          const Text(
            'Catatan:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            task.notes.trim().isEmpty ? '(tidak ada catatan)' : task.notes,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 26),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () =>
                  context.read<TaskController>().toggleCompleted(task),
              style: ElevatedButton.styleFrom(
                backgroundColor: task.isCompleted
                    ? AppColors.textSecondary
                    : AppColors.maroon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                task.isCompleted ? 'Batalkan Selesai' : 'Tandai Selesai',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sep() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          ':',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.maroon,
          ),
        ),
      );
}

class _TimeCell extends StatelessWidget {
  final String value;
  final String label;
  const _TimeCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.maroon,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
