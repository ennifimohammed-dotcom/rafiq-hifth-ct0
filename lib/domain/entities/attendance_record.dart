import 'enums.dart';

/// One attendance entry for a student on a given day.
class AttendanceRecord {
  final String id;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
  });
}
