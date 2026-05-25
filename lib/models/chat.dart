class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? kind; // 'welcome', 'assistant_demo', 'assistant_recommendation_detail'
  final String? schoolId;
  final List<String>? strengthKeys;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.kind,
    this.schoolId,
    this.strengthKeys,
  });
}

class KeywordRule {
  final RegExp pattern;
  final Map<String, int> delta;

  KeywordRule(String patternStr, this.delta)
      : pattern = RegExp(patternStr, caseSensitive: false);
}

final List<KeywordRule> keywordRules = [
  KeywordRule(
      r'(tech|it|computer|ai|software|code|programming|engineering|lập trình|công nghệ|máy tính|kỹ thuật)',
      { 'tech': 2, 'engineering': 1 }),
  KeywordRule(
      r'(business|economics|finance|marketing|startup|kinh doanh|kinh tế|tài chính|khởi nghiệp|quản trị)',
      { 'business': 2, 'social': 1 }),
  KeywordRule(
      r'(design|media|art|creative|ui|ux|nghệ thuật|thiết kế|truyền thông|sáng tạo)',
      { 'creative': 2, 'social': 1 }),
  KeywordRule(
      r'(communication|team|social|psychology|xã hội|giao tiếp|nhóm|tâm lý|con người|hướng ngoại)',
      { 'social': 2, 'business': 1 }),
  KeywordRule(
      r'(scholarship|tuition|budget|cost|học phí|chi phí|ngân sách|học bổng|rẻ|dưới|under)',
      { 'business': 1, 'social': 1 }),
];

Map<String, int> extractDeltaFromMessage(String message) {
  Map<String, int> delta = {};
  bool matched = false;

  for (var rule in keywordRules) {
    if (rule.pattern.hasMatch(message)) {
      matched = true;
      rule.delta.forEach((key, value) {
        delta[key] = (delta[key] ?? 0) + value;
      });
    }
  }

  if (!matched) {
    return { 'social': 1, 'business': 1 };
  }

  return delta;
}

const Map<String, String> focusLabelsVi = {
  'tech': 'công nghệ và máy tính',
  'business': 'kinh doanh và thị trường',
  'engineering': 'kỹ thuật và giải quyết vấn đề thực tế',
  'creative': 'sáng tạo, truyền thông và thiết kế',
  'social': 'giao tiếp, con người và tác động xã hội',
};

const Map<String, String> focusLabelsEn = {
  'tech': 'technology and computing',
  'business': 'business and market orientation',
  'engineering': 'engineering and practical problem-solving',
  'creative': 'creative and media-oriented fields',
  'social': 'communication and social impact areas',
};
