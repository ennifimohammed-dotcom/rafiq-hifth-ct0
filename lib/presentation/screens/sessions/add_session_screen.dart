import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/quran_data.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/student.dart';
import '../../providers/app_providers.dart';
import '../../widgets/surah_picker_field.dart';

/// Record a memorization or revision session in under 10 seconds:
/// everything is pre-filled from the student's current position and
/// adjusted with one-tap chips.
class AddSessionScreen extends ConsumerStatefulWidget {
  final String studentId;

  const AddSessionScreen({super.key, required this.studentId});

  @override
  ConsumerState<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends ConsumerState<AddSessionScreen> {
  SessionType _type = SessionType.memorization;
  SessionRating _rating = SessionRating.good;
  int _surah = 1;
  late final TextEditingController _ayahStartController;
  late final TextEditingController _ayahEndController;
  final _notesController = TextEditingController();
  final Set<String> _mistakes = {};
  final _customMistakeController = TextEditingController();
  bool _saving = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _ayahStartController = TextEditingController(text: '1');
    _ayahEndController = TextEditingController(text: '5');
  }

  @override
  void dispose() {
    _ayahStartController.dispose();
    _ayahEndController.dispose();
    _notesController.dispose();
    _customMistakeController.dispose();
    super.dispose();
  }

  /// Pre-fill from the student's current position: start = currentEnd + 1.
  void _prefill(Student student) {
    if (_prefilled) return;
    _prefilled = true;
    final surah = QuranData.byNumber(student.currentSurah);
    var start = student.currentAyahEnd + 1;
    var surahNumber = student.currentSurah;
    if (start > surah.ayahCount && surahNumber < 114) {
      surahNumber += 1;
      start = 1;
    }
    final maxAyah = QuranData.byNumber(surahNumber).ayahCount;
    final end = (start + 4).clamp(start, maxAyah);
    _surah = surahNumber;
    _ayahStartController.text = '$start';
    _ayahEndController.text = '$end';
  }

  void _extendEnd(int by) {
    final maxAyah = QuranData.byNumber(_surah).ayahCount;
    final current = int.tryParse(_ayahEndController.text.trim()) ?? 1;
    final updated = (current + by).clamp(1, maxAyah);
    setState(() => _ayahEndController.text = '$updated');
  }

  void _addCustomMistake() {
    final text = _customMistakeController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _mistakes.add(text);
      _customMistakeController.clear();
    });
  }

  Future<void> _save() async {
    final start = int.tryParse(_ayahStartController.text.trim());
    final end = int.tryParse(_ayahEndController.text.trim());
    final maxAyah = QuranData.byNumber(_surah).ayahCount;

    if (start == null || end == null || start < 1 || end < start) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تحقق من أرقام الآيات')),
      );
      return;
    }
    if (end > maxAyah) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('السورة تحتوي على $maxAyah آية فقط')),
      );
      return;
    }

    setState(() => _saving = true);

    final id = const Uuid().v4();
    final now = DateTime.now();
    final QuranSession session = _type == SessionType.memorization
        ? MemorizationSession(
            id: id,
            studentId: widget.studentId,
            surah: _surah,
            ayahStart: start,
            ayahEnd: end,
            rating: _rating,
            mistakes: _mistakes.toList(),
            notes: _notesController.text.trim(),
            timestamp: now,
          )
        : RevisionSession(
            id: id,
            studentId: widget.studentId,
            surah: _surah,
            ayahStart: start,
            ayahEnd: end,
            rating: _rating,
            mistakes: _mistakes.toList(),
            notes: _notesController.text.trim(),
            timestamp: now,
          );

    try {
      await ref.read(sessionRepositoryProvider).addSession(session);
      // Refresh the public parent snapshot in the background.
      // ignore: unawaited_futures
      ref.read(shareRepositoryProvider).syncPublicReport(widget.studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الجلسة ✔')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final studentAsync = ref.watch(studentProvider(widget.studentId));
    final student = studentAsync.value;
    if (student != null) _prefill(student);

    return Scaffold(
      appBar: AppBar(
        title: Text(student == null ? 'جلسة جديدة' : 'جلسة: ${student.name}'),
      ),
      body: student == null && studentAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<SessionType>(
                  segments: const [
                    ButtonSegment(
                      value: SessionType.memorization,
                      label: Text('حفظ جديد'),
                      icon: Icon(Icons.auto_stories_rounded),
                    ),
                    ButtonSegment(
                      value: SessionType.revision,
                      label: Text('مراجعة'),
                      icon: Icon(Icons.replay_rounded),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) =>
                      setState(() => _type = s.first),
                ),
                const SizedBox(height: 18),
                SurahPickerField(
                  selectedSurah: _surah,
                  onSelected: (surah) =>
                      setState(() => _surah = surah.number),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ayahStartController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'من الآية'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _ayahEndController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'إلى الآية'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ActionChip(
                      label: const Text('+5 آيات'),
                      onPressed: () => _extendEnd(5),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('+10 آيات'),
                      onPressed: () => _extendEnd(10),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'التقييم',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<SessionRating>(
                  segments: const [
                    ButtonSegment(
                      value: SessionRating.excellent,
                      label: Text('ممتاز'),
                    ),
                    ButtonSegment(
                      value: SessionRating.good,
                      label: Text('جيد'),
                    ),
                    ButtonSegment(
                      value: SessionRating.weak,
                      label: Text('ضعيف'),
                    ),
                  ],
                  selected: {_rating},
                  onSelectionChanged: (s) =>
                      setState(() => _rating = s.first),
                ),
                const SizedBox(height: 18),
                Text(
                  'الأخطاء (اختياري)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in AppConstants.mistakePresets)
                      FilterChip(
                        label: Text(preset),
                        selected: _mistakes.contains(preset),
                        onSelected: (selected) => setState(() {
                          selected
                              ? _mistakes.add(preset)
                              : _mistakes.remove(preset);
                        }),
                      ),
                    for (final custom in _mistakes.where(
                        (m) => !AppConstants.mistakePresets.contains(m)))
                      FilterChip(
                        label: Text(custom),
                        selected: true,
                        onSelected: (_) =>
                            setState(() => _mistakes.remove(custom)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customMistakeController,
                        decoration: const InputDecoration(
                          hintText: 'خطأ آخر...',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addCustomMistake(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: _addCustomMistake,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _notesController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('حفظ الجلسة'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
