import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../repositories/notification_repository.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

/// Handler pesan FCM saat aplikasi di background / terminated.
/// Wajib berupa top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background: ${message.messageId} - ${message.notification?.title}');
}

/// Notifikasi push berbasis Firebase Cloud Messaging.
///
/// Aman dipanggil walau Firebase belum dikonfigurasi: semua error di-catch
/// sehingga aplikasi tetap berjalan (push sekadar nonaktif). Lihat SETUP.md.
class FcmService {
  const FcmService._();

  static String? token;
  static bool ready = false;

  static final ValueNotifier<RemoteMessage?> lastForegroundMessage =
      ValueNotifier<RemoteMessage?>(null);

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      token = await messaging.getToken();
      debugPrint('FCM token: $token');
      FirebaseMessaging.instance.onTokenRefresh.listen((t) => token = t);

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      ready = true;
    } catch (e) {
      debugPrint('FcmService: Firebase belum dikonfigurasi -> $e');
      ready = false;
    }
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    lastForegroundMessage.value = message;
    final n = message.notification;
    final title = n?.title ?? 'RoastLine';
    final body = n?.body ?? message.data['body']?.toString() ?? 'Pesan baru';
    debugPrint('FCM foreground: $title - $body');

    // Tampilkan sebagai notifikasi lokal + catat ke feed dalam app.
    await NotificationService.showNow(
      title: title,
      body: body,
      payload: 'push',
    );
    final uid = SupabaseService.currentUserId;
    if (uid != null) {
      try {
        await NotificationRepository().create(
          idProfile: uid,
          message: body,
          kind: 'push',
        );
      } catch (_) {}
    }
  }
}
