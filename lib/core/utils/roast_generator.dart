import 'dart:math';

/// Menghasilkan kalimat "roast" pendek & nyelekit berdasarkan sisa waktu.
class RoastGenerator {
  const RoastGenerator._();

  static final Random _rng = Random();

  static const List<String> _telat = [
    'KAMU TELAT. LAGI. MEMALUKAN.',
    'DEADLINE LEWAT, OTAKMU KEMANA?',
    'SELAMAT, KAMU GAGAL LAGI.',
    'NGUMPULIN KAPAN? TAHUN DEPAN?',
    'MALES BANGET SIH JADI ORANG.',
  ];

  static const List<String> _kritis = [
    'KERJAKAN TUGASMU, BODOH.',
    'WAKTU HABIS, MASIH REBAHAN?',
    'PANIK? MAKANYA JANGAN NUNDA.',
    'GERAK SEKARANG, JANGAN CENGENG.',
    'MASIH SEMPET SCROLL? TOLOL.',
  ];

  static const List<String> _sedang = [
    'JANGAN BERMALAS-MALASAN, ORANG GA HAVE.',
    'MULAI SEKARANG ATAU NYESEL.',
    'NANTI NANTI TERUS, KAPAN KELARNYA?',
    'TUGAS NGGAK KELAR SENDIRI, GENIUS.',
    'CICIL SEKARANG, JANGAN GOBLOK.',
  ];

  static const List<String> _santai = [
    'MULAI DARI SEKARANG, JANGAN SOK SIBUK.',
    'SANTAI BOLEH, MALES JANGAN.',
    'WAKTU BANYAK BUKAN BUAT REBAHAN.',
    'JANGAN TUNGGU MEPET, PEMALAS.',
    'KERJAKAN DIKIT, BIAR NGGAK NANGIS NANTI.',
  ];

  /// [remaining] sisa durasi menuju deadline.
  static String forRemaining(Duration remaining) {
    if (remaining.isNegative) return _pick(_telat);
    if (remaining.inHours < 6) return _pick(_kritis);
    if (remaining.inDays < 2) return _pick(_sedang);
    return _pick(_santai);
  }

  static String _pick(List<String> list) => list[_rng.nextInt(list.length)];
}

enum DeadlineUrgency { telat, kritis, sedang, santai }

DeadlineUrgency urgencyOf(DateTime deadline) {
  final r = deadline.difference(DateTime.now());
  if (r.isNegative) return DeadlineUrgency.telat;
  if (r.inHours < 6) return DeadlineUrgency.kritis;
  if (r.inDays < 2) return DeadlineUrgency.sedang;
  return DeadlineUrgency.santai;
}
