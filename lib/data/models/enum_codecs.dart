import '../../domain/entities/enums.dart';

/// String <-> enum codecs used by Firestore mappers.
class EnumCodecs {
  EnumCodecs._();

  static String sessionType(SessionType t) => t.name;
  static SessionType sessionTypeFrom(String? s) => SessionType.values
      .firstWhere((e) => e.name == s, orElse: () => SessionType.memorization);

  static String rating(SessionRating r) => r.name;
  static SessionRating ratingFrom(String? s) => SessionRating.values
      .firstWhere((e) => e.name == s, orElse: () => SessionRating.good);

  static String attendance(AttendanceStatus a) => a.name;
  static AttendanceStatus attendanceFrom(String? s) =>
      AttendanceStatus.values.firstWhere((e) => e.name == s,
          orElse: () => AttendanceStatus.present);
}
