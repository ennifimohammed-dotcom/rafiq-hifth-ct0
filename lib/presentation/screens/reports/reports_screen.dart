import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/quran_data.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/student.dart';
import '../../providers/app_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

/// Per-student report overview with quick access to sharing.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'حدث خطأ',
          subtitle: e.toString(),
        ),
        data: (students) {
          if (students.isEmpty) {
            return const EmptyState(
              icon: Icons.assessment_outlined,
              title: 'لا توجد تقارير',
              subtitle: 'أضف طلاباً لعرض تقاريرهم هنا',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _ReportCard(student: students[index]),
          );
        },
      ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  final Student student;

  const _ReportCard({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final surah = QuranData.byNumber(student.currentSurah);
    final summary = ref.watch(studentAttendanceSummaryProvider(student.id));
    final progress = (student.progressPercentage / 100).clamp(0.0, 1.0);
    final isShared =
        student.shareToken != null && student.shareToken!.isNotEmpty;

    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isShared)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'مُشارَك',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        scheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                Formatters.percent(student.progressPercentage),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${surah.displayName} • الآية ${student.currentAyahStart}-${student.currentAyahEnd}'
            '   |   حضور ${summary.rate.toStringAsFixed(0)}٪',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/students/${student.id}'),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('التفاصيل'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push('/students/${student.id}/share'),
                  icon: const Icon(Icons.qr_code_rounded, size: 18),
                  label: Text(isShared ? 'المشاركة' : 'مشاركة'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
