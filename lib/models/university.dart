class University {
  final String id;
  final Map<String, String> name;
  final Map<String, String> major;
  final Map<String, String> place;
  final Map<String, String> tuition;
  final Map<String, int> affinity;
  final Map<String, Map<String, String>> stats;

  const University({
    required this.id,
    required this.name,
    required this.major,
    required this.place,
    required this.tuition,
    required this.affinity,
    required this.stats,
  });
}

class UniversityWithScore extends University {
  final int score;

  UniversityWithScore({
    required super.id,
    required super.name,
    required super.major,
    required super.place,
    required super.tuition,
    required super.affinity,
    required super.stats,
    required this.score,
  });

  factory UniversityWithScore.fromUniversity(University u, int score) {
    return UniversityWithScore(
      id: u.id,
      name: u.name,
      major: u.major,
      place: u.place,
      tuition: u.tuition,
      affinity: u.affinity,
      stats: u.stats,
      score: score,
    );
  }
}

const List<University> universities = [
  University(
    id: "hcmut",
    name: { "en": "HCMC University of Technology", "vi": "ĐH Bách Khoa TP.HCM" },
    major: { "en": "Technology - Engineering", "vi": "Khối ngành Công nghệ - Kỹ thuật" },
    place: { "en": "Ho Chi Minh City", "vi": "TP. Hồ Chí Minh" },
    tuition: { "en": "15-25M VND/semester", "vi": "15-25M VNĐ/học kỳ" },
    affinity: { "tech": 4, "engineering": 4, "business": 1, "creative": 1, "social": 1 },
    stats: {
      "students": { "en": "25,000+ students", "vi": "25,000+ sinh viên" },
      "rank": { "en": "Top 5 in Vietnam", "vi": "Top 5 tại Việt Nam" },
    },
  ),
  University(
    id: "hust",
    name: { "en": "Hanoi University of Science and Technology", "vi": "ĐH Bách Khoa Hà Nội" },
    major: { "en": "Engineering & Applied Science", "vi": "Kỹ thuật và Công nghệ ứng dụng" },
    place: { "en": "Ha Noi", "vi": "Hà Nội" },
    tuition: { "en": "18-28M VNĐ/semester", "vi": "18-28M VNĐ/học kỳ" },
    affinity: { "tech": 3, "engineering": 4, "business": 1, "creative": 1, "social": 1 },
    stats: {
      "students": { "en": "35,000+ students", "vi": "35,000+ sinh viên" },
      "rank": { "en": "Top 3 in Vietnam", "vi": "Top 3 tại Việt Nam" },
    },
  ),
  University(
    id: "ftu",
    name: { "en": "Foreign Trade University", "vi": "ĐH Ngoại Thương" },
    major: { "en": "International Business", "vi": "Kinh tế đối ngoại" },
    place: { "en": "Ha Noi", "vi": "Hà Nội" },
    tuition: { "en": "14-22M VNĐ/semester", "vi": "14-22M VNĐ/học kỳ" },
    affinity: { "tech": 1, "engineering": 1, "business": 4, "creative": 2, "social": 3 },
    stats: {
      "students": { "en": "20,000+ students", "vi": "20,000+ sinh viên" },
      "rank": { "en": "Top Business School", "vi": "Top trường khối kinh tế" },
    },
  ),
  University(
    id: "rmit",
    name: { "en": "RMIT Vietnam", "vi": "RMIT Việt Nam" },
    major: { "en": "Business, Media & Design", "vi": "Kinh doanh, Truyền thông, Thiết kế" },
    place: { "en": "HCMC & Ha Noi", "vi": "TP.HCM & Hà Nội" },
    tuition: { "en": "70-95M VNĐ/semester", "vi": "70-95M VNĐ/học kỳ" },
    affinity: { "tech": 2, "engineering": 1, "business": 3, "creative": 4, "social": 3 },
    stats: {
      "students": { "en": "12,000+ students", "vi": "12,000+ sinh viên" },
      "rank": { "en": "Top International Program", "vi": "Top chương trình quốc tế" },
    },
  ),
];

const List<String> scoreKeys = ["tech", "business", "engineering", "creative", "social"];

List<UniversityWithScore> rankUniversities(Map<String, int> profile) {
  return universities.map((school) {
    int weighted = 0;
    for (var key in scoreKeys) {
      weighted += (profile[key] ?? 0) * (school.affinity[key] ?? 0);
    }
    // Calculate match score
    int score = (68 + weighted / 2.4).round();
    if (score < 68) score = 68;
    if (score > 97) score = 97;
    return UniversityWithScore.fromUniversity(school, score);
  }).toList()..sort((a, b) => b.score.compareTo(a.score));
}
