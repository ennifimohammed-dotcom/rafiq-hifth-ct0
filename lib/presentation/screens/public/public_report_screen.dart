import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/quran_data.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/analytics.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/public_report.dart';
import '../../providers/app_providers.dart';
import '../../widgets/section_card.dart';
import '../../widgets/weekly_progress_chart.dart';

/// Parent-facing read-only report. No authentication required.
class PublicReportScreen extends ConsumerWidget {
  final String token;

  const PublicReportScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(publicReportProvider(token));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الحفظ'),
        automaticallyImplyLeading: false,
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _InvalidToken(message: e.toString()),
        data: (report) {
          if (report == null) {
            return const _InvalidToken();
          }
          return _ReportBody(report: report);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Report body
// ---------------------------------------------------------------------------

class _ReportBody extends StatelessWidget {
  final PublicReport report;

  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (report.progressPercentage / 100).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header: student name + last updated
        SectionCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primary.withOpacity(0.12),
                child: Text(
                  report.studentName.isNotEmpty
                      ? report.studentName[0]
                      : '؟',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                report.studentName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'آخر تحديث: ${Formatters.dateTime(report.updatedAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Progress bar
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'تقدم الحفظ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    Formatters.percent(report.progressPercentage),
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
                  minHeight: 12,
                  backgroundColor: scheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${report.totalAyahsMemorized} آية محفوظة',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    report.currentPosition,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Last session
        if (report.lastSession != null) ...[
          _SectionTitle(title: 'آخر جلسة'),
          const SizedBox(height: 8),
          _LastSessionCard(session: report.lastSession!),
          const SizedBox(height: 12),
        ],

        // Attendance summary
        _SectionTitle(title: 'ملخص الحضور'),
        const SizedBox(height: 8),
        _AttendanceSummaryCard(summary: report.attendance),
        const SizedBox(height: 12),

        // Weekly chart
        if (report.weeklyProgress.isNotEmpty &&
            report.weeklyProgress.any((p) => p.ayahs > 0)) ...[
          _SectionTitle(title: 'الحفظ الأسبوعي (آيات)'),
          const SizedBox(height: 8),
          SectionCard(
            child: WeeklyProgressChart(points: report.weeklyProgress),
          ),
          const SizedBox(height: 12),
        ],

        // Notes visible to parent
        if (report.notes.isNotEmpty) ...[
          _SectionTitle(title: 'ملاحظات المعلم'),
          const SizedBox(height: 8),
          for (final note in report.notes) ...[
            _NoteCard(note: note),
            const SizedBox(height: 8),
          ],
        ],

        const SizedBox(height: 16),
        Center(
          child: Text(
            'معلم القرآن',
            style: TextStyle(
              fontSize: 12,
              color: scheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _LastSessionCard extends StatelessWidget {
  final PublicLastSession session;

  const _LastSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMemorization = session.type == SessionType.memorization;

    return SectionCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isMemorization
                  ? Icons.auto_stories_rounded
                  : Icons.replay_rounded,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.position,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Pill(
                      label: session.type.labelAr,
                      color: isMemorization
                          ? scheme.primary
                          : const Color(0xFFC9A24B),
                    ),
                    const SizedBox(width: 6),
                    _Pill(
                      label: session.rating.labelAr,
                      color: _ratingColor(session.rating),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            Formatters.date(session.date),
            style: TextStyle(fontSize: 11, color: scheme.outline),
          ),
        ],
      ),
    );
  }

  Color _ratingColor(SessionRating rating) {
    switch (rating) {
      case SessionRating.excellent:
        return const Color(0xFF1B7A4A);
      case SessionRating.good:
        return const Color(0xFF2E7DB8);
      case SessionRating.weak:
        return const Color(0xFFC0392B);
    }
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  final AttendanceSummary summary;

  const _AttendanceSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AttendanceStat(
            label: 'حضور',
            value: '${summary.present}',
            color: const Color(0xFF1B7A4A),
          ),
          _AttendanceStat(
            label: 'تأخر',
            value: '${summary.lateArrival}',
            color: const Color(0xFFC9A24B),
          ),
          _AttendanceStat(
            label: 'غياب',
            value: '${summary.absent}',
            color: const Color(0xFFC0392B),
          ),
          _AttendanceStat(
            label: 'النسبة',
            value: '${summary.rate.toStringAsFixed(0)}٪',
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AttendanceStat({
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final PublicNote note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.text, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            Formatters.date(note.date),
            style: TextStyle(fontSize: 11, color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Invalid / expired token
// ---------------------------------------------------------------------------

class _InvalidToken extends StatelessWidget {
  final String? message;

  const _InvalidToken({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text(
              'الرابط غير صالح',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'قد يكون هذا الرابط منتهياً أو تم إلغاؤه من قِبَل المعلم.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
