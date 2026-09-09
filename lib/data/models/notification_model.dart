/// Merepresentasikan baris tabel `notifications` (sesuai ERD).
class AppNotification {
  final String idNotification;
  final String idProfile;
  final String? idTasks;
  final String message;
  final String kind;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.idNotification,
    required this.idProfile,
    this.idTasks,
    required this.message,
    this.kind = 'info',
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      idNotification: map['id_notification'] as String,
      idProfile: map['id_profile'] as String,
      idTasks: map['id_tasks'] as String?,
      message: (map['message'] as String?) ?? '',
      kind: (map['kind'] as String?) ?? 'info',
      isRead: (map['is_read'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        idNotification: idNotification,
        idProfile: idProfile,
        idTasks: idTasks,
        message: message,
        kind: kind,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
