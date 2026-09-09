import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/roast_generator.dart';
import '../../../data/models/task_model.dart';

/// Kartu tugas sesuai desain home-dashboard:
/// judul + badge, mata kuliah, sisa waktu, kutipan roast, tombol hapus + selesai.
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  ({Color color, String label}) get _badge {
    if (task.isCompleted) return (color: AppColors.success, label: 'SELESAI');
    switch (urgencyOf(task.deadline)) {
      case DeadlineUrgency.telat:
        return (color: AppColors.danger, label: 'TELAT');
      case DeadlineUrgency.kritis:
        return (color: AppColors.danger, label: 'KRITIS');
      case DeadlineUrgency.sedang:
        return (color: AppColors.warning, label: 'SEDANG');
      case DeadlineUrgency.santai:
        return (color: AppColors.textSecondary, label: 'SANTAI');
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final done = task.isCompleted;
    final timeColor = done ? AppColors.textSecondary : badge.color;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                        color: done
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badge.color),
                    ),
                    child: Text(
                      badge.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                        color: badge.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                task.course,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    done ? Icons.check_circle_outline : Icons.access_time,
                    size: 13,
                    color: done ? AppColors.success : timeColor,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      done
                          ? (task.finishedAt != null
                              ? 'Diselesaikan ${DateFormatter.format(task.finishedAt!)}'
                              : 'Sudah selesai')
                          : DateFormatter.sisaWaktu(task.deadline),
                      style: TextStyle(
                        fontSize: 12,
                        color: done ? AppColors.success : timeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (!done) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.quoteBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"${RoastGenerator.forRemaining(task.remaining)}"',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _IconSquareButton(
                    icon: Icons.delete_outline,
                    onTap: onDelete,
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onToggle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: done
                            ? AppColors.textSecondary
                            : AppColors.maroon,
                        minimumSize: const Size(96, 36),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(done ? 'Batalkan' : 'Selesai'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconSquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}
