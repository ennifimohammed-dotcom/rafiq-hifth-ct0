/// Shared domain enums.

enum SessionType { memorization, revision }

enum SessionRating { excellent, good, weak }

enum AttendanceStatus { present, absent, lateArrival }

extension SessionTypeX on SessionType {
  String get labelAr =>
      this == SessionType.memorization ? 'حفظ جديد' : 'مراجعة';
}

extension SessionRatingX on SessionRating {
  String get labelAr {
    switch (this) {
      case SessionRating.excellent:
        return 'ممتاز';
      case SessionRating.good:
        return 'جيد';
      case SessionRating.weak:
        return 'ضعيف';
    }
  }
}

extension AttendanceStatusX on AttendanceStatus {
  String get labelAr {
    switch (this) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absent:
        return 'غائب';
      case AttendanceStatus.lateArrival:
        return 'متأخر';
    }
  }
}
