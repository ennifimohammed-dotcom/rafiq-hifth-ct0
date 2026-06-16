/// Global application constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'معلم القرآن';

  /// Base URL used to build shareable parent report links.
  /// Replace with your hosted web domain (e.g. Firebase Hosting).
  static const String reportBaseUrl = 'https://quran-tracker.web.app/report/';

  /// Total number of ayahs in the Quran (Hafs).
  static const int totalQuranAyahs = 6236;

  /// Quick-pick mistake categories for fast session input.
  static const List<String> mistakePresets = [
    'تجويد',
    'نسيان',
    'تشكيل',
    'تردد',
    'إبدال كلمة',
    'مخارج الحروف',
  ];
}
