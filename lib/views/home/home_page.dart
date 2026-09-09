import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/notification_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/task_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/notification_service.dart';
import '../add_task/add_task_page.dart';
import '../dashboard/dashboard_page.dart';
import '../notifications/notification_page.dart';
import '../task_list/task_list_page.dart';

/// Shell utama: bottom nav (Utama / Jadwal) + FAB tengah untuk Tambah Tugas.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.tappedPayload.addListener(_onNotificationTapped);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermissions();
      context.read<ProfileController>().loadProfile();
      context.read<NotificationController>().loadNotifications();
      // loadTasks terakhir: memicu penjadwalan reminder + sweep feed.
      context.read<TaskController>().loadTasks();
      _onNotificationTapped(); // kalau app dibuka dari tap notifikasi
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.tappedPayload.removeListener(_onNotificationTapped);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Balik ke app (mis. setelah lihat notifikasi OS) -> feed & tugas disegarkan.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<TaskController>().loadTasks();
      context.read<NotificationController>().loadNotifications();
    }
  }

  void _onNotificationTapped() {
    final payload = NotificationService.tappedPayload.value;
    if (payload == null || !mounted) return;
    NotificationService.tappedPayload.value = null;
    // Semua notifikasi tugas diarahkan ke halaman Notifikasi.
    context.read<TaskController>().loadTasks();
    context.read<NotificationController>().loadNotifications();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
  }

  Future<void> _openAddTask() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskPage()),
    );
    if (created == true && mounted) {
      context.read<TaskController>().loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    const pages = [DashboardPage(), TaskListPage(embedded: true)];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: SizedBox(
        width: 58,
        height: 58,
        child: FloatingActionButton(
          onPressed: _openAddTask,
          backgroundColor: AppColors.maroon,
          elevation: 3,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 62,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_rounded,
                label: 'Utama',
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
            ),
            const SizedBox(width: 58),
            Expanded(
              child: _NavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Jadwal',
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.maroon : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
