import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/quran_data.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/student.dart';
import '../../providers/app_providers.dart';
import '../../widgets/surah_picker_field.dart';

class AddSessionScreen extends ConsumerStatefulWidget {
  final String studentId;
  const AddSessionScreen({super.key, required this.studentId});

  @override
  ConsumerState<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends ConsumerState<AddSessionScreen> {
  // ── Common state ───────────────────────────────────────────────────────────
  SessionType    _type          = SessionType.memorization;
  SessionRating  _rating        = SessionRating.good;
  TrackingMode   _trackingMode  = TrackingMode.surahAyah;
  DateTime       _sessionDate   = DateTime.now();
  final _notesController        = TextEditingController();
  final Set<String> _mistakes   = {};
  final _customMistakeCtrl      = TextEditingController();
  bool _saving                  = false;
  bool _prefilled               = false;

  // ── Surah/Ayah state ───────────────────────────────────────────────────────
  int _surah = 1;
  late final TextEditingController _ayahStartCtrl;
  late final TextEditingController _ayahEndCtrl;

  // ── Hizb/Eighth state (1-60 / 1-8) ────────────────────────────────────────
  int _startHizb   = 1;
  int _startEighth = 1;
  int _endHizb     = 1;
  int _endEighth   = 1;

  @override
  void initState() {
    super.initState();
    _ayahStartCtrl = TextEditingController(text: '1');
    _ayahEndCtrl   = TextEditingController(text: '5');
  }

  @override
  void dispose() {
    _ayahStartCtrl.dispose();
    _ayahEndCtrl.dispose();
    _notesController.dispose();
    _customMistakeCtrl.dispose();
    super.dispose();
  }

  void _prefill(Student student) {
    if (_prefilled) return;
    _prefilled = true;
    final surah = QuranData.byNumber(student.currentSurah);
    var start       = student.currentAyahEnd + 1;
    var surahNumber = student.currentSurah;
    if (start > surah.ayahCount && surahNumber < 114) {
      surahNumber += 1;
      start = 1;
    }
    final maxAyah = QuranData.byNumber(surahNumber).ayahCount;
    _surah                = surahNumber;
    _ayahStartCtrl.text  = '$start';
    _ayahEndCtrl.text    = '${(start + 4).clamp(start, maxAyah)}';
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'اختر تاريخ الجلسة',
    );
    if (picked != null) setState(() => _sessionDate = picked);
  }

  void _extendEnd(int by) {
    final maxAyah = QuranData.byNumber(_surah).ayahCount;
    final current = int.tryParse(_ayahEndCtrl.text.trim()) ?? 1;
    setState(() =>
        _ayahEndCtrl.text = '${(current + by).clamp(1, maxAyah)}');
  }

