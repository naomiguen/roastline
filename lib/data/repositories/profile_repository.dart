import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';
import '../services/supabase_service.dart';

/// Menangani use case: Melihat Profil Pengguna.
class ProfileRepository {
  SupabaseClient get _client => SupabaseService.client;

  Future<Profile?> getProfile(String idProfile) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id_profile', idProfile)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromMap(data);
  }

  Future<Profile> updateFullName(String idProfile, String fullName) async {
    final data = await _client
        .from('profiles')
        .update({'full_name': fullName})
        .eq('id_profile', idProfile)
        .select()
        .single();
    return Profile.fromMap(data);
  }
}
