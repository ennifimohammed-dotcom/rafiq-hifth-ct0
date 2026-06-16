/// Core student entity.
class Student {
  final String id;
  final String name;
  final int? age;
  final String? parentPhone;
  final int currentSurah;
  final int currentAyahStart;
  final int currentAyahEnd;
  final int totalAyahsMemorized;
  final double progressPercentage;
  final String? shareToken;
  final DateTime createdAt;

  const Student({
    required this.id,
    required this.name,
    this.age,
    this.parentPhone,
    this.currentSurah = 1,
    this.currentAyahStart = 1,
    this.currentAyahEnd = 1,
    this.totalAyahsMemorized = 0,
    this.progressPercentage = 0,
    this.shareToken,
    required this.createdAt,
  });

  Student copyWith({
    String? name,
    int? age,
    String? parentPhone,
    int? currentSurah,
    int? currentAyahStart,
    int? currentAyahEnd,
    int? totalAyahsMemorized,
    double? progressPercentage,
    String? shareToken,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      parentPhone: parentPhone ?? this.parentPhone,
      currentSurah: currentSurah ?? this.currentSurah,
      currentAyahStart: currentAyahStart ?? this.currentAyahStart,
      currentAyahEnd: currentAyahEnd ?? this.currentAyahEnd,
      totalAyahsMemorized: totalAyahsMemorized ?? this.totalAyahsMemorized,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      shareToken: shareToken ?? this.shareToken,
      createdAt: createdAt,
    );
  }
}
