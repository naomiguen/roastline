import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/reminder.dart';
import '../models/task_model.dart';

/// Notifikasi lokal terjadwal (reminder deadline). Tidak butuh Firebase.
///
/// Semua metode aman dipanggil di web / platform tanpa dukungan
/// (otomatis no-op).
class NotificationService {
  const NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _ready = false;
  static bool get isReady => _ready;
  static bool get _supported => !kIsWeb;

  /// Diisi saat user menge-tap notifikasi (payload `task:ID` atau lainnya).
  /// UI mendengarkan ini untuk membuka halaman Notifikasi.
  static final ValueNotifier<String?> tappedPayload =
      ValueNotifier<String?>(null);

  @pragma('vm:entry-point')
  static void _onTapBackground(NotificationResponse r) {
    tappedPayload.value = r.payload;
  }

  static const String _channelId = 'roastline_reminders';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    'Pengingat Deadline',
    description: 'Pengingat tugas Julidline menjelang deadline',
    importance: Importance.max,
  );

  /// Detail notifikasi dengan teks panjang yang bisa di-expand di shade.
  static NotificationDetails _detailsFor(String body) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Pengingat Deadline',
          channelDescription: 'Pengingat tugas Julidline menjelang deadline',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      );

  static AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  static Future<void> init() async {
    if (!_supported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      // Reminder dijadwalkan pakai instan absolut (UTC) sehingga tidak
      // bergantung nama zona waktu device.

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (r) => tappedPayload.value = r.payload,
        onDidReceiveBackgroundNotificationResponse: _onTapBackground,
      );
      await _android?.createNotificationChannel(_channel);

      // Kalau app dibuka dari tap notifikasi saat masih terminated.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        tappedPayload.value = launch!.notificationResponse?.payload;
      }
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService.init gagal: $e');
    }
  }

  /// Minta izin: notifikasi (Android 13+/iOS) + exact alarm (Android 12+).
  /// Return true kalau notifikasi diizinkan.
  static Future<bool> requestPermissions() async {
    if (!_supported) return false;
    try {
      final granted = await _android?.requestNotificationsPermission();
      await _android?.requestExactAlarmsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? true;
    } catch (e) {
      debugPrint('requestPermissions gagal: $e');
      return false;
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    if (!_supported) return false;
    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// true kalau OS mengizinkan alarm presisi (notifikasi tepat waktu).
  /// Kalau false, notifikasi terjadwal bisa telat 10–60 detik.
  static Future<bool> canScheduleExact() async {
    if (!_supported) return false;
    try {
      return await _android?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return false;
    }
  }

  /// ID notifikasi deterministik per (tugas, slot) supaya bisa di-cancel.
  /// Dijaga tetap di dalam rentang int 32-bit Android (< 2^31).
  static int _notifId(String taskId, ReminderSlot slot) {
    final base = taskId.hashCode & 0x03FFFFFF; // maks ~67 juta
    return base * 8 + slot.index; // 5 slot -> aman
  }

  static Future<void> _schedule(
    int id,
    String title,
    String body,
    DateTime whenLocal, {
    String? payload,
  }) async {
    final when = tz.TZDateTime.from(whenLocal.toUtc(), tz.UTC);
    final details = _detailsFor(body);
    try {
      await _plugin.zonedSchedule(
        id, title, body, when, details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Izin exact alarm ditolak -> mode longgar (bisa telat beberapa menit).
      await _plugin.zonedSchedule(
        id, title, body, when, details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Jadwalkan ulang seluruh reminder untuk satu tugas.
  static Future<void> scheduleForTask(Task task) async {
    if (!_supported || !_ready || task.idTasks == null) return;
    await cancelForTask(task.idTasks!);
    if (task.isCompleted) return;

    final now = DateTime.now();
    for (final slot in ReminderSlot.values) {
      if (!slot.isScheduled) continue;
      final fireAt = slot.fireTimeFor(task.deadline);
      if (fireAt.isBefore(now)) continue;
      try {
        await _schedule(
          _notifId(task.idTasks!, slot),
          slot.title,
          reminderBody(slot, task.title),
          fireAt,
          payload: 'task:${task.idTasks}',
        );
      } catch (e) {
        debugPrint('scheduleForTask gagal ($slot): $e');
      }
    }
  }

  static Future<void> cancelForTask(String taskId) async {
    if (!_supported || !_ready) return;
    for (final slot in ReminderSlot.values) {
      try {
        await _plugin.cancel(_notifId(taskId, slot));
      } catch (_) {}
    }
  }

  static Future<void> cancelAll() async {
    if (!_supported || !_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Tampilkan notifikasi untuk satu slot tugas SEKARANG, memakai id yang
  /// sama dengan versi terjadwalnya — jadi kalau alarm OS-nya sudah/akan
  /// tampil, ini meng-update, bukan menduplikasi.
  static Future<void> showForSlot(
    String taskId,
    ReminderSlot slot,
    String title,
    String body,
  ) async {
    if (!_supported || !_ready) return;
    final id = _notifId(taskId, slot);
    try {
      await _plugin.cancel(id);
      await _plugin.show(id, title, body, _detailsFor(body),
          payload: 'task:$taskId');
    } catch (e) {
      debugPrint('showForSlot gagal: $e');
    }
  }

  /// Tampilkan notifikasi langsung (untuk pesan FCM foreground / tes).
  static Future<void> showNow({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_supported || !_ready) return;
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
        title,
        body,
        _detailsFor(body),
        payload: payload,
      );
    } catch (e) {
      debugPrint('showNow gagal: $e');
    }
  }

  /// Dipakai tombol "Tes Notifikasi": 1 notif sekarang + 1 terjadwal 10 detik.
  /// Return pesan status untuk ditampilkan ke user.
  static Future<String> sendTest() async {
    if (!_supported) {
      return 'Notifikasi sistem tidak didukung di platform ini (web/desktop). '
          'Pakai emulator/HP Android.';
    }
    if (!_ready) {
      return 'Layanan notifikasi belum siap. Restart aplikasi.';
    }
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      await requestPermissions();
    }
    await showNow(
      title: 'Tes Julidline',
      body: 'Kalau kamu lihat ini, notifikasi langsung berfungsi.',
    );
    try {
      await _schedule(
        999001,
        'Tes Terjadwal (10 detik)',
        'Notifikasi terjadwal berfungsi. Deadline reminder juga bakal jalan.',
        DateTime.now().add(const Duration(seconds: 10)),
      );
    } catch (e) {
      return 'Notifikasi langsung terkirim, tapi yang terjadwal gagal: $e';
    }
    final pending = await _plugin.pendingNotificationRequests();
    final exact = await canScheduleExact();

    if (!enabled) {
      return 'Izin notifikasi belum aktif. Aktifkan di Setelan aplikasi, '
          'lalu coba lagi.';
    }
    if (!exact) {
      return 'Terkirim, tapi izin "Alarm & pengingat" BELUM aktif → notifikasi '
          'terjadwal bisa telat 10–60 detik. Aktifkan di Setelan → Aplikasi → '
          'Julidline → Alarm & pengingat. (${pending.length} di antrian)';
    }
    return 'Terkirim. Alarm presisi aktif ✔ Tunggu ~10 detik untuk notif '
        'terjadwal. (${pending.length} notif dalam antrian)';
  }
}
