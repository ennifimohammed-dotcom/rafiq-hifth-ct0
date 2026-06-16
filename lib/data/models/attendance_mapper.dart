import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/attendance_record.dart';
import '../../core/utils/formatters.dart';
import 'enum_codecs.dart';

class AttendanceMapper {
  AttendanceMapper._();

  static AttendanceRecord fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return AttendanceRecord(
      id: doc.id,
      studentId: (d['studentId'] ?? '') as String,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: EnumCodecs.attendanceFrom(d['status'] as String?),
    );
  }

  static Map<String, dynamic> toMap(AttendanceRecord r,
          {required String teacherId}) =>
      {
        'teacherId': teacherId,
        'studentId': r.studentId,
        'date': Timestamp.fromDate(r.date),
        'dateKey': Formatters.dateKey(r.date),
        'status': EnumCodecs.attendance(r.status),
      };
}
