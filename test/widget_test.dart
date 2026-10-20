import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roastline/core/utils/reminder.dart';
import 'package:roastline/core/utils/roast_generator.dart';

void main() {
  test('urgencyOf mengklasifikasikan sisa waktu dengan benar', () {
    final now = DateTime.now();
    expect(urgencyOf(now.subtract(const Duration(hours: 1))),
        DeadlineUrgency.telat);
    expect(urgencyOf(now.add(const Duration(hours: 2))),
        DeadlineUrgency.kritis);
    expect(urgencyOf(now.add(const Duration(hours: 30))),
        DeadlineUrgency.sedang);
    expect(urgencyOf(now.add(const Duration(days: 5))),
        DeadlineUrgency.santai);
  });

  test('RoastGenerator selalu menghasilkan teks non-kosong', () {
    for (final d in [
      const Duration(hours: -3),
      const Duration(hours: 2),
      const Duration(hours: 20),
      const Duration(days: 4),
    ]) {
      expect(RoastGenerator.forRemaining(d), isNotEmpty);
    }
  });

  group('ReminderSlot', () {
    final deadline = DateTime(2026, 10, 15, 23, 59);

    test('fireTimeFor menghitung ambang yang benar', () {
      expect(ReminderSlot.h24.fireTimeFor(deadline),
          deadline.subtract(const Duration(hours: 24)));
      expect(ReminderSlot.h6.fireTimeFor(deadline),
          deadline.subtract(const Duration(hours: 6)));
      expect(ReminderSlot.h1.fireTimeFor(deadline),
          deadline.subtract(const Duration(hours: 1)));
      expect(ReminderSlot.due.fireTimeFor(deadline), deadline);
      expect(ReminderSlot.overdue.fireTimeFor(deadline),
          deadline.add(const Duration(minutes: 1)));
    });

    test('kind unik per slot & semua slot dijadwalkan ke OS', () {
      final kinds = ReminderSlot.values.map((s) => s.kind).toSet();
      expect(kinds.length, ReminderSlot.values.length);
      for (final s in ReminderSlot.values) {
        expect(s.isScheduled, isTrue);
      }
    });

    test('overdue fire-time berada setelah deadline', () {
      final d = DateTime(2026, 10, 15, 23, 59);
      expect(ReminderSlot.overdue.fireTimeFor(d).isAfter(d), isTrue);
      expect(ReminderSlot.due.fireTimeFor(d), d);
    });

    test('reminderBody selalu memuat judul tugas', () {
      for (final s in ReminderSlot.values) {
        expect(reminderBody(s, 'Laporan Fisika'), contains('Laporan Fisika'));
      }
    });
  });

  testWidgets('smoke: MaterialApp bisa dirender', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Julidline'))),
    );
    expect(find.text('Julidline'), findsOneWidget);
  });
}
