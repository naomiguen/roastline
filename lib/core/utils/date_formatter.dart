class DateFormatter {
  const DateFormatter._();

  static const List<String> _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const List<String> _bulanPanjang = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// Contoh: 15 Okt 2026, 23:59
  static String format(DateTime date) {
    final d = date.toLocal();
    return '${d.day} ${_bulan[d.month - 1]} ${d.year}, ${_two(d.hour)}:${_two(d.minute)}';
  }

  /// Contoh: 15 Oktober 2026
  static String tanggalPanjang(DateTime date) {
    final d = date.toLocal();
    return '${d.day} ${_bulanPanjang[d.month - 1]} ${d.year}';
  }

  /// Contoh: 15 Okt 2026
  static String tanggalPendek(DateTime date) {
    final d = date.toLocal();
    return '${d.day} ${_bulan[d.month - 1]} ${d.year}';
  }

  /// Contoh: 23:59
  static String jam(DateTime date) {
    final d = date.toLocal();
    return '${_two(d.hour)}:${_two(d.minute)}';
  }

  /// Sisa waktu menuju deadline dalam bahasa manusia.
  static String sisaWaktu(DateTime deadline) {
    final diff = deadline.toLocal().difference(DateTime.now());
    if (diff.isNegative) {
      final lewat = diff.abs();
      if (lewat.inDays > 0) return 'Telat ${lewat.inDays} hari';
      if (lewat.inHours > 0) return 'Telat ${lewat.inHours} jam';
      return 'Telat ${lewat.inMinutes} menit';
    }
    if (diff.inDays > 0) return '${diff.inDays} hari lagi';
    if (diff.inHours > 0) return '${diff.inHours} jam lagi';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lagi';
    return 'Sekarang juga!';
  }
}
