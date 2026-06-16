import '../entities/session.dart';

abstract class SessionRepository {
  Stream<List<QuranSession>> watchSessions(String studentId);
  Future<List<QuranSession>> getSessions(String studentId, {int limit});

  /// Persists a session. Memorization sessions also advance the
  /// student's current position and progress percentage atomically.
  Future<void> addSession(QuranSession session);

  Future<void> deleteSession(String studentId, String sessionId);

  /// Number of sessions recorded today across all students.
  Stream<int> watchSessionsTodayCount();
}
