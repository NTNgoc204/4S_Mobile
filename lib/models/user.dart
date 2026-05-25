class UserProfile {
  String email;
  String fullName;
  String dateOfBirth;
  String address;
  String phoneNumber;

  // Academic Profile
  double gpa;
  double mathScore;
  double englishScore;
  double scienceScore;

  // Preferences
  String preferredLocation;
  double maxTuition; // in million VND/year
  String studyMode; // 'Vietnamese' or 'English'
  String language; // 'vi' or 'en'

  // Plan: 'free', 'pro', 'edu'
  String currentPlan;

  UserProfile({
    required this.email,
    required this.fullName,
    required this.dateOfBirth,
    required this.address,
    required this.phoneNumber,
    this.gpa = 7.5,
    this.mathScore = 75,
    this.englishScore = 70,
    this.scienceScore = 65,
    this.preferredLocation = 'TP. Hồ Chí Minh',
    this.maxTuition = 50.0,
    this.studyMode = 'Tiếng Việt',
    this.language = 'vi',
    this.currentPlan = 'free',
  });

  UserProfile copyWith({
    String? email,
    String? fullName,
    String? dateOfBirth,
    String? address,
    String? phoneNumber,
    double? gpa,
    double? mathScore,
    double? englishScore,
    double? scienceScore,
    String? preferredLocation,
    double? maxTuition,
    String? studyMode,
    String? language,
    String? currentPlan,
  }) {
    return UserProfile(
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gpa: gpa ?? this.gpa,
      mathScore: mathScore ?? this.mathScore,
      englishScore: englishScore ?? this.englishScore,
      scienceScore: scienceScore ?? this.scienceScore,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      maxTuition: maxTuition ?? this.maxTuition,
      studyMode: studyMode ?? this.studyMode,
      language: language ?? this.language,
      currentPlan: currentPlan ?? this.currentPlan,
    );
  }
}
