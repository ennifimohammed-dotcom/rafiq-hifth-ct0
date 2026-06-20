import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/quran_data.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/student.dart';
import '../../providers/app_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/rating_chip.dart';
import '../../widgets/section_card.dart';
import '../../widgets/weekly_attendance_grid.dart';
import '../../widgets/weekly_progress_chart.dart';

/// Full student profile: overview, sessions, attendance, notes.
class StudentDetailScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProvider(studentId));

    return studentAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'حدث خطأ',
          subtitle: e.toString(),
        ),
      ),
      data: (student) {
        if (student == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'الطالب غير موجود',
            ),
          );
        }
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(student.name),
              actions: [
                IconButton(
                  tooltip: 'مشاركة التقرير',
                  icon: const Icon(Icons.qr_code_rounded),
                  onPressed: () => context.push('/students/$studentId/share'),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      context.push('/students/$studentId/edit');
                    } else if (v == 'delete') {
                      await _confirmDelete(context, ref, student);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('تعديل'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading:
                            Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('حذف',
                            style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'نظرة عامة'),
                  Tab(text: 'الجلسات'),
                  Tab(text: 'الحضور'),
                  Tab(text: 'الملاحظات'),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => context.push('/students/$studentId/session'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('جلسة جديدة'),
            ),
            body: TabBarView(
              children: [
                _OverviewTab(student: student),
                _SessionsTab(studentId: studentId),
                _AttendanceTab(studentId: studentId),
                _NotesTab(studentId: studentId),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطالب'),
        content: Text(
            'سيتم حذف "${student.name}" مع كل الجلسات والحضور والملاحظات. لا يمكن التراجع.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(studentRepositoryProvider).deleteStudent(student.id);
      if (context.mounted) context.go('/students');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الحذف: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Overview tab
// ---------------------------------------------------------------------------

class _OverviewTab extends ConsumerWidget {
  final Student student;

  const _OverviewTab({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final surah = QuranData.byNumber(student.currentSurah);
    final weekly = ref.watch(studentWeeklyProgressProvider(student.id));
    final summary = ref.watch(studentAttendanceSummaryProvider(student.id));
    final progress = (student.progressPercentage / 100).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'تقدم الحفظ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    Formatters.percent(student.progressPercentage),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: scheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${student.totalAyahsMemorized} آية محفوظة',
                style:
                    TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(Icons.menu_book_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الموضع الحالي',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.displayName} • الآية ${student.currentAyahStart} - ${student.currentAyahEnd}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(
                label: 'حضور',
                value: '${summary.present}',
                color: const Color(0xFF1B7A4A),
              ),
              _MiniStat(
                label: 'تأخر',
                value: '${summary.lateArrival}',
                color: const Color(0xFFC9A24B),
              ),
              _MiniStat(
                label: 'غياب',
                value: '${summary.absent}',
                color: const Color(0xFFC0392B),
              ),
              _MiniStat(
                label: 'نسبة الحضور',
                value: '${summary.rate.toStringAsFixed(0)}٪',
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الحفظ الأسبوعي (آيات)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              weekly.every((p) => p.ayahs == 0)
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'لا توجد جلسات حفظ بعد',
                          style: TextStyle(
                              fontSize: 13, color: scheme.outline),
                        ),
                      ),
                    )
                  : WeeklyProgressChart(points: weekly),
            ],
          ),
        ),
        if (student.parentPhone != null && student.parentPhone!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionCard(
            child: Row(
              children: [
                Icon(Icons.phone_outlined, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Text('ولي الأمر: ${student.parentPhone}'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sessions tab
// ---------------------------------------------------------------------------

class _SessionsTab extends ConsumerWidget {
  final String studentId;

  const _SessionsTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(studentSessionsProvider(studentId));

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'حدث خطأ',
        subtitle: e.toString(),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return const EmptyState(
            icon: Icons.auto_stories_outlined,
            title: 'لا توجد جلسات بعد',
            subtitle: 'اضغط "جلسة جديدة" لتسجيل أول جلسة',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _SessionCard(
            session: sessions[index],
            onDelete: () =>
                _deleteSession(context, ref, sessions[index]),
          ),
        );
      },
    );
  }

  Future<void> _deleteSession(
      BuildContext context, WidgetRef ref, QuranSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الجلسة'),
        content: const Text('هل تريد حذف هذه الجلسة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(sessionRepositoryProvider)
          .deleteSession(studentId, session.id);
      // ignore: unawaited_futures
      ref.read(shareRepositoryProvider).syncPublicReport(studentId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الحذف: $e')),
        );
      }
    }
  }
}

class _SessionCard extends StatelessWidget {
  final QuranSession session;
  final VoidCallback onDelete;

  const _SessionCard({required this.session, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMemorization = session.type == SessionType.memorization;
    final isSurahMode = session.trackingMode == TrackingMode.surahAyah;

    // Position label depends on tracking mode.
    final positionLabel = isSurahMode
        ? () {
            final surah = QuranData.byNumber(session.surah);
            return '${surah.displayName} • الآية ${session.ayahStart} - ${session.ayahEnd} (${session.ayahCount} آية)';
          }()
        : 'الحزب ${session.startHizb} الثمن ${session.startEighth}'
          ' — الحزب ${session.endHizb} الثمن ${session.endEighth}';

    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isMemorization
                          ? scheme.primary
                          : const Color(0xFFC9A24B))
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.type.labelAr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isMemorization
                        ? scheme.primary
                        : const Color(0xFF8A6A22),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              RatingChip(rating: session.rating),
              const Spacer(),
              // Session date badge
              Text(
                Formatters.date(session.sessionDate),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.delete_outline,
                    size: 20, color: scheme.outline),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            positionLabel,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          if (session.mistakes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in session.mistakes)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      m,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (session.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              session.notes,
              style:
                  TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            Formatters.dateTime(session.timestamp),
            style: TextStyle(fontSize: 11, color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Attendance tab
// ---------------------------------------------------------------------------

class _AttendanceTab extends ConsumerWidget {
  final String studentId;

  const _AttendanceTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(studentAttendanceProvider(studentId));
    final summary = ref.watch(studentAttendanceSummaryProvider(studentId));

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'حدث خطأ',
        subtitle: e.toString(),
      ),
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'لا توجد سجلات حضور',
            subtitle: 'استخدم شاشة الحضور لتسجيل حضور اليوم',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            // Summary stats
            SectionCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(
                    label: 'حضور',
                    value: '${summary.present}',
                    color: const Color(0xFF1B7A4A),
                  ),
                  _MiniStat(
                    label: 'تأخر',
                    value: '${summary.lateArrival}',
                    color: const Color(0xFFC9A24B),
                  ),
                  _MiniStat(
                    label: 'غياب',
                    value: '${summary.absent}',
                    color: const Color(0xFFC0392B),
                  ),
                  _MiniStat(
                    label: 'النسبة',
                    value: '${summary.rate.toStringAsFixed(0)}٪',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Weekly attendance grid
            SectionCard(
              padding: const EdgeInsets.all(12),
              child: WeeklyAttendanceGrid(records: records),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Notes tab
// ---------------------------------------------------------------------------

class _NotesTab extends ConsumerStatefulWidget {
  final String studentId;

  const _NotesTab({required this.studentId});

  @override
  ConsumerState<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<_NotesTab> {
  final _controller = TextEditingController();
  bool _visibleToParent = true;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(noteRepositoryProvider).addNote(Note(
            id: const Uuid().v4(),
            studentId: widget.studentId,
            text: text,
            visibleToParent: _visibleToParent,
            createdAt: DateTime.now(),
          ));
      // ignore: unawaited_futures
      ref.read(shareRepositoryProvider).syncPublicReport(widget.studentId);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إضافة الملاحظة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteNote(Note note) async {
    try {
      await ref
          .read(noteRepositoryProvider)
          .deleteNote(widget.studentId, note.id);
      // ignore: unawaited_futures
      ref.read(shareRepositoryProvider).syncPublicReport(widget.studentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الحذف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final notesAsync = ref.watch(studentNotesProvider(widget.studentId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'أضف ملاحظة عن الطالب...',
                    border: InputBorder.none,
                  ),
                ),
                Row(
                  children: [
                    Switch(
                      value: _visibleToParent,
                      onChanged: (v) =>
                          setState(() => _visibleToParent = v),
                    ),
                    Text(
                      'مرئية لولي الأمر',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _saving ? null : _addNote,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('إضافة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: notesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'حدث خطأ',
              subtitle: e.toString(),
            ),
            data: (notes) {
              if (notes.isEmpty) {
                return const EmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  title: 'لا توجد ملاحظات',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: notes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return SectionCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note.text,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              note.visibleToParent
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 16,
                              color: scheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              note.visibleToParent
                                  ? 'مرئية لولي الأمر'
                                  : 'خاصة بالمعلم',
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.outline,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              Formatters.date(note.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.outline,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _deleteNote(note),
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: scheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
