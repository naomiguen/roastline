import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Konfigurasi koneksi Supabase.
///
/// Urutan sumber kredensial (yang pertama ketemu dipakai):
///  1. `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
///     (atau `--dart-define-from-file=assets/env.json`)
///  2. file asset `assets/env.json` (dibaca otomatis via [loadFromAssetIfNeeded])
///  3. nilai default di bawah (placeholder -> muncul layar "belum dikonfigurasi")
class SupabaseConfig {
  const SupabaseConfig._();

  static String _url = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_REF.supabase.co',
  );

  static String _anonKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  static String get url => _url;
  static String get anonKey => _anonKey;

  static bool get isConfigured =>
      !_url.contains('YOUR_PROJECT_REF') && !_anonKey.contains('YOUR_SUPABASE');

  /// Kalau kredensial belum diisi lewat --dart-define, coba baca dari
  /// asset `assets/env.json`. Aman kalau file tidak ada (di-skip).
  static Future<void> loadFromAssetIfNeeded() async {
    if (isConfigured) return;
    try {
      final raw = await rootBundle.loadString('assets/env.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final u = (map['SUPABASE_URL'] as String?)?.trim();
      final k = (map['SUPABASE_ANON_KEY'] as String?)?.trim();
      if (u != null && u.isNotEmpty) _url = u;
      if (k != null && k.isNotEmpty) _anonKey = k;
    } catch (_) {
      // assets/env.json tidak ada / tidak valid -> biarkan pakai default.
    }
  }
}
