import 'enums.dart';

/// Base class for a Quran study session (memorization or revision).
abstract class QuranSession {
  final String id;
  final String studentId;
  final SessionRating rating;
  final List<String> mistakes;
  final String notes;
  final DateTime timestamp;

  // ── Enhancement 1: session date (actual lesson date, defaults to timestamp) ──
  final DateTime sessionDate;

  // ── Enhancement 2: tracking mode ─────────────────────────────────────────────
  final TrackingMode trackingMode;

  // Surah/Ayah fields (used when trackingMode == surahAyah)
  final int surah;
  final int ayahStart;
  final int ayahEnd;

  // Hizb/Eighth fields (used when trackingMode == hizbEighth, all nullable)
  final int? startHizb;
  final int? startEighth;
  final int? endHizb;
  final int? endEighth;

  QuranSession({
    required this.id,
    required this.studentId,
    required this.rating,
    this.mistakes = const [],
    this.notes = '',
    required this.timestamp,
    DateTime? sessionDate,
    this.trackingMode = TrackingMode.surahAyah,
    this.surah = 0,
    this.ayahStart = 0,
    this.ayahEnd = 0,
    this.startHizb,
    this.startEighth,
    this.endHizb,
    this.endEighth,
  }) : sessionDate = sessionDate ?? timestamp;

  SessionType get type;

  int get ayahCount => trackingMode == TrackingMode.surahAyah
      ? (ayahEnd - ayahStart + 1).clamp(0, 9999)
      : 0;
}

/// New memorization session: advances the student's progress.
class MemorizationSession extends QuranSession {
  MemorizationSession({
    required super.id,
    required super.studentId,
    required super.rating,
    super.mistakes,
    super.notes,
    required super.timestamp,
    super.sessionDate,
    super.trackingMode,
    super.surah,
    super.ayahStart,
    super.ayahEnd,
    super.startHizb,
    super.startEighth,
    super.endHizb,
    super.endEighth,
  });

  @override
  SessionType get type => SessionType.memorization;
}

/// Revision session: evaluates already-memorized portions.
class RevisionSession extends QuranSession {
  RevisionSession({
    required super.id,
    required super.studentId,
    required super.rating,
    super.mistakes,
    super.notes,
    required super.timestamp,
    super.sessionDate,
    super.trackingMode,
    super.surah,
    super.ayahStart,
    super.ayahEnd,
    super.startHizb,
    super.startEighth,
    super.endHizb,
    super.endEighth,
  });

  @override
  SessionType get type => SessionType.revision;
}
