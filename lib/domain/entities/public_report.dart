import 'analytics.dart';
import 'enums.dart';

/// Read-only snapshot a parent sees through a share link.
class PublicReport {
  final String token;
  final String studentName;
  final String currentPosition;
  final double progressPercentage;
  final int totalAyahsMemorized;
  final PublicLastSession? lastSession;
  final AttendanceSummary attendance;
  final List<PublicNote> notes;
  final List<WeeklyPoint> weeklyProgress;
  final DateTime updatedAt;

  const PublicReport({
    required this.token,
    required this.studentName,
    required this.currentPosition,
    required this.progressPercentage,
    required this.totalAyahsMemorized,
    this.lastSession,
    required this.attendance,
    this.notes = const [],
    this.weeklyProgress = const [],
    required this.updatedAt,
  });
}

class PublicLastSession {
  final String position;
  final SessionType type;
  final SessionRating rating;
  final DateTime date;

  const PublicLastSession({
    required this.position,
    required this.type,
    required this.rating,
    required this.date,
  });
}

class PublicNote {
  final String text;
  final DateTime date;

  const PublicNote({required this.text, required this.date});
}
