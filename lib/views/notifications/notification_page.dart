import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/notification_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/notification_model.dart';

/// Menampilkan isi tabel `notifications` milik user (in-app feed).
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().loadNotifications();
    });
  }

  ({IconData icon, Color color}) _style(String kind) {
    switch (kind) {
      case 'task_added':
        return (icon: Icons.add_task, color: AppColors.maroon);
      case 'completed':
        return (icon: Icons.check_circle, color: AppColors.success);
      case 'reminder_24h':
      case 'reminder_6h':
        return (
          icon: Icons.notifications_active_outlined,
          color: AppColors.warning
        );
      case 'reminder_1h':
      case 'due':
        return (icon: Icons.alarm, color: AppColors.danger);
      case 'overdue':
        return (icon: Icons.error_outline, color: AppColors.danger);
      case 'push':
        return (icon: Icons.campaign_outlined, color: AppColors.maroon);
      default:
        return (
          icon: Icons.notifications_outlined,
          color: AppColors.textSecondary
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (c.unreadCount > 0)
            TextButton(
              onPressed: c.markAllAsRead,
              child: const Text(
                'Tandai semua',
                style: TextStyle(color: AppColors.maroon, fontSize: 12.5),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => c.loadNotifications(),
        child: Column(
          children: [
            if (c.infoBanner != null)
              Container(
                width: double.infinity,
                color: AppColors.roastBg,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.maroon, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.infoBanner!,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.maroon),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: _buildBody(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(NotificationController c) {
    if (c.isLoading && c.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.error != null && c.items.isEmpty) {
      return _Placeholder(text: c.error!);
    }
    if (c.items.isEmpty) {
      return const _Placeholder(
        text: 'Belum ada notifikasi.\nTambah tugas dulu, gih.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: c.items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final AppNotification n = c.items[i];
        final s = _style(n.kind);
        return Material(
          color: n.isRead ? AppColors.surface : AppColors.roastBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => c.markAsRead(n),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: s.color.withValues(alpha: 0.14),
                    child: Icon(s.icon, color: s.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.message,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: n.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                        if (n.createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormatter.format(n.createdAt!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!n.isRead)
                    Container(
                      margin: const EdgeInsets.only(top: 4, left: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.maroon,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String text;
  const _Placeholder({required this.text});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
        const Icon(Icons.notifications_off_outlined,
            size: 56, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
