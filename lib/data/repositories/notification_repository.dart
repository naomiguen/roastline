import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/reminder.dart';
import '../models/notification_model.dart';
import '../models/task_model.dart';
import '../services/supabase_service.dart';

class NotificationRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Jadi `false` otomatis kalau tabel `notifications` belum punya kolom `kind`
  /// (skema lama). Aplikasi tetap jalan; dedup jatuh ke per-tugas.
  static bool _kindSupported = true;

  static bool _isMissingColumn(Object e, String col) {
    final s = e.toString().toLowerCase();
    return s.contains(col) &&
        (s.contains('column') ||
            s.contains('schema cache') ||
            s.contains('pgrst204') ||
            s.contains('42703'));
  }

  /// Error per-baris yang aman diabaikan: duplikat (23505) atau tugas
  /// referensinya sudah dihapus (FK violation 23503).
  static bool _isIgnorableRowError(Object e) {
    if (e is PostgrestException && (e.code == '23505' || e.code == '23503')) {
      return true;
    }
    final s = e.toString().toLowerCase();
    return s.contains('duplicate key') ||
        s.contains('23505') ||
        s.contains('foreign key') ||
        s.contains('23503');
  }

  Map<String, dynamic> _row(
    String idProfile,
    String? idTasks,
    String message,
    String kind,
  ) {
    final r = <String, dynamic>{
      'id_profile': idProfile,
      'id_tasks': idTasks,
      'message': message,
    };
    if (_kindSupported) r['kind'] = kind;
    return r;
  }

  Future<List<AppNotification>> getNotifications(String idProfile) async {
    try {
      final data = await _client
          .from('notifications')
          .select()
          .eq('id_profile', idProfile)
          .order('created_at', ascending: false)
          .limit(100);
      return (data as List)
          .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (_isMissingColumn(e, 'created_at')) {
        final data = await _client
            .from('notifications')
            .select()
            .eq('id_profile', idProfile)
            .limit(100);
        return (data as List)
            .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  /// Pasangan kunci ("idTasks|kind" atau "idTasks|") yang sudah ada di feed.
  Future<Set<String>> _existingKeys(String idProfile) async {
    Future<Set<String>> run() async {
      final cols = _kindSupported ? 'id_tasks, kind' : 'id_tasks';
      final rows = await _client
          .from('notifications')
          .select(cols)
          .eq('id_profile', idProfile)
          .not('id_tasks', 'is', null);
      return {
        for (final r in rows as List)
          _kindSupported
              ? "${r['id_tasks']}|${r['kind']}"
              : "${r['id_tasks']}|",
      };
    }

    try {
      return await run();
    } on PostgrestException catch (e) {
      if (_kindSupported && _isMissingColumn(e, 'kind')) {
        _kindSupported = false;
        return run();
      }
      rethrow;
    }
  }

  /// Insert per baris supaya satu baris gagal tidak menggagalkan semuanya.
  /// Toleran terhadap: duplikat (unique index) & kolom `kind` belum ada.
  Future<void> _insert(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _insertOne(row);
    }
  }

  Future<void> _insertOne(Map<String, dynamic> row) async {
    try {
      await _client.from('notifications').insert(row);
    } on PostgrestException catch (e) {
      if (_isIgnorableRowError(e)) return; // duplikat / tugas sudah dihapus
      if (_kindSupported && _isMissingColumn(e, 'kind')) {
        _kindSupported = false;
        await _insertOne(Map.of(row)..remove('kind'));
        return;
      }
      rethrow;
    }
  }

  /// Buat satu notifikasi. Untuk notifikasi terikat tugas, dedup berdasarkan
  /// (id_tasks, kind) — dilakukan di sisi klien, tidak butuh unique index.
  Future<void> create({
    required String idProfile,
    String? idTasks,
    required String message,
    String kind = 'info',
  }) async {
    if (idTasks != null) {
      final existing = await _existingKeys(idProfile);
      final key = _kindSupported ? '$idTasks|$kind' : '$idTasks|';
      if (existing.contains(key)) return;
    }
    await _insert([_row(idProfile, idTasks, message, kind)]);
  }

  /// Sweep: catat entri feed untuk ambang reminder yang sudah lewat
  /// **setelah tugas dibuat**. Idempoten via dedup klien.
  Future<void> sweepReminders(String idProfile, List<Task> tasks) async {
    final now = DateTime.now();
    final existing = await _existingKeys(idProfile);
    final rows = <Map<String, dynamic>>[];

    for (final t in tasks) {
      if (t.isCompleted || t.idTasks == null) continue;
      final createdAt = t.createdAt ?? now;
      for (final slot in ReminderSlot.values) {
        final fireAt = slot.fireTimeFor(t.deadline);
        if (fireAt.isAfter(now) || !fireAt.isAfter(createdAt)) continue;
        final key =
            _kindSupported ? '${t.idTasks}|${slot.kind}' : '${t.idTasks}|';
        if (existing.contains(key)) continue;
        existing.add(key); // cegah duplikat dalam batch yang sama
        rows.add(_row(idProfile, t.idTasks, reminderBody(slot, t.title),
            slot.kind));
      }
    }
    await _insert(rows);
  }

  Future<void> markAsRead(String idNotification) async {
    await _client
        .from('notifications')
        .update({'is_read': true}).eq('id_notification', idNotification);
  }

  Future<void> markAllAsRead(String idProfile) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id_profile', idProfile)
        .eq('is_read', false);
  }

  Future<void> deleteForTask(String idTasks) async {
    await _client.from('notifications').delete().eq('id_tasks', idTasks);
  }
}
