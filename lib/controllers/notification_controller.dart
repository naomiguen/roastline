import 'package:flutter/foundation.dart';

import '../data/models/notification_model.dart';
import '../data/models/task_model.dart';
import '../data/repositories/notification_repository.dart';
import '../data/services/supabase_service.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({NotificationRepository? repository})
      : _repo = repository ?? NotificationRepository();

  final NotificationRepository _repo;

  List<AppNotification> _items = [];
  bool _loading = false;
  String? _error;
  String? _infoBanner;

  List<AppNotification> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  String? get error => _error;

  /// Peringatan non-fatal (mis. sweep reminder gagal karena skema lama).
  String? get infoBanner => _infoBanner;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  String? get _uid => SupabaseService.currentUserId;

  Future<void> loadNotifications() async {
    final uid = _uid;
    if (uid == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repo.getNotifications(uid);
    } catch (e) {
      _error = 'Gagal memuat notifikasi: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Catat reminder yang ambangnya sudah lewat lalu muat ulang feed.
  /// Dipanggil setelah daftar tugas berubah.
  Future<void> syncFromTasks(List<Task> tasks) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _repo.sweepReminders(uid, tasks);
      _infoBanner = null;
    } catch (e) {
      debugPrint('syncFromTasks gagal: $e');
      _infoBanner = 'Sebagian notifikasi gagal disimpan. Pastikan '
          'supabase/schema.sql sudah dijalankan di project Supabase kamu.';
    }
    await loadNotifications();
  }

  Future<void> markAsRead(AppNotification n) async {
    if (n.isRead) return;
    _items = [
      for (final it in _items)
        if (it.idNotification == n.idNotification)
          it.copyWith(isRead: true)
        else
          it,
    ];
    notifyListeners();
    try {
      await _repo.markAsRead(n.idNotification);
    } catch (_) {
      await loadNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null || unreadCount == 0) return;
    _items = [for (final it in _items) it.copyWith(isRead: true)];
    notifyListeners();
    try {
      await _repo.markAllAsRead(uid);
    } catch (_) {
      await loadNotifications();
    }
  }

  void clear() {
    _items = [];
    _error = null;
    _infoBanner = null;
    notifyListeners();
  }
}
