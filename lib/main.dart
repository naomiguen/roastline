import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'controllers/auth_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/task_controller.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/app_colors.dart';
import 'data/services/fcm_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kredensial dari --dart-define, atau fallback ke assets/env.json.
  await SupabaseConfig.loadFromAssetIfNeeded();

  if (!SupabaseConfig.isConfigured) {
    runApp(const _ConfigMissingApp());
    return;
  }

  try {
    await SupabaseService.init();
  } catch (e) {
    runApp(_InitErrorApp(message: '$e'));
    return;
  }

  // Tidak fatal kalau gagal — aplikasi tetap jalan tanpa notifikasi OS/push.
  await NotificationService.init();
  await FcmService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(
          create: (context) => TaskController(
            notificationController: context.read<NotificationController>(),
          ),
        ),
      ],
      child: const RoastLineApp(),
    ),
  );
}

/// Ditampilkan kalau `Supabase.initialize` gagal (URL/anon key salah,
/// tidak ada koneksi, dsb) — supaya tidak layar abu-abu tanpa info.
class _InitErrorApp extends StatelessWidget {
  final String message;
  const _InitErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: AppColors.maroon),
              const SizedBox(height: 16),
              const Text(
                'Gagal terhubung ke Supabase',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cek SUPABASE_URL & SUPABASE_ANON_KEY di assets/env.json, '
                'dan pastikan ada koneksi internet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ditampilkan bila kredensial Supabase belum diisi (lihat SETUP.md).
class _ConfigMissingApp extends StatelessWidget {
  const _ConfigMissingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: const Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings_suggest_outlined,
                  size: 64, color: AppColors.maroon),
              SizedBox(height: 16),
              Text(
                'Kredensial Supabase belum diisi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Isi assets/env.json (SUPABASE_URL & SUPABASE_ANON_KEY), '
                'atau jalankan dengan --dart-define-from-file=assets/env.json.\n'
                'Detail ada di SETUP.md.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
