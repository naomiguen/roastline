import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/task_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/task_model.dart';

/// Use case: Menambah Tugas Baru / Edit Tugas.
/// Kalau [task] diisi -> mode edit.
class AddTaskPage extends StatefulWidget {
  final Task? task;
  const AddTaskPage({super.key, this.task});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _courseC = TextEditingController();
  final _notesC = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;
  String? _dateError;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    if (t != null) {
      _titleC.text = t.title;
      _courseC.text = t.course;
      _notesC.text = t.notes;
      final d = t.deadline.toLocal();
      _date = DateTime(d.year, d.month, d.day);
      _time = TimeOfDay(hour: d.hour, minute: d.minute);
    }
  }

  @override
  void dispose() {
    _titleC.dispose();
    _courseC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Mode edit boleh memilih tanggal lampau (mis. tugas sudah telat).
    final first = _isEdit && _date != null && _date!.isBefore(today)
        ? _date!
        : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();

    String? dateErr;
    if (_date == null || _time == null) {
      dateErr = 'Tanggal dan jam deadline wajib diisi';
    }
    final deadline = (_date != null && _time != null)
        ? DateTime(_date!.year, _date!.month, _date!.day,
            _time!.hour, _time!.minute)
        : null;
    // Deadline masa depan wajib untuk tugas baru; saat edit boleh dibiarkan lampau.
    final deadlineChanged =
        _isEdit && deadline != null && !deadline.isAtSameMomentAs(
            widget.task!.deadline.toLocal());
    if (dateErr == null &&
        deadline != null &&
        (!_isEdit || deadlineChanged) &&
        !deadline.isAfter(DateTime.now())) {
      dateErr = 'Deadline harus di masa depan';
    }
    setState(() => _dateError = dateErr);
    if (!formOk || dateErr != null || deadline == null) return;

    setState(() => _saving = true);
    final taskC = context.read<TaskController>();
    final bool ok;
    if (_isEdit) {
      ok = await taskC.updateTask(
        original: widget.task!,
        title: _titleC.text.trim(),
        course: _courseC.text.trim(),
        deadline: deadline,
        notes: _notesC.text.trim(),
      );
    } else {
      ok = await taskC.addTask(
        title: _titleC.text.trim(),
        course: _courseC.text.trim(),
        deadline: deadline,
        notes: _notesC.text.trim(),
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(taskC.error ?? 'Gagal menyimpan tugas')),
      );
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      );

  Widget _pickerBox({
    required String value,
    required bool filled,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: filled
                      ? AppColors.textPrimary
                      : const Color(0xFF9E9E9E),
                ),
              ),
            ),
            Icon(icon, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Tugas' : 'Tambah Tugas Baru'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('Nama Tugas'),
            TextFormField(
              controller: _titleC,
              decoration: const InputDecoration(
                hintText: 'Contoh: Makalah Pancasila',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama tugas wajib diisi'
                  : null,
            ),
            const SizedBox(height: 20),
            _label('Mata Kuliah'),
            TextFormField(
              controller: _courseC,
              decoration: const InputDecoration(
                hintText: 'Contoh: Pendidikan Kewarganegaraan',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Mata kuliah wajib diisi'
                  : null,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Tanggal Deadline'),
                      _pickerBox(
                        value: _date == null
                            ? 'Pilih tanggal'
                            : DateFormatter.tanggalPendek(_date!),
                        filled: _date != null,
                        icon: Icons.calendar_today_outlined,
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Jam Deadline'),
                      _pickerBox(
                        value: _time == null
                            ? 'Pilih jam'
                            : _time!.format(context),
                        filled: _time != null,
                        icon: Icons.access_time,
                        onTap: _pickTime,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_dateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _dateError!,
                  style: const TextStyle(
                      color: AppColors.danger, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            _label('Catatan Tambahan'),
            TextFormField(
              controller: _notesC,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Tulis detail tugas, referensi, atau keluh kesahmu di sini...',
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.roastBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.roastBorder),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_fire_department,
                      color: AppColors.maroon, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ISI YANG BENER, JANGAN ASAL. TUGAS INI NENTUIN NILAIMU.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.maroon,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Tugas'),
            ),
          ],
        ),
      ),
    );
  }
}
