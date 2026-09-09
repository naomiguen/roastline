import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Strip kalender mingguan yang bisa diklik.
/// "Oktober 2026" + panah ganti minggu, deret 7 hari (Sen–Min).
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
    _weekStart = anchor.subtract(Duration(days: anchor.weekday - 1));
  }

  void _shift(int weeks) {
    setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final label = '${_bulan[days[3].month - 1]} ${days[3].year}';

    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            _arrow(Icons.chevron_left, () => _shift(-1)),
            const SizedBox(width: 4),
            _arrow(Icons.chevron_right, () => _shift(1)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 7; i++)
              _DayCell(
                dow: _hari[i],
                date: days[i],
                isToday: days[i] == _today,
                isSelected: widget.selectedDay == days[i],
                hasDeadline: widget.deadlineDays.contains(days[i]),
                onTap: () {
                  final same = widget.selectedDay == days[i];
                  widget.onSelect(same ? null : days[i]);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 22, color: AppColors.textSecondary),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String dow;
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool hasDeadline;
  final VoidCallback onTap;

  const _DayCell({
    required this.dow,
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.hasDeadline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isSelected ? AppColors.maroon : Colors.transparent;
    final Color fg = isSelected
        ? Colors.white
        : (isToday ? AppColors.maroon : AppColors.textPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          Text(dow,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Container(
            width: 34,
            height: 40,
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
          const SizedBox(height: 4),
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