  void _addCustomMistake() {
    final text = _customMistakeCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _mistakes.add(text);
      _customMistakeCtrl.clear();
    });
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  String? _validateSurahAyah() {
    final start = int.tryParse(_ayahStartCtrl.text.trim());
    final end   = int.tryParse(_ayahEndCtrl.text.trim());
    final max   = QuranData.byNumber(_surah).ayahCount;
    if (start == null || end == null || start < 1 || end < start) {
      return 'تحقق من أرقام الآيات';
    }
    if (end > max) return 'السورة تحتوي $max آية فقط';
    return null;
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_trackingMode == TrackingMode.surahAyah) {
      final err = _validateSurahAyah();
      if (err != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    }
    setState(() => _saving = true);

    final now  = DateTime.now();
    final id   = const Uuid().v4();
    final start = _trackingMode == TrackingMode.surahAyah
        ? int.parse(_ayahStartCtrl.text.trim())
        : 0;
    final end = _trackingMode == TrackingMode.surahAyah
        ? int.parse(_ayahEndCtrl.text.trim())
        : 0;

    final QuranSession session = _type == SessionType.memorization
        ? MemorizationSession(
            id:           id,
            studentId:    widget.studentId,
            rating:       _rating,
            mistakes:     _mistakes.toList(),
            notes:        _notesController.text.trim(),
            timestamp:    now,
            sessionDate:  _sessionDate,
            trackingMode: _trackingMode,
            surah:        _trackingMode == TrackingMode.surahAyah ? _surah : 0,
            ayahStart:    start,
            ayahEnd:      end,
            startHizb:    _trackingMode == TrackingMode.hizbEighth ? _startHizb   : null,
            startEighth:  _trackingMode == TrackingMode.hizbEighth ? _startEighth : null,
            endHizb:      _trackingMode == TrackingMode.hizbEighth ? _endHizb     : null,
            endEighth:    _trackingMode == TrackingMode.hizbEighth ? _endEighth   : null,
          )
        : RevisionSession(
            id:           id,
            studentId:    widget.studentId,
            rating:       _rating,
            mistakes:     _mistakes.toList(),
            notes:        _notesController.text.trim(),
            timestamp:    now,
            sessionDate:  _sessionDate,
            trackingMode: _trackingMode,
            surah:        _trackingMode == TrackingMode.surahAyah ? _surah : 0,
            ayahStart:    start,
            ayahEnd:      end,
            startHizb:    _trackingMode == TrackingMode.hizbEighth ? _startHizb   : null,
            startEighth:  _trackingMode == TrackingMode.hizbEighth ? _startEighth : null,
            endHizb:      _trackingMode == TrackingMode.hizbEighth ? _endHizb     : null,
            endEighth:    _trackingMode == TrackingMode.hizbEighth ? _endEighth   : null,
          );

    try {
      await ref.read(sessionRepositoryProvider).addSession(session);
      // ignore: unawaited_futures
      ref.read(shareRepositoryProvider).syncPublicReport(widget.studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ الجلسة ✔')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme       = Theme.of(context).colorScheme;
    final studentAsync = ref.watch(studentProvider(widget.studentId));
    final student      = studentAsync.value;
    if (student != null) _prefill(student);

    return Scaffold(
      appBar: AppBar(
        title: Text(student == null
            ? 'جلسة جديدة'
            : 'جلسة: ${student.name}'),
      ),
      body: student == null && studentAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── نوع الجلسة ──────────────────────────────────────
                SegmentedButton<SessionType>(
                  segments: const [
                    ButtonSegment(
                        value: SessionType.memorization,
                        label: Text('حفظ جديد'),
                        icon: Icon(Icons.auto_stories_rounded)),
                    ButtonSegment(
                        value: SessionType.revision,
                        label: Text('مراجعة'),
                        icon: Icon(Icons.replay_rounded)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) =>
                      setState(() => _type = s.first),
                ),
                const SizedBox(height: 14),

                // ── تاريخ الجلسة ─────────────────────────────────────
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 20, color: scheme.primary),
                      const SizedBox(width: 10),
                      Text('تاريخ الجلسة:  ',
                          style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 14)),
                      Text(Formatters.date(_sessionDate),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: scheme.onSurface)),
                      const Spacer(),
                      Icon(Icons.edit_calendar_rounded,
                          size: 18,
                          color: scheme.onSurfaceVariant),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // ── طريقة المتابعة ───────────────────────────────────
                SegmentedButton<TrackingMode>(
                  segments: const [
                    ButtonSegment(
                        value: TrackingMode.surahAyah,
                        label: Text('سورة وآيات'),
                        icon: Icon(Icons.format_list_numbered_rounded)),
                    ButtonSegment(
                        value: TrackingMode.hizbEighth,
                        label: Text('حزب وثمن'),
                        icon: Icon(Icons.grid_view_rounded)),
                  ],
                  selected: {_trackingMode},
                  onSelectionChanged: (s) =>
                      setState(() => _trackingMode = s.first),
                ),
                const SizedBox(height: 16),

                // ── قسم السورة والآيات ────────────────────────────────
                if (_trackingMode == TrackingMode.surahAyah) ...[
                  SurahPickerField(
                    selectedSurah: _surah,
                    onSelected: (s) =>
                        setState(() => _surah = s.number),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _ayahStartCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'من الآية'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _ayahEndCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'إلى الآية'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    ActionChip(
                        label: const Text('+5 آيات'),
                        onPressed: () => _extendEnd(5)),
                    const SizedBox(width: 8),
                    ActionChip(
                        label: const Text('+10 آيات'),
                        onPressed: () => _extendEnd(10)),
                  ]),
                ],

                // ── قسم الحزب والثمن ──────────────────────────────────
                if (_trackingMode == TrackingMode.hizbEighth) ...[
                  _HizbSection(
                    title: 'البداية',
                    hizb:    _startHizb,
                    eighth:  _startEighth,
                    onHizb:   (v) => setState(() => _startHizb = v),
                    onEighth: (v) => setState(() => _startEighth = v),
                  ),
                  const SizedBox(height: 12),
                  _HizbSection(
                    title: 'النهاية',
                    hizb:    _endHizb,
                    eighth:  _endEighth,
                    onHizb:   (v) => setState(() => _endHizb = v),
                    onEighth: (v) => setState(() => _endEighth = v),
                  ),
                ],

                const SizedBox(height: 18),

                // ── التقييم ──────────────────────────────────────────
                Text('التقييم',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                SegmentedButton<SessionRating>(
                  segments: const [
                    ButtonSegment(
                        value: SessionRating.excellent,
                        label: Text('ممتاز')),
                    ButtonSegment(
                        value: SessionRating.good,
                        label: Text('جيد')),
                    ButtonSegment(
                        value: SessionRating.weak,
                        label: Text('ضعيف')),
                  ],
                  selected: {_rating},
                  onSelectionChanged: (s) =>
                      setState(() => _rating = s.first),
                ),
                const SizedBox(height: 18),

                // ── الأخطاء ──────────────────────────────────────────
                Text('الأخطاء (اختياري)',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in AppConstants.mistakePresets)
                      FilterChip(
                        label: Text(p),
                        selected: _mistakes.contains(p),
                        onSelected: (v) => setState(() =>
                            v ? _mistakes.add(p) : _mistakes.remove(p)),
                      ),
                    for (final c in _mistakes.where(
                        (m) => !AppConstants.mistakePresets.contains(m)))
                      FilterChip(
                        label: Text(c),
                        selected: true,
                        onSelected: (_) =>
                            setState(() => _mistakes.remove(c)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _customMistakeCtrl,
                      decoration: const InputDecoration(
                          hintText: 'خطأ آخر...', isDense: true),
                      onSubmitted: (_) => _addCustomMistake(),
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: _addCustomMistake),
                ]),
                const SizedBox(height: 14),

                // ── ملاحظات ───────────────────────────────────────────
                TextField(
                  controller: _notesController,
                  minLines: 1,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                ),
                const SizedBox(height: 24),

                // ── زر الحفظ ─────────────────────────────────────────
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : const Icon(Icons.check_rounded),
                  label: const Text('حفظ الجلسة'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

// ── Hizb/Eighth row widget ─────────────────────────────────────────────────

class _HizbSection extends StatelessWidget {
  final String title;
  final int hizb;
  final int eighth;
  final ValueChanged<int> onHizb;
  final ValueChanged<int> onEighth;

  const _HizbSection({
    required this.title,
    required this.hizb,
    required this.eighth,
    required this.onHizb,
    required this.onEighth,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: scheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Row(children: [
            // Hizb
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الحزب',
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    value: hizb,
                    isDense: true,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8)),
                    items: List.generate(
                      60,
                      (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}',
                              textDirection: TextDirection.ltr)),
                    ),
                    onChanged: (v) { if (v != null) onHizb(v); },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Eighth
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الثمن',
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    value: eighth,
                    isDense: true,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8)),
                    items: List.generate(
                      8,
                      (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}',
                              textDirection: TextDirection.ltr)),
                    ),
                    onChanged: (v) { if (v != null) onEighth(v); },
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
