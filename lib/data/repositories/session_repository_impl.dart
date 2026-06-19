import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../models/session_mapper.dart';
import 'firestore_paths.dart';

class SessionRepositoryImpl implements SessionRepository {
  final FirestorePaths _paths;

  SessionRepositoryImpl(this._paths);

  List<QuranSession> _sortByDate(List<QuranSession> sessions) {
    sessions.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    return sessions;
  }

  @override
  Stream<List<QuranSession>> watchSessions(String studentId) {
    return _paths
        .sessions(studentId)
        .orderBy('timestamp', descending: true)
        .limit(300)
        .snapshots()
        .map((snap) =>
            _sortByDate(snap.docs.map(SessionMapper.fromDoc).toList()));
  }

  @override
  Future<List<QuranSession>> getSessions(String studentId,
      {int limit = 300}) async {
    final snap = await _paths
        .sessions(studentId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return _sortByDate(snap.docs.map(SessionMapper.fromDoc).toList());
  }

  @override
  Future<void> addSession(QuranSession session) async {
    final batch      = _paths.db.batch();
    final sessionRef = _paths.sessions(session.studentId).doc();

    batch.set(sessionRef,
        SessionMapper.toMap(session, teacherId: _paths.teacherId));

    // Update student position only for surahAyah memorization sessions.
    if (session.type == SessionType.memorization &&
        session.trackingMode == TrackingMode.surahAyah) {
      batch.update(_paths.student(session.studentId), {
        'currentSurah':    session.surah,
        'currentAyahStart': session.ayahStart,
        'currentAyahEnd':   session.ayahEnd,
        'totalAyahsMemorized':
            FieldValue.increment(session.ayahCount),
      });
    }

    await batch.commit();

    // Recompute progress percentage for surahAyah mode only.
    if (session.type == SessionType.memorization &&
        session.trackingMode == TrackingMode.surahAyah) {
      final doc =
          await _paths.student(session.studentId).get();
      final total =
          (doc.data()?['totalAyahsMemorized'] ?? 0) as int;
      final pct = (total / AppConstants.totalQuranAyahs * 100)
          .clamp(0.0, 100.0)
          .toDouble();
      await _paths
          .student(session.studentId)
          .update({'progressPercentage': pct});
    }
  }

  @override
  Future<void> deleteSession(String studentId, String sessionId) async {
    await _paths.sessions(studentId).doc(sessionId).delete();
  }

  @override
  Stream<int> watchSessionsTodayCount() {
    final now        = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _paths.db
        .collectionGroup('sessions')
        .where('teacherId', isEqualTo: _paths.teacherId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
