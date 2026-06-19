import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/enums.dart';

/// Weekly attendance grid with prev/next week navigation.
///
/// Accepts all [records] for a student and manages week navigation internally.
class WeeklyAttendanceGrid extends StatefulWidget {
  final List<AttendanceRecord> records;

  const WeeklyAttendanceGrid({super.key, required this.records});

  @override
  State<WeeklyAttendanceGrid> createState() => _WeeklyAttendanceGridState();
}

class _WeeklyAttendanceGridState extends State<WeeklyAttendanceGrid> {
  late DateTime _weekStart; // Always a Monday.

  static const _dayNames = ['إث', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = _mondayOf(now);
  }

  static DateTime _mondayOf(DateTime d) {
    final daysFromMonday = d.weekday - 1;
    return DateTime(d.year, d.month, d.day - daysFromMonday);
  }

  bool get _isCurrentWeek {
    final nowMonday = _mondayOf(DateTime.now());
    return _weekStart == nowMonday;
  }

  /// Build a lookup map: 'yyyy-M-d' → AttendanceStatus.
  Map<String, AttendanceStatus> get _dayMap {
    final map = <String, AttendanceStatus>{};
    for (final r in widget.records) {
      final key = '${r.date.year}-${r.date.month}-${r.date.day}';
      map[key] = r.status;
    }
    return map;
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  @override
  Widget build(BuildContext context) {
    final scheme   = Theme.of(context).colorScheme;
    final days     = _weekDays;
    final dayMap   = _dayMap;
    final endOfWeek = _weekStart.add(const Duration(days: 6));

    return Column(
      children: [
        // ── Week navigation header ────────────────────────────────────
        Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () =>
                setState(() => _weekStart =
                    _weekStart.subtract(const Duration(days: 7))),
          ),
          Expanded(
            child: Text(
              '${Formatters.date(_weekStart)} — ${Formatters.date(endOfWeek)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _isCurrentWeek
                ? null
                : () => setState(() => _weekStart =
                    _weekStart.add(const Duration(days: 7))),
          ),
        ]),
        const SizedBox(height: 6),

        // ── Grid ─────────────────────────────────────────────────────
        Row(
          children: List.generate(7, (i) {
            final day    = days[i];
            final key    = '${day.year}-${day.month}-${day.day}';
            final status = dayMap[key];
            final isToday = _isToday(day);

            return Expanded(
              child: _DayCell(
                dayName:  _dayNames[i],
                dayNum:   '${day.day}',
                status:   status,
                isToday:  isToday,
                scheme:   scheme,
              ),
            );
          }),
        ),

        // ── Legend ────────────────────────────────────────────────────
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendItem(icon: '✔', label: 'حاضر',  color: Color(0xFF1B7A4A)),
              SizedBox(width: 14),
              _LegendItem(icon: '✖', label: 'غائب',  color: Color(0xFFC0392B)),
              SizedBox(width: 14),
              _LegendItem(icon: '⏰', label: 'متأخر', color: Color(0xFFC9A24B)),
              SizedBox(width: 14),
              _LegendItem(icon: '—', label: 'لا توجد حصة', color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

// ── Single day cell ─────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final String dayName;
  final String dayNum;
  final AttendanceStatus? status;
  final bool isToday;
  final ColorScheme scheme;

  const _DayCell({
    required this.dayName,
    required this.dayNum,
    required this.status,
    required this.isToday,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      AttendanceStatus.present     => ('✔', const Color(0xFF1B7A4A)),
      AttendanceStatus.absent      => ('✖', const Color(0xFFC0392B)),
      AttendanceStatus.lateArrival => ('⏰', const Color(0xFFC9A24B)),
      null                         => ('—', Colors.grey),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isToday
            ? scheme.primary.withOpacity(0.08)
            : scheme.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: isToday
            ? Border.all(color: scheme.primary.withOpacity(0.4))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dayName,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isToday ? scheme.primary : scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(dayNum,
              style: TextStyle(
                  fontSize: 10,
                  color: isToday ? scheme.primary : scheme.outline)),
          const SizedBox(height: 4),
          Text(icon,
              style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }
}

// ── Legend item ──────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _LegendItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: 13, color: color)),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
