import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/analytics.dart';
import '../../domain/entities/public_report.dart';
import 'enum_codecs.dart';

class PublicReportMapper {
  PublicReportMapper._();

  static PublicReport fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final last = d['lastSession'] as Map<String, dynamic>?;
    return PublicReport(
      token: doc.id,
      studentName: (d['studentName'] ?? '') as String,
      currentPosition: (d['currentPosition'] ?? '') as String,
      progressPercentage:
          ((d['progressPercentage'] ?? 0) as num).toDouble(),
      totalAyahsMemorized: (d['totalAyahsMemorized'] ?? 0) as int,
      lastSession: last == null
          ? null
          : PublicLastSession(
              position: (last['position'] ?? '') as String,
              type: EnumCodecs.sessionTypeFrom(last['type'] as String?),
              rating: EnumCodecs.ratingFrom(last['rating'] as String?),
              date: (last['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
            ),
      attendance: AttendanceSummary(
        present: (d['attendancePresent'] ?? 0) as int,
        absent: (d['attendanceAbsent'] ?? 0) as int,
        lateArrival: (d['attendanceLate'] ?? 0) as int,
      ),
      notes: ((d['notes'] ?? const []) as List)
          .whereType<Map<String, dynamic>>()
          .map((n) => PublicNote(
                text: (n['text'] ?? '') as String,
                date: (n['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
              ))
          .toList(),
      weeklyProgress: ((d['weeklyProgress'] ?? const []) as List)
          .whereType<Map<String, dynamic>>()
          .map((w) => WeeklyPoint(
                label: (w['label'] ?? '') as String,
                ayahs: (w['ayahs'] ?? 0) as int,
              ))
          .toList(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toMap(PublicReport r,
          {required String teacherId}) =>
      {
        'teacherId': teacherId,
        'studentName': r.studentName,
        'currentPosition': r.currentPosition,
        'progressPercentage': r.progressPercentage,
        'totalAyahsMemorized': r.totalAyahsMemorized,
        'lastSession': r.lastSession == null
            ? null
            : {
                'position': r.lastSession!.position,
                'type': EnumCodecs.sessionType(r.lastSession!.type),
                'rating': EnumCodecs.rating(r.lastSession!.rating),
                'date': Timestamp.fromDate(r.lastSession!.date),
              },
        'attendancePresent': r.attendance.present,
        'attendanceAbsent': r.attendance.absent,
        'attendanceLate': r.attendance.lateArrival,
        'notes': r.notes
            .map((n) =>
                {'text': n.text, 'date': Timestamp.fromDate(n.date)})
            .toList(),
        'weeklyProgress': r.weeklyProgress
            .map((w) => {'label': w.label, 'ayahs': w.ayahs})
            .toList(),
        'updatedAt': Timestamp.fromDate(r.updatedAt),
      };
}
