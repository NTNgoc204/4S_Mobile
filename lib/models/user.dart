class UserProfile {
  String userId;
  String email;
  String fullName;
  String dateOfBirth;
  String address;
  String phoneNumber;
  String role;
  String avatarUrl;

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
    this.userId = '',
    required this.email,
    required this.fullName,
    required this.dateOfBirth,
    required this.address,
    required this.phoneNumber,
    this.role = '',
    this.avatarUrl = '',
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

  factory UserProfile.fromMeResponse(Map<String, dynamic> json) {
    final email = _asString(json['email']);
    final username = _asString(json['username']);
    final dob = _asDateString(json['dob'] ?? json['DOB']);
    final currentPlan = _asString(json['currentPlan']).toLowerCase();

    return UserProfile(
      userId: _asString(json['userId']),
      email: email,
      fullName: username.isNotEmpty ? username : email,
      dateOfBirth: dob,
      address: _asString(json['address']),
      phoneNumber: _asString(json['phoneNumber']),
      role: _asString(json['role']),
      avatarUrl: _asString(json['avatarUrl'] ?? json['AvatarUrl']),
      currentPlan: currentPlan.isNotEmpty ? currentPlan : 'free',
    );
  }

  UserProfile copyWith({
    String? userId,
    String? email,
    String? fullName,
    String? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? role,
    String? avatarUrl,
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
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gpa: gpa ?? this.gpa,
      mathScore: mathScore ?? this.mathScore,
      englishScore: englishScore ?? this.englishScore,
      scienceScore: scienceScore ?? this.scienceScore,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      maxTuition: maxTuition ?? this.maxTuition,
      studyMode: studyMode ?? this.studyMode,
      language: language ?? this.language,
      currentPlan: (currentPlan ?? this.currentPlan).toLowerCase(),
    );
  }

  static String _asString(Object? value) {
    return value?.toString() ?? '';
  }

  static String _asDateString(Object? value) {
    if (value == null) return '';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    final year = parsed.year.toString().padLeft(4, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
