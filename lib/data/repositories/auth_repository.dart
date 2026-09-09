import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// Menangani use case: Register, Login, Logout, Reset Kata Sandi.
class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Skema deep link untuk callback reset password (didaftarkan di
  /// AndroidManifest / Info.plist). Di web pakai default Site URL Supabase.
  static const String _resetRedirect =
      'io.supabase.roastline://login-callback/';

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  /// Use case: Register.
  /// Baris `profiles` dibuat otomatis oleh trigger `on_auth_user_created`.
  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    // Fallback bila trigger belum terpasang & user langsung ter-login.
    // Best-effort: kegagalan di sini tidak menggagalkan registrasi.
    final user = res.user;
    if (user != null && _client.auth.currentSession != null) {
      try {
        await _client.from('profiles').upsert({
          'id_profile': user.id,
          'full_name': fullName,
          'email': email,
        }, onConflict: 'id_profile');
      } catch (_) {
        // trigger handle_new_user biasanya sudah bikin baris ini.
      }
    }
    return res;
  }

  /// Use case: Login.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Use case: Logout.
  Future<void> logout() => _client.auth.signOut();

  /// Use case: Mereset Kata Sandi (kirim link ke email).
  /// Link membuka aplikasi lewat deep link -> event `passwordRecovery`.
  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : _resetRedirect,
    );
  }

  /// Ganti password untuk user yang sedang login.
  Future<void> changePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
