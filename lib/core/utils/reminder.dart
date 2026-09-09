import 'dart:math';

/// Titik-titik pengingat menuju deadline + teks roast-nya.
enum ReminderSlot { h24, h6, h1, due, overdue }

extension ReminderSlotX on ReminderSlot {
  /// Kunci unik di tabel `notifications` (kolom `kind`).
  String get kind => switch (this) {
        ReminderSlot.h24 => 'reminder_24h',
        ReminderSlot.h6 => 'reminder_6h',
        ReminderSlot.h1 => 'reminder_1h',
        ReminderSlot.due => 'due',
        ReminderSlot.overdue => 'overdue',
      };

  /// Selisih sebelum deadline. `overdue` bernilai negatif (setelah deadline).
  Duration get offset => switch (this) {
        ReminderSlot.h24 => const Duration(hours: 24),
        ReminderSlot.h6 => const Duration(hours: 6),
        ReminderSlot.h1 => const Duration(hours: 1),
        ReminderSlot.due => Duration.zero,
        ReminderSlot.overdue => const Duration(minutes: -1),
      };

  /// Waktu notifikasi ini seharusnya tampil untuk [deadline] tertentu.
  DateTime fireTimeFor(DateTime deadline) => deadline.subtract(offset);

  String get title => switch (this) {
        ReminderSlot.h24 => 'Deadline tinggal 1 hari',
        ReminderSlot.h6 => 'Deadline 6 jam lagi',
        ReminderSlot.h1 => '1 JAM LAGI',
        ReminderSlot.due => 'Waktunya habis',
        ReminderSlot.overdue => 'Kamu telat ngumpulin',
      };

  /// Semua slot (termasuk `overdue`) dijadwalkan ke OS sebagai push.
  bool get isScheduled => true;
}

final _rng = Random();

String reminderBody(ReminderSlot slot, String taskTitle) {
  final lists = switch (slot) {
    ReminderSlot.h24 => [
        '"$taskTitle" besok. JANGAN SOK SANTAI.',
        '"$taskTitle" tinggal sehari. MULAI SEKARANG, PEMALAS.',
      ],
    ReminderSlot.h6 => [
        '"$taskTitle" 6 jam lagi. MASIH BISA MALES?',
        '6 JAM buat "$taskTitle". TUTUP HP-NYA, KERJAKAN.',
      ],
    ReminderSlot.h1 => [
        '1 JAM. "$taskTitle". KERJAKAN, BODOH.',
        '"$taskTitle" 60 menit lagi. GERAK ATAU MERANA.',
      ],
    ReminderSlot.due => [
        'WAKTU HABIS. "$taskTitle". NGUMPULIN SANA.',
        '"$taskTitle" DEADLINE SEKARANG. SUBMIT ATAU NANGIS?',
      ],
    ReminderSlot.overdue => [
        '"$taskTitle" TELAT. MEMALUKAN. CEPETAN.',
        'TELAT NGUMPULIN "$taskTitle". MALES BANGET SIH.',
      ],
  };
  return lists[_rng.nextInt(lists.length)];
}
