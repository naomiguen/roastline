/// Merepresentasikan baris tabel `tasks` (sesuai ERD).
class Task {
  final String? idTasks;
  final String idProfile;
  final String title;
  final String course;
  final DateTime deadline;
  final String notes;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Task({
    this.idTasks,
    required this.idProfile,
    required this.title,
    required this.course,
    required this.deadline,
    this.notes = '',
    this.isCompleted = false,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.parse(v as String);
    return Task(
      idTasks: map['id_tasks'] as String?,
      idProfile: map['id_profile'] as String,
      title: (map['title'] as String?) ?? '',
      course: (map['course'] as String?) ?? '',
      deadline: DateTime.parse(map['deadline'] as String),
      notes: (map['notes'] as String?) ?? '',
      isCompleted: (map['is_completed'] as bool?) ?? false,
      completedAt: parse(map['completed_at']),
      createdAt: parse(map['created_at']),
      updatedAt: parse(map['updated_at']),
    );
  }

  /// Payload untuk insert/update (kolom yang boleh ditulis client).
  Map<String, dynamic> toInsertMap() => {
        'id_profile': idProfile,
        'title': title,
        'course': course,
        'deadline': deadline.toUtc().toIso8601String(),
        'notes': notes,
        'is_completed': isCompleted,
      };

  Task copyWith({
    String? title,
    String? course,
    DateTime? deadline,
    String? notes,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Task(
      idTasks: idTasks,
      idProfile: idProfile,
      title: title ?? this.title,
      course: course ?? this.course,
      deadline: deadline ?? this.deadline,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Perkiraan waktu tugas ditandai selesai.
  DateTime? get finishedAt => completedAt ?? (isCompleted ? updatedAt : null);

  Duration get remaining => deadline.difference(DateTime.now());
  bool get isOverdue => !isCompleted && remaining.isNegative;
}
