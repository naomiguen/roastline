import 'package:flutter/foundation.dart';

import '../data/models/profile_model.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/supabase_service.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({ProfileRepository? repository})
      : _repo = repository ?? ProfileRepository();

  final ProfileRepository _repo;

  Profile? _profile;
  bool _loading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get isLoading => _loading;
  String? get error => _error;

  /// Use case: Melihat Profil Pengguna.
  Future<void> loadProfile() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _repo.getProfile(uid);
      // Fallback jika baris profil belum ada (trigger belum jalan).
      _profile ??= Profile(
        idProfile: uid,
        fullName: SupabaseService.currentUser?.userMetadata?['full_name']
                ?.toString() ??
            '',
        email: SupabaseService.currentUser?.email ?? '',
      );
    } catch (e) {
      _error = 'Gagal memuat profil: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  bool _saving = false;
  bool get isSaving => _saving;

  /// Return true jika sukses.
  Future<bool> updateName(String fullName) async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return false;
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _repo.updateFullName(uid, fullName);
      return true;
    } catch (e) {
      _error = 'Gagal memperbarui profil: $e';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  void clear() {
    _profile = null;
    _error = null;
    notifyListeners();
  }
}
