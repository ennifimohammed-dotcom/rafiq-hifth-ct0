import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_mapper.dart';
import 'firestore_paths.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirestorePaths _paths;

  AttendanceRepositoryImpl(this._paths);

  @override
  Stream<List<AttendanceRecord>> watchStudentAttendance(String studentId) {
    return _paths
        .attendance(studentId)
        .orderBy('date', descending: true)
        .limit(365)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceMapper.fromDoc).toList());
  }

  @override
  Future<List<AttendanceRecord>> getStudentAttendance(String studentId,
      {int limit = 365}) async {
    final snap = await _paths
        .attendance(studentId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(AttendanceMapper.fromDoc).toList();
  }

  @override
  Stream<Map<String, AttendanceStatus>> watchByDate(DateTime date) {
    final key = Formatters.dateKey(date);
    return _paths.db
        .collectionGroup('attendance')
        .where('teacherId', isEqualTo: _paths.teacherId)
        .where('dateKey', isEqualTo: key)
        .snapshots()
        .map((snap) {
      final map = <String, AttendanceStatus>{};
      for (final doc in snap.docs) {
        final record = AttendanceMapper.fromDoc(doc);
        map[record.studentId] = record.status;
      }
      return map;
    });
  }

  @override
  Future<void> setAttendance({
    required String studentId,
    required DateTime date,
    required AttendanceStatus status,
  }) async {
    final key = Formatters.dateKey(date);
    final record = AttendanceRecord(
      id: key,
      studentId: studentId,
      date: DateTime(date.year, date.month, date.day),
      status: status,
    );
    // One document per student per day -> idempotent one-tap marking.
    await _paths
        .attendance(studentId)
        .doc(key)
        .set(AttendanceMapper.toMap(record, teacherId: _paths.teacherId));
  }
}
