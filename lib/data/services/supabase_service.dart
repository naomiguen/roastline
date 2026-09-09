import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Wrapper tipis untuk inisialisasi & akses global client Supabase.
class SupabaseService {
  const SupabaseService._();

  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // "anon key" pada dashboard Supabase (Project Settings > API).
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  /// Aman dipanggil sebelum `init()` (mis. di test) -> null, tidak melempar.
  static User? get currentUser {
    try {
      return auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static String? get currentUserId => currentUser?.id;

  static bool get isLoggedIn => currentUser != null;
}
