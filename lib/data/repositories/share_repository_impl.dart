import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/quran_data.dart';
import '../../domain/entities/attendance_record.dart';
import '../../core/utils/analytics_utils.dart';
import '../../domain/entities/public_report.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/share_repository.dart';
import '../../domain/repositories/student_repository.dart';
import '../models/public_report_mapper.dart';
import 'firestore_paths.dart';

class ShareRepositoryImpl implements ShareRepository {
  final FirestorePaths _paths;
  final StudentRepository _students;
  final SessionRepository _sessions;
  final NoteRepository _notes;
  final AttendanceFetcher _attendance;

  ShareRepositoryImpl(
    this._paths,
    this._students,
    this._sessions,
    this._notes,
    this._attendance,
  );

  @override
  Future<String> generateToken(String studentId) async {
    final student = await _students.getStudent(studentId);
    if (student == null) {
      throw StateError('Student not found');
    }

    // Revoke the previous token first (one active link per student).
    if (student.shareToken != null) {
      await revokeToken(studentId);
    }

    final token = const Uuid().v4().replaceAll('-', '');
    final batch = _paths.db.batch();
    batch.set(_paths.sharedTokens().doc(token), {
      'teacherId': _paths.teacherId,
      'studentId': studentId,
      'createdAt': Timestamp.now(),
      'active': true,
    });
    batch.update(_paths.student(studentId), {'shareToken': token});
    await batch.commit();

    await syncPublicReport(studentId);
    return token;
  }

  @override
  Future<void> revokeToken(String studentId) async {
    final student = await _students.getStudent(studentId);
    final token = student?.shareToken;
    if (token == null) return;

    final batch = _paths.db.batch();
    batch.delete(_paths.sharedTokens().doc(token));
    batch.delete(_paths.publicReports().doc(token));
    batch.update(_paths.student(studentId), {'shareToken': null});
    await batch.commit();
  }

  @override
  Future<void> syncPublicReport(String studentId) async {
    final student = await _students.getStudent(studentId);
    final token = student?.shareToken;
    if (student == null || token == null) return;

    final sessions = await _sessions.getSessions(studentId, limit: 300);
    final attendanceRecords = await _attendance(studentId);
    final notes = await _notes.getNotes(studentId, limit: 50);

    final surah = QuranData.byNumber(student.currentSurah);
    final last = sessions.isEmpty ? null : sessions.first;
    final lastSurah = last == null ? null : QuranData.byNumber(last.surah);

    final report = PublicReport(
      token: token,
      studentName: student.name,
      currentPosition:
          '${surah.displayName} – الآية ${student.currentAyahStart} إلى ${student.currentAyahEnd}',
      progressPercentage: student.progressPercentage,
      totalAyahsMemorized: student.totalAyahsMemorized,
      lastSession: last == null
          ? null
          : PublicLastSession(
              position:
                  '${lastSurah!.displayName} (${last.ayahStart} – ${last.ayahEnd})',
              type: last.type,
              rating: last.rating,
              date: last.timestamp,
            ),
      attendance: AnalyticsUtils.summarize(attendanceRecords),
      notes: notes
          .where((n) => n.visibleToParent)
          .take(5)
          .map((n) => PublicNote(text: n.text, date: n.createdAt))
          .toList(),
      weeklyProgress: AnalyticsUtils.weeklyProgress(sessions),
      updatedAt: DateTime.now(),
    );

    await _paths.publicReports().doc(token).set(
        PublicReportMapper.toMap(report, teacherId: _paths.teacherId));
  }

  @override
  Future<PublicReport?> fetchPublicReport(String token) async {
    final doc = await _paths.publicReports().doc(token).get();
    if (!doc.exists) return null;
    return PublicReportMapper.fromDoc(doc);
  }
}

/// Small function type so the share repository can fetch attendance
/// without depending on the full attendance contract.
typedef AttendanceFetcher = Future<List<AttendanceRecord>> Function(
    String studentId);
