/// Lightweight analytics value objects shared between teacher UI
/// and the public parent report.

class WeeklyPoint {
  final String label;
  final int ayahs;

  const WeeklyPoint({required this.label, required this.ayahs});
}

class AttendanceSummary {
  final int present;
  final int absent;
  final int lateArrival;

  const AttendanceSummary({
    this.present = 0,
    this.absent = 0,
    this.lateArrival = 0,
  });

  int get total => present + absent + lateArrival;

  /// Attendance rate (present + late) as a 0–100 percentage.
  double get rate =>
      total == 0 ? 0 : (present + lateArrival) / total * 100;
}
