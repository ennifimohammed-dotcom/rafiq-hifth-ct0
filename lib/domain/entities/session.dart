import 'enums.dart';

/// Base class for a Quran study session (memorization or revision).
abstract class QuranSession {
  final String id;
  final String studentId;
  final int surah;
  final int ayahStart;
  final int ayahEnd;
  final SessionRating rating;
  final List<String> mistakes;
  final String notes;
  final DateTime timestamp;

  const QuranSession({
    required this.id,
    required this.studentId,
    required this.surah,
    required this.ayahStart,
    required this.ayahEnd,
    required this.rating,
    this.mistakes = const [],
    this.notes = '',
    required this.timestamp,
  });

  SessionType get type;

  int get ayahCount => (ayahEnd - ayahStart + 1).clamp(0, 9999);
}

/// New memorization session: advances the student's progress.
class MemorizationSession extends QuranSession {
  const MemorizationSession({
    required super.id,
    required super.studentId,
    required super.surah,
    required super.ayahStart,
    required super.ayahEnd,
    required super.rating,
    super.mistakes,
    super.notes,
    required super.timestamp,
  });

  @override
  SessionType get type => SessionType.memorization;
}

/// Revision session: evaluates already-memorized portions.
class RevisionSession extends QuranSession {
  const RevisionSession({
    required super.id,
    required super.studentId,
    required super.surah,
    required super.ayahStart,
    required super.ayahEnd,
    required super.rating,
    super.mistakes,
    super.notes,
    required super.timestamp,
  });

  @override
  SessionType get type => SessionType.revision;
}
