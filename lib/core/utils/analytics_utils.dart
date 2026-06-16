import '../../domain/entities/analytics.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/session.dart';

/// Pure analytics computations shared by the teacher UI and the
/// public-report publisher.
class AnalyticsUtils {
  AnalyticsUtils._();

  /// Ayahs memorized per week over the last [weeks] weeks (oldest first).
  static List<WeeklyPoint> weeklyProgress(
    List<QuranSession> sessions, {
    int weeks = 8,
  }) {
    final points = <WeeklyPoint>[];
    final currentWeekStart = _startOfWeek(DateTime.now());
    for (var i = weeks - 1; i >= 0; i--) {
      final weekStart = currentWeekStart.subtract(Duration(days: 7 * i));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final ayahs = sessions
          .where((s) =>
              s.type == SessionType.memorization &&
              !s.timestamp.isBefore(weekStart) &&
              s.timestamp.isBefore(weekEnd))
          .fold<int>(0, (sum, s) => sum + s.ayahCount);
      points.add(WeeklyPoint(
        label: '${weekStart.day}/${weekStart.month}',
        ayahs: ayahs,
      ));
    }
    return points;
  }

  static AttendanceSummary summarize(List<AttendanceRecord> records) {
    var present = 0;
    var absent = 0;
    var lateArrival = 0;
    for (final r in records) {
      switch (r.status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.absent:
          absent++;
        case AttendanceStatus.lateArrival:
          lateArrival++;
      }
    }
    return AttendanceSummary(
      present: present,
      absent: absent,
      lateArrival: lateArrival,
    );
  }

  static DateTime _startOfWeek(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}
