import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/session.dart';
import 'enum_codecs.dart';

class SessionMapper {
  SessionMapper._();

  static QuranSession fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final type = EnumCodecs.sessionTypeFrom(d['type'] as String?);
    final mistakes =
        ((d['mistakes'] ?? const []) as List).map((e) => e.toString()).toList();
    final base = (
      id: doc.id,
      studentId: (d['studentId'] ?? '') as String,
      surah: (d['surah'] ?? 1) as int,
      ayahStart: (d['ayahStart'] ?? 1) as int,
      ayahEnd: (d['ayahEnd'] ?? 1) as int,
      rating: EnumCodecs.ratingFrom(d['rating'] as String?),
      notes: (d['notes'] ?? '') as String,
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
    if (type == SessionType.revision) {
      return RevisionSession(
        id: base.id,
        studentId: base.studentId,
        surah: base.surah,
        ayahStart: base.ayahStart,
        ayahEnd: base.ayahEnd,
        rating: base.rating,
        mistakes: mistakes,
        notes: base.notes,
        timestamp: base.timestamp,
      );
    }
    return MemorizationSession(
      id: base.id,
      studentId: base.studentId,
      surah: base.surah,
      ayahStart: base.ayahStart,
      ayahEnd: base.ayahEnd,
      rating: base.rating,
      mistakes: mistakes,
      notes: base.notes,
      timestamp: base.timestamp,
    );
  }

  static Map<String, dynamic> toMap(QuranSession s,
          {required String teacherId}) =>
      {
        'teacherId': teacherId,
        'studentId': s.studentId,
        'type': EnumCodecs.sessionType(s.type),
        'surah': s.surah,
        'ayahStart': s.ayahStart,
        'ayahEnd': s.ayahEnd,
        'rating': EnumCodecs.rating(s.rating),
        'mistakes': s.mistakes,
        'notes': s.notes,
        'timestamp': Timestamp.fromDate(s.timestamp),
      };
}
