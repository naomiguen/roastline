import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/reminder.dart';
import '../data/models/task_model.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/services/notification_service.dart';
import '../data/services/supabase_service.dart';
import 'notification_controller.dart';

class TaskController extends ChangeNotifier {
  TaskController({
    TaskRepository? taskRepository,
    NotificationRepository? notificationRepository,
    NotificationController? notificationController,
    String? Function()? currentUserId,
    bool enableTicker = true,
  })  : _repo = taskRepository ?? TaskRepository(),
        _notif = notificationRepository ?? NotificationRepository(),
        _notifController = notificationController,
        _uidProvider = currentUserId ?? (() => SupabaseService.currentUserId),
        // ignore: prefer_initializing_formals
        _enableTicker = enableTicker;

  final TaskRepository _repo;
  final NotificationRepository _notif;
  NotificationController? _notifController;
  final String? Function() _uidProvider;
  final bool _enableTicker;

  set notificationController(NotificationController c) => _notifController = c;

  /// Ticker foreground: tiap 15 dtk cek apakah ada ambang reminder yang baru
  /// terlewati, lalu munculkan notifikasi + segarkan feed. Ini backstop saat
  /// aplikasi sedang dibuka; kalau app ke-kill, alarm OS yang jalan.
  Timer? _ticker;
  DateTime _lastTick = DateTime.now();

  List<Task> _tasks = [];
  bool _loading = false;
  String? _error;

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _loading;
  String? get error => _error;

  List<Task> get upcoming => _tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completed => _tasks.where((t) => t.isCompleted).toList();

  String? get _uid => _uidProvider();

