import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/student.dart';
import '../../providers/app_providers.dart';
import '../../widgets/empty_state.dart';

/// One-tap attendance marking for all students on a chosen day.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  bool get _isToday {
    final now = DateTime.now();
    return _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
  }

  void _shiftDay(int days) {
    setState(() => _date = _date.add(Duration(days: days)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(
          () => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _mark(String studentId, AttendanceStatus status) async {
    try {
      await ref.read(attendanceRepositoryProvider).setAttendance(
            studentId: studentId,
            date: _date,
            status: status,
          );
      // ignore: unawaited_futures
      ref.read(shareRepositoryProvider).syncPublicReport(studentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر التسجيل: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final studentsAsync = ref.watch(studentsStreamProvider);
    final byDateAsync = ref.watch(attendanceByDateProvider(_date));
    final marked = byDateAsync.value ?? const <String, AttendanceStatus>{};

    return Scaffold(
      appBar: AppBar(title: const Text('الحضور')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => _shiftDay(-1),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            _isToday
                                ? 'اليوم'
                                : Formatters.dayName(_date),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            Formatters.date(_date),
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _isToday ? null : () => _shiftDay(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'حدث خطأ',
                subtitle: e.toString(),
              ),
              data: (students) {
                if (students.isEmpty) {
                  return const EmptyState(
                    icon: Icons.groups_2_outlined,
                    title: 'لا يوجد طلاب',
                    subtitle: 'أضف طلاباً أولاً من شاشة الطلاب',
                  );
                }
                final markedCount = students
                    .where((s) => marked.containsKey(s.id))
                    .length;
                return Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            'تم تسجيل $markedCount من ${students.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: students.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _AttendanceRow(
                            student: student,
                            status: marked[student.id],
                            onMark: (status) =>
                                _mark(student.id, status),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final Student student;
  final AttendanceStatus? status;
  final ValueChanged<AttendanceStatus> onMark;

  const _AttendanceRow({
    required this.student,
    required this.status,
    required this.onMark,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primary.withOpacity(0.12),
                child: Text(
                  student.name.isNotEmpty
                      ? student.name[0]
                      : '؟',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (status != null)
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatusChoice(
                label: 'حاضر',
                color: const Color(0xFF1B7A4A),
                selected: status == AttendanceStatus.present,
                onTap: () => onMark(AttendanceStatus.present),
              ),
              const SizedBox(width: 8),
              _StatusChoice(
                label: 'متأخر',
                color: const Color(0xFFC9A24B),
                selected: status == AttendanceStatus.lateArrival,
                onTap: () => onMark(AttendanceStatus.lateArrival),
              ),
              const SizedBox(width: 8),
              _StatusChoice(
                label: 'غائب',
                color: const Color(0xFFC0392B),
                selected: status == AttendanceStatus.absent,
                onTap: () => onMark(AttendanceStatus.absent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChoice extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : color.withOpacity(0.35),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
