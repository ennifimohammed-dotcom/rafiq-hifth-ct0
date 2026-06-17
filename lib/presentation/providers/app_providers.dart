import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/analytics_utils.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/firestore_paths.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../data/repositories/share_repository_impl.dart';
import '../../data/repositories/student_repository_impl.dart';
import '../../domain/entities/analytics.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/public_report.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/share_repository.dart';
import '../../domain/repositories/student_repository.dart';

// ---------------------------------------------------------------------------
// Infrastructure singletons
// ---------------------------------------------------------------------------

/// Overridden in main.dart with the initialised SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main.dart');
});

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// ---------------------------------------------------------------------------
// Auth  (local credentials + anonymous Firebase session)
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(sharedPreferencesProvider));
});

final teacherIdProvider = StreamProvider<String?>(
    (ref) => ref.watch(authRepositoryProvider).watchTeacherId());

// ---------------------------------------------------------------------------
// Firestore path resolver
// ---------------------------------------------------------------------------

final firestorePathsProvider = Provider<FirestorePaths>((ref) {
  final uid = ref.watch(teacherIdProvider).value ??
      ref.watch(authRepositoryProvider).currentTeacherId ??
      '_unauthenticated_';
  return FirestorePaths(ref.watch(firestoreProvider), uid);
});

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

final studentRepositoryProvider = Provider<StudentRepository>(
    (ref) => StudentRepositoryImpl(ref.watch(firestorePathsProvider)));

final sessionRepositoryProvider = Provider<SessionRepository>(
    (ref) => SessionRepositoryImpl(ref.watch(firestorePathsProvider)));

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
    (ref) => AttendanceRepositoryImpl(ref.watch(firestorePathsProvider)));

final noteRepositoryProvider = Provider<NoteRepository>(
    (ref) => NoteRepositoryImpl(ref.watch(firestorePathsProvider)));

final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  return ShareRepositoryImpl(
    ref.watch(firestorePathsProvider),
    ref.watch(studentRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
    ref.watch(noteRepositoryProvider),
    (studentId) => ref
        .read(attendanceRepositoryProvider)
        .getStudentAttendance(studentId),
  );
});

// ---------------------------------------------------------------------------
// Students
// ---------------------------------------------------------------------------

final studentsStreamProvider = StreamProvider<List<Student>>(
    (ref) => ref.watch(studentRepositoryProvider).watchStudents());

final studentProvider = StreamProvider.family<Student?, String>(
    (ref, id) => ref.watch(studentRepositoryProvider).watchStudent(id));

// ---------------------------------------------------------------------------
// Sessions
// ---------------------------------------------------------------------------

final studentSessionsProvider =
    StreamProvider.family<List<QuranSession>, String>((ref, studentId) =>
        ref.watch(sessionRepositoryProvider).watchSessions(studentId));

final sessionsTodayCountProvider = StreamProvider<int>(
    (ref) => ref.watch(sessionRepositoryProvider).watchSessionsTodayCount());

final studentWeeklyProgressProvider =
    Provider.family<List<WeeklyPoint>, String>((ref, studentId) {
  final sessions =
      ref.watch(studentSessionsProvider(studentId)).value ?? const [];
  return AnalyticsUtils.weeklyProgress(sessions);
});

// ---------------------------------------------------------------------------
// Attendance
// ---------------------------------------------------------------------------

final studentAttendanceProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, studentId) =>
        ref
            .watch(attendanceRepositoryProvider)
            .watchStudentAttendance(studentId));

final studentAttendanceSummaryProvider =
    Provider.family<AttendanceSummary, String>((ref, studentId) {
  final records =
      ref.watch(studentAttendanceProvider(studentId)).value ?? const [];
  return AnalyticsUtils.summarize(records);
});

final attendanceByDateProvider =
    StreamProvider.family<Map<String, AttendanceStatus>, DateTime>(
        (ref, date) =>
            ref.watch(attendanceRepositoryProvider).watchByDate(date));

// ---------------------------------------------------------------------------
// Notes
// ---------------------------------------------------------------------------

final studentNotesProvider = StreamProvider.family<List<Note>, String>(
    (ref, studentId) =>
        ref.watch(noteRepositoryProvider).watchNotes(studentId));

// ---------------------------------------------------------------------------
// Public report (parent view — no auth required)
// ---------------------------------------------------------------------------

final publicReportProvider = FutureProvider.family<PublicReport?, String>(
    (ref, token) =>
        ref.watch(shareRepositoryProvider).fetchPublicReport(token));