  Future<void> loadTasks() async {
    final uid = _uid;
    if (uid == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _tasks = await _repo.getTasks(uid);
    } catch (e) {
      _error = 'Gagal memuat tugas: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
    _startTicker();
    // Tidak di-await: penjadwalan reminder & sinkron feed jalan di belakang.
    unawaited(_afterTasksChanged());
  }

  void _startTicker() {
    if (!_enableTicker || _ticker != null) return;
    _lastTick = DateTime.now();
    _scheduleNextTick();
  }

  /// Interval adaptif: cepat (2 dtk) kalau ada ambang < 2 menit lagi,
  /// santai (30 dtk) selain itu — supaya notif terasa "pas" tanpa boros baterai.
  void _scheduleNextTick() {
    _ticker?.cancel();
    final soon = _secondsToNextSlot();
    final interval = (soon != null && soon <= 120)
        ? const Duration(seconds: 2)
        : const Duration(seconds: 30);
    _ticker = Timer(interval, _onTick);
  }

  int? _secondsToNextSlot() {
    final now = DateTime.now();
    int? best;
    for (final t in _tasks) {
      if (t.isCompleted) continue;
      for (final slot in ReminderSlot.values) {
        final d = slot.fireTimeFor(t.deadline).difference(now).inSeconds;
        if (d >= 0 && (best == null || d < best)) best = d;
      }
    }
    return best;
  }

  /// Cek ambang reminder yang baru terlewati sejak tick sebelumnya.
  Future<void> _onTick() async {
    if (_uid != null && _tasks.isNotEmpty) {
      final now = DateTime.now();
      final prev = _lastTick;
      _lastTick = now;

      var crossed = false;
      for (final t in _tasks) {
        if (t.isCompleted || t.idTasks == null) continue;
        for (final slot in ReminderSlot.values) {
          final f = slot.fireTimeFor(t.deadline);
          if (f.isAfter(prev) && !f.isAfter(now)) {
            crossed = true;
            await _safe(() => NotificationService.showForSlot(
                  t.idTasks!,
                  slot,
                  slot.title,
                  reminderBody(slot, t.title),
                ));
          }
        }
      }
      notifyListeners(); // update countdown/urgency di UI
      if (crossed) await loadTasks(); // sweep feed
    }
    _scheduleNextTick();
  }

  /// Use case: Menambah Tugas Baru.
  Future<bool> addTask({
    required String title,
    required String course,
    required DateTime deadline,
    String notes = '',
  }) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final created = await _repo.addTask(Task(
        idProfile: uid,
        title: title,
        course: course,
        deadline: deadline,
        notes: notes,
      ));
      _tasks = [..._tasks, created];
      _sort();
      notifyListeners();

      await _safe(() => _notif.create(
            idProfile: uid,
            idTasks: created.idTasks,
            message: 'Tugas baru ditambahkan: ${created.title}',
            kind: 'task_added',
          ));
      await _afterTasksChanged(); // menjadwalkan reminder tugas baru
      return true;
    } catch (e) {
      _error = 'Gagal menambah tugas: $e';
      notifyListeners();
      return false;
    }
  }

  /// Edit tugas yang sudah ada (judul, mata kuliah, deadline, catatan).
  Future<bool> updateTask({
    required Task original,
    required String title,
    required String course,
    required DateTime deadline,
    String notes = '',
  }) async {
    if (original.idTasks == null) return false;
    final edited = original.copyWith(
      title: title,
      course: course,
      deadline: deadline,
      notes: notes,
    );
    try {
      final saved = await _repo.updateTask(edited);
      _replace(saved);
      _sort();
      notifyListeners();
      // Deadline mungkin berubah -> jadwal ulang reminder & sinkron feed.
      await _afterTasksChanged();
      return true;
    } catch (e) {
      _error = 'Gagal menyimpan perubahan: $e';
      notifyListeners();
      return false;
    }
  }

  /// Use case: Menandai Tugas Selesai.
  Future<void> toggleCompleted(Task task) async {
    final target = !task.isCompleted;
    _replace(task.copyWith(isCompleted: target));
    _sort();
    notifyListeners();
    try {
      final updated = await _repo.setCompleted(task.idTasks!, target);
      _replace(updated);
      if (target) {
        await _safe(() => NotificationService.cancelForTask(updated.idTasks!));
        await _safe(() => _notif.create(
              idProfile: updated.idProfile,
              idTasks: updated.idTasks,
              message: 'Mantap, "${updated.title}" ditandai selesai.',
              kind: 'completed',
            ));
      }
    } catch (e) {
      _replace(task); // rollback
      _error = 'Gagal memperbarui tugas: $e';
      notifyListeners();
      return;
    }
    _sort();
    notifyListeners();
    await _afterTasksChanged(); // reschedule kalau di-batalkan, sinkron feed
  }

  /// Use case: Menghapus Tugas.
  Future<void> deleteTask(Task task) async {
    final backup = _tasks;
    _tasks = _tasks.where((t) => t.idTasks != task.idTasks).toList();
    notifyListeners();
    try {
      await _repo.deleteTask(task.idTasks!);
      await _safe(() => NotificationService.cancelForTask(task.idTasks!));
      // Baris notifications ikut terhapus otomatis (ON DELETE CASCADE).
      await _safe(
          () => _notifController?.loadNotifications() ?? Future.value());
    } catch (e) {
      _tasks = backup; // rollback
      _error = 'Gagal menghapus tugas: $e';
      notifyListeners();
    }
  }

  Task? byId(String id) {
    for (final t in _tasks) {
      if (t.idTasks == id) return t;
    }
    return null;
  }

  /// Setelah daftar tugas berubah: jadwalkan ulang reminder tiap tugas aktif
  /// dan sinkronkan feed notifikasi.
  Future<void> _afterTasksChanged() async {
    for (final t in _tasks.where((t) => !t.isCompleted)) {
      await _safe(() => NotificationService.scheduleForTask(t));
    }
    await _safe(
        () => _notifController?.syncFromTasks(_tasks) ?? Future.value());
  }

  Future<void> _safe(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      debugPrint('TaskController._safe: $e');
    }
  }

  void _replace(Task task) {
    _tasks = [
      for (final t in _tasks)
        if (t.idTasks == task.idTasks) task else t,
    ];
  }

  void _sort() {
    _tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return a.deadline.compareTo(b.deadline);
    });
  }

  void clear() {
    _ticker?.cancel();
    _ticker = null;
    _tasks = [];
    _error = null;
    NotificationService.cancelAll();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
