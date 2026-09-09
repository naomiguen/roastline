import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_model.dart';
import '../services/supabase_service.dart';

/// Menangani use case:
/// Melihat Daftar Tugas, Menambah Tugas Baru, Melihat Detail Tugas,
/// Menandai Tugas Selesai, Menghapus Tugas.
class TaskRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Use case: Melihat Daftar Tugas (urut berdasarkan deadline terdekat).
  Future<List<Task>> getTasks(String idProfile) async {
    final data = await _client
        .from('tasks')
        .select()
        .eq('id_profile', idProfile)
        .order('is_completed', ascending: true)
        .order('deadline', ascending: true);

    return (data as List)
        .map((e) => Task.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Use case: Melihat Detail Tugas.
  Future<Task?> getTask(String idTasks) async {
    final data =
        await _client.from('tasks').select().eq('id_tasks', idTasks).maybeSingle();
    if (data == null) return null;
    return Task.fromMap(data);
  }

  /// Use case: Menambah Tugas Baru.
  Future<Task> addTask(Task task) async {
    final data =
        await _client.from('tasks').insert(task.toInsertMap()).select().single();
    return Task.fromMap(data);
  }

  Future<Task> updateTask(Task task) async {
    final id = task.idTasks;
    if (id == null) {
      throw ArgumentError('updateTask butuh Task dengan id_tasks non-null');
    }
    final data = await _client
        .from('tasks')
        .update(task.toInsertMap())
        .eq('id_tasks', id)
        .select()
        .single();
    return Task.fromMap(data);
  }

  /// Use case: Menandai Tugas Selesai.
  Future<Task> setCompleted(String idTasks, bool value) async {
    final data = await _client
        .from('tasks')
        .update({
          'is_completed': value,
          'completed_at':
              value ? DateTime.now().toUtc().toIso8601String() : null,
        })
        .eq('id_tasks', idTasks)
        .select()
        .single();
    return Task.fromMap(data);
  }

  /// Use case: Menghapus Tugas.
  Future<void> deleteTask(String idTasks) async {
    await _client.from('tasks').delete().eq('id_tasks', idTasks);
  }
}
