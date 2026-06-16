import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/quran_data.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/app_providers.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final students = ref.watch(studentsStreamProvider);
    final sessionsToday = ref.watch(sessionsTodayCountProvider);
    final today = DateTime.now();
    final attendanceToday = ref.watch(
        attendanceByDateProvider(DateTime(today.year, today.month, today.day)));

    final presentToday = attendanceToday.maybeWhen(
      data: (map) => map.values
          .where((s) =>
              s == AttendanceStatus.present ||
              s == AttendanceStatus.lateArrival)
          .length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل تريد تسجيل الخروج؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('خروج'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authRepositoryProvider).signOut();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentsStreamProvider);
          ref.invalidate(sessionsTodayCountProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${Formatters.dayName(today)}، ${Formatters.date(today)}',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.groups_rounded,
                    label: 'إجمالي الطلاب',
                    value: '${students.value?.length ?? 0}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    icon: Icons.menu_book_rounded,
                    label: 'جلسات اليوم',
                    value: '${sessionsToday.value ?? 0}',
                    color: const Color(0xFF2E7DB8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    icon: Icons.fact_check_rounded,
                    label: 'حضور اليوم',
                    value: '$presentToday',
                    color: const Color(0xFFC9A24B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'إجراءات سريعة',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_circle_rounded,
                    label: 'جلسة جديدة',
                    onTap: () => context.go('/students'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.checklist_rounded,
                    label: 'حضور اليوم',
                    onTap: () => context.go('/attendance'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'الطلاب',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            students.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SectionCard(
                child: Text('تعذر تحميل الطلاب: $e'),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return SectionCard(
                    child: Column(
                      children: [
                        Icon(Icons.person_add_alt_1_rounded,
                            size: 40, color: scheme.outline),
                        const SizedBox(height: 8),
                        const Text('لا يوجد طلاب بعد'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => context.push('/students/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة أول طالب'),
                        ),
                      ],
                    ),
                  );
                }
                final preview = list.take(5).toList();
                return Column(
                  children: [
                    for (final student in preview)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SectionCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: InkWell(
                            onTap: () =>
                                context.push('/students/${student.id}'),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      scheme.primary.withOpacity(0.12),
                                  child: Text(
                                    student.name.isEmpty
                                        ? '؟'
                                        : student.name[0],
                                    style: TextStyle(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        QuranData.byNumber(
                                                student.currentSurah)
                                            .displayName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  Formatters.percent(
                                      student.progressPercentage),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (list.length > 5)
                      TextButton(
                        onPressed: () => context.go('/students'),
                        child: const Text('عرض جميع الطلاب'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer.withOpacity(0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
