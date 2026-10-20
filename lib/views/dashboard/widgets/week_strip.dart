import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Strip kalender mingguan yang bisa diklik, bisa di-toggle ke grid bulanan.
/// "Oktober 2026" + tombol mode + panah ganti minggu/bulan, deret 7 hari (Sen–Min).
/// Hari ini diberi garis, hari terpilih diisi maroon, hari yang punya
/// deadline diberi titik.
class WeekStrip extends StatefulWidget {
  final Set<DateTime> deadlineDays;
  final DateTime? selectedDay;
  final ValueChanged<DateTime?> onSelect;

  const WeekStrip({
    super.key,
    this.deadlineDays = const {},
    this.selectedDay,
    required this.onSelect,
  });

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  late DateTime _weekStart;
  late DateTime _month; // tanggal 1 bulan yang tampil di mode bulanan
  bool _monthly = false;
  final DateTime _today = _dateOnly(DateTime.now());

  static const _bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    final anchor = widget.selectedDay ?? _today;
    _weekStart = _startOfWeek(anchor);
    _month = DateTime(anchor.year, anchor.month);
  }

  static DateTime _startOfWeek(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  void _shift(int step) {
    setState(() {
      if (_monthly) {
        _month = DateTime(_month.year, _month.month + step);
      } else {
        _weekStart = DateTime(
            _weekStart.year, _weekStart.month, _weekStart.day + 7 * step);
      }
    });
  }

  void _toggleMode() {
    setState(() {
      if (_monthly) {
        // Balik ke mingguan: minggu dari tanggal terpilih / hari ini kalau
        // masih di bulan yang sama / tanggal 1 bulan yang sedang dilihat.
        final sel = widget.selectedDay;
        final DateTime anchor;
        if (sel != null &&
            sel.year == _month.year &&
            sel.month == _month.month) {
          anchor = sel;
        } else if (_today.year == _month.year &&
            _today.month == _month.month) {
          anchor = _today;
        } else {
          anchor = _month;
        }
        _weekStart = _startOfWeek(anchor);
      } else {
        final mid = _weekStart.add(const Duration(days: 3));
        _month = DateTime(mid.year, mid.month);
      }
      _monthly = !_monthly;
    });
  }

  void _tap(DateTime day) {
    final same = widget.selectedDay == day;
    widget.onSelect(same ? null : day);
  }

  @override
  Widget build(BuildContext context) {
    final String label;
    if (_monthly) {
      label = '${_bulan[_month.month - 1]} ${_month.year}';
    } else {
      final mid = _weekStart.add(const Duration(days: 3));
      label = '${_bulan[mid.month - 1]} ${mid.year}';
    }

    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            _arrow(
              _monthly ? Icons.view_week_rounded : Icons.calendar_month_rounded,
              _toggleMode,
              size: 20,
              tooltip: _monthly ? 'Tampilan mingguan' : 'Tampilan bulanan',
            ),
            const SizedBox(width: 8),
            _arrow(Icons.chevron_left, () => _shift(-1)),
            const SizedBox(width: 4),
            _arrow(Icons.chevron_right, () => _shift(1)),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _monthly ? _buildMonth() : _buildWeek(),
        ),
      ],
    );
  }

  Widget _buildWeek() {
    final days = List.generate(
        7, (i) => DateTime(_weekStart.year, _weekStart.month, _weekStart.day + i));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          _DayCell(
            dow: _hari[i],
            date: days[i],
            isToday: days[i] == _today,
            isSelected: widget.selectedDay == days[i],
            hasDeadline: widget.deadlineDays.contains(days[i]),
            onTap: () => _tap(days[i]),
          ),
      ],
    );
  }

  Widget _buildMonth() {
    final first = _startOfWeek(_month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = _month.weekday - 1;
    final rows = ((leading + daysInMonth) / 7).ceil();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final h in _hari)
              SizedBox(
                width: 34,
                child: Text(
                  h,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var c = 0; c < 7; c++)
                  Builder(builder: (_) {
                    final d = DateTime(
                        first.year, first.month, first.day + r * 7 + c);
                    return _DayCell(
                      date: d,
                      isToday: d == _today,
                      isSelected: widget.selectedDay == d,
                      hasDeadline: widget.deadlineDays.contains(d),
                      dimmed: d.month != _month.month,
                      compact: true,
                      onTap: () => _tap(d),
                    );
                  }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap,
      {double size = 22, String? tooltip}) {
    final btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: size, color: AppColors.textSecondary),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip, child: btn);
  }
}

class _DayCell extends StatelessWidget {
  final String? dow;
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool hasDeadline;
  final bool dimmed; // tanggal di luar bulan yang tampil (mode bulanan)
  final bool compact; // sel lebih pendek untuk grid bulanan
  final VoidCallback onTap;

  const _DayCell({
    this.dow,
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.hasDeadline,
    this.dimmed = false,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isSelected ? AppColors.maroon : Colors.transparent;
    final Color fg = isSelected
        ? Colors.white
        : (isToday
            ? AppColors.maroon
            : (dimmed ? AppColors.textSecondary : AppColors.textPrimary));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          if (dow != null) ...[
            Text(dow!,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
          ],
          Container(
            width: 34,
            height: compact ? 32 : 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: (isToday && !isSelected)
                  ? Border.all(color: AppColors.maroon, width: 1.4)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight:
                    (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
                color: fg,
              ),
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasDeadline ? AppColors.maroon : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
