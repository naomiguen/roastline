/// Merepresentasikan baris tabel `profiles` (sesuai ERD).
class Profile {
  final String idProfile;
  final String fullName;
  final String email;
  final DateTime? createdAt;

  const Profile({
    required this.idProfile,
    required this.fullName,
    required this.email,
    this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      idProfile: map['id_profile'] as String,
      fullName: (map['full_name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id_profile': idProfile,
        'full_name': fullName,
        'email': email,
      };

  Profile copyWith({String? fullName, String? email}) => Profile(
        idProfile: idProfile,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        createdAt: createdAt,
      );

  /// Inisial untuk avatar, contoh "Andi Pratama" -> "AP".
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}
