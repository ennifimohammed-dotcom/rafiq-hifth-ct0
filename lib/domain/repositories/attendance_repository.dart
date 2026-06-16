import '../entities/attendance_record.dart';
import '../entities/enums.dart';

abstract class AttendanceRepository {
  Stream<List<AttendanceRecord>> watchStudentAttendance(String studentId);
  Future<List<AttendanceRecord>> getStudentAttendance(String studentId,
      {int limit});

  /// Map of studentId -> status for a given day across all students.
  Stream<Map<String, AttendanceStatus>> watchByDate(DateTime date);

  Future<void> setAttendance({
    required String studentId,
    required DateTime date,
    required AttendanceStatus status,
  });
}
