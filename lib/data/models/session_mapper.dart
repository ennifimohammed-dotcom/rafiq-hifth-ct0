import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/session.dart';
import 'enum_codecs.dart';

class SessionMapper {
  SessionMapper._();

  static QuranSession fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};

    final type      = EnumCodecs.sessionTypeFrom(d['type'] as String?);
    final mistakes  = ((d['mistakes'] ?? const []) as List)
        .map((e) => e.toString()).toList();
    final timestamp = (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    // Enhancement 1: sessionDate — falls back to timestamp for old records.
    final sessionDate = (d['sessionDate'] as Timestamp?)?.toDate() ?? timestamp;

    // Enhancement 2: trackingMode — defaults to surahAyah for old records.
    final trackingMode = d['trackingMode'] == 'hizbEighth'
        ? TrackingMode.hizbEighth
        : TrackingMode.surahAyah;

    final common = (
      id:           doc.id,
      studentId:    (d['studentId']   ?? '')  as String,
      surah:        (d['surah']       ?? 0)   as int,
      ayahStart:    (d['ayahStart']   ?? 0)   as int,
      ayahEnd:      (d['ayahEnd']     ?? 0)   as int,
      rating:       EnumCodecs.ratingFrom(d['rating'] as String?),
      notes:        (d['notes']       ?? '')  as String,
      startHizb:    d['startHizb']   as int?,
      startEighth:  d['startEighth'] as int?,
      endHizb:      d['endHizb']     as int?,
      endEighth:    d['endEighth']   as int?,
    );

    if (type == SessionType.revision) {
      return RevisionSession(
        id:           common.id,
        studentId:    common.studentId,
        surah:        common.surah,
        ayahStart:    common.ayahStart,
        ayahEnd:      common.ayahEnd,
        rating:       common.rating,
        mistakes:     mistakes,
        notes:        common.notes,
        timestamp:    timestamp,
        sessionDate:  sessionDate,
        trackingMode: trackingMode,
        startHizb:    common.startHizb,
        startEighth:  common.startEighth,
        endHizb:      common.endHizb,
        endEighth:    common.endEighth,
      );
    }
    return MemorizationSession(
      id:           common.id,
      studentId:    common.studentId,
      surah:        common.surah,
      ayahStart:    common.ayahStart,
      ayahEnd:      common.ayahEnd,
      rating:       common.rating,
      mistakes:     mistakes,
      notes:        common.notes,
      timestamp:    timestamp,
      sessionDate:  sessionDate,
      trackingMode: trackingMode,
      startHizb:    common.startHizb,
      startEighth:  common.startEighth,
      endHizb:      common.endHizb,
      endEighth:    common.endEighth,
    );
  }

  static Map<String, dynamic> toMap(QuranSession s,
      {required String teacherId}) {
    final map = <String, dynamic>{
      'teacherId':    teacherId,
      'studentId':    s.studentId,
      'type':         EnumCodecs.sessionType(s.type),
      'rating':       EnumCodecs.rating(s.rating),
      'mistakes':     s.mistakes,
      'notes':        s.notes,
      'timestamp':    Timestamp.fromDate(s.timestamp),
      'sessionDate':  Timestamp.fromDate(s.sessionDate),
      'trackingMode': s.trackingMode == TrackingMode.hizbEighth
          ? 'hizbEighth'
          : 'surahAyah',
    };

    if (s.trackingMode == TrackingMode.surahAyah) {
      map['surah']    = s.surah;
      map['ayahStart'] = s.ayahStart;
      map['ayahEnd']   = s.ayahEnd;
    } else {
      map['startHizb']   = s.startHizb;
      map['startEighth'] = s.startEighth;
      map['endHizb']     = s.endHizb;
      map['endEighth']   = s.endEighth;
    }

    return map;
  }
}
