import 'package:flutter_test/flutter_test.dart';
import 'package:roastline/controllers/task_controller.dart';
import 'package:roastline/data/models/notification_model.dart';
import 'package:roastline/data/models/task_model.dart';
import 'package:roastline/data/repositories/notification_repository.dart';
import 'package:roastline/data/repositories/task_repository.dart';

class _FakeTaskRepo extends TaskRepository {
  final List<Task> store;
  bool failNext = false;
  _FakeTaskRepo([List<Task>? seed]) : store = seed ?? [];

  void _maybeFail() {
    if (failNext) {
      failNext = false;
      throw Exception('boom');
    }
  }

  @override
  Future<List<Task>> getTasks(String idProfile) async => List.of(store);

  @override
  Future<Task> addTask(Task task) async {
    _maybeFail();
    final created = Task(
      idTasks: 'id-${store.length}',
      idProfile: task.idProfile,
      title: task.title,
      course: task.course,
      deadline: task.deadline,
      notes: task.notes,
      createdAt: DateTime.now(),
    );
    store.add(created);
    return created;
  }

  @override
  Future<Task> setCompleted(String idTasks, bool value) async {
    _maybeFail();
    final i = store.indexWhere((t) => t.idTasks == idTasks);
    store[i] = store[i].copyWith(isCompleted: value);
    return store[i];
  }

  @override
  Future<void> deleteTask(String idTasks) async {
    _maybeFail();
    store.removeWhere((t) => t.idTasks == idTasks);
  }

  @override
  Future<Task> updateTask(Task task) async {
    _maybeFail();
    final i = store.indexWhere((t) => t.idTasks == task.idTasks);
    store[i] = task;
    return task;
  }
}

class _FakeNotifRepo extends NotificationRepository {
  @override
  Future<void> create({
    required String idProfile,
    String? idTasks,
    required String message,
    String kind = 'info',
  }) async {}

  @override
  Future<void> sweepReminders(String idProfile, List<Task> tasks) async {}

  @override
  Future<List<AppNotification>> getNotifications(String idProfile) async => [];
}

Task _task({
  String? id,
  String title = 'Tugas',
  bool done = false,
  Duration inFuture = const Duration(days: 1),
}) {
  return Task(
    idTasks: id,
    idProfile: 'u1',
    title: title,
    course: 'MK',
    deadline: DateTime.now().add(inFuture),
    isCompleted: done,
    createdAt: DateTime.now(),
  );
}

void main() {
  late _FakeTaskRepo repo;
  late TaskController c;

  TaskController build() => TaskController(
        taskRepository: repo,
        notificationRepository: _FakeNotifRepo(),
        currentUserId: () => 'u1',
        enableTicker: false,
      );

  setUp(() {
    repo = _FakeTaskRepo();
    c = build();
    addTearDown(c.dispose);
  });

  test('loadTasks mengisi daftar dari repository', () async {
    repo.store.addAll([_task(id: 'a'), _task(id: 'b')]);
    await c.loadTasks();
    expect(c.tasks.length, 2);
    expect(c.isLoading, isFalse);
  });

  test('addTask menambah tugas & upcoming bertambah', () async {
    final ok = await c.addTask(
      title: 'Laporan',
      course: 'Fisika',
      deadline: DateTime.now().add(const Duration(hours: 5)),
    );
    expect(ok, isTrue);
    expect(c.tasks.single.title, 'Laporan');
    expect(c.upcoming.length, 1);
  });

  test('addTask gagal -> return false & error terisi', () async {
    repo.failNext = true;
    final ok = await c.addTask(
      title: 'X',
      course: 'Y',
      deadline: DateTime.now().add(const Duration(hours: 1)),
    );
    expect(ok, isFalse);
    expect(c.error, isNotNull);
    expect(c.tasks, isEmpty);
  });

  test('toggleCompleted membalik status & memindah ke completed', () async {
    repo.store.add(_task(id: 'a'));
    await c.loadTasks();
    await c.toggleCompleted(c.tasks.first);
    expect(c.completed.length, 1);
    expect(c.upcoming, isEmpty);
  });

  test('toggleCompleted rollback saat repo error', () async {
    repo.store.add(_task(id: 'a'));
    await c.loadTasks();
    repo.failNext = true;
    await c.toggleCompleted(c.tasks.first);
    expect(c.tasks.first.isCompleted, isFalse); // kembali seperti semula
    expect(c.error, isNotNull);
  });

  test('deleteTask menghapus; rollback saat gagal', () async {
    repo.store.addAll([_task(id: 'a'), _task(id: 'b')]);
    await c.loadTasks();

    await c.deleteTask(c.tasks.firstWhere((t) => t.idTasks == 'a'));
    expect(c.tasks.map((t) => t.idTasks), ['b']);

    repo.failNext = true;
    await c.deleteTask(c.tasks.first);
    expect(c.tasks.length, 1); // gagal -> tidak jadi terhapus
  });

  test('updateTask mengubah field tugas', () async {
    repo.store.add(_task(id: 'a', title: 'Lama'));
    await c.loadTasks();
    final ok = await c.updateTask(
      original: c.tasks.first,
      title: 'Baru',
      course: 'MK2',
      deadline: DateTime.now().add(const Duration(days: 3)),
      notes: 'catatan',
    );
    expect(ok, isTrue);
    expect(c.tasks.first.title, 'Baru');
    expect(c.tasks.first.course, 'MK2');
  });

  test('byId mengembalikan tugas yang cocok / null', () async {
    repo.store.add(_task(id: 'a'));
    await c.loadTasks();
    expect(c.byId('a')?.idTasks, 'a');
    expect(c.byId('zzz'), isNull);
  });
}
