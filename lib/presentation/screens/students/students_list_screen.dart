import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/quran_data.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/student.dart';
import '../../providers/app_providers.dart';
import '../../widgets/empty_state.dart';

/// All students, searchable, with quick access to detail & add.
class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الطلاب')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/students/add'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('طالب جديد'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ابحث عن طالب...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'حدث خطأ أثناء التحميل',
                subtitle: e.toString(),
              ),
              data: (students) {
                final filtered = _query.isEmpty
                    ? students
                    : students
                        .where((s) => s.name.contains(_query))
                        .toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.groups_2_outlined,
                    title: 'لا يوجد طلاب',
                    subtitle: 'أضف أول طالب بالضغط على زر "طالب جديد"',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _StudentCard(student: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surah = QuranData.byNumber(student.currentSurah);
    final progress = (student.progressPercentage / 100).clamp(0.0, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/students/${student.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.primary.withOpacity(0.12),
              child: Text(
                student.name.isNotEmpty ? student.name[0] : '؟',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${surah.displayName} • الآية ${student.currentAyahStart}-${student.currentAyahEnd}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor:
                          scheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  Formatters.percent(student.progressPercentage),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'الحفظ',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
