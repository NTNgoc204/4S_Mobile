class QuizOption {
  final String id;
  final Map<String, String> label;
  final String profile;
  final Map<String, int> vector;
  final String answerValue;
  final String? optionCode;
  final String? scoreTag;

  const QuizOption({
    required this.id,
    required this.label,
    required this.profile,
    required this.vector,
    String? answerValue,
    this.optionCode,
    this.scoreTag,
  }) : answerValue = answerValue ?? id;

  factory QuizOption.fromApi(Map<String, dynamic> json) {
    final inferred = inferOptionProfile(json);
    final content = json['content']?.toString() ?? '';
    final id = json['id']?.toString() ?? '';

    return QuizOption(
      id: id,
      answerValue: id,
      optionCode: json['optionCode']?.toString(),
      scoreTag: json['scoreTag']?.toString(),
      label: {'en': content, 'vi': content},
      profile: inferred.profile,
      vector: inferred.vector,
    );
  }
}

class QuizQuestion {
  final String id;
  final Map<String, String> prompt;
  final List<QuizOption> options;
  final int displayOrder;

  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    this.displayOrder = 0,
  });

  factory QuizQuestion.fromApi(
    Map<String, dynamic> json,
    List<Map<String, dynamic>> options,
  ) {
    final questionId = json['id']?.toString() ?? '';
    final content = json['content']?.toString() ?? '';
    final questionOptions = options
        .where((option) => option['questionId']?.toString() == questionId)
        .toList()
      ..sort(
        (a, b) => ((a['displayOrder'] as num?)?.toInt() ?? 0).compareTo(
          ((b['displayOrder'] as num?)?.toInt() ?? 0),
        ),
      );

    return QuizQuestion(
      id: questionId,
      prompt: {'en': content, 'vi': content},
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      options: questionOptions.map(QuizOption.fromApi).toList(),
    );
  }
}

class OptionProfile {
  final String profile;
  final Map<String, int> vector;

  const OptionProfile({required this.profile, required this.vector});
}

const Map<String, OptionProfile> optionCodeProfiles = {
  'A': OptionProfile(profile: 'practical', vector: {'engineering': 3, 'tech': 1, 'leftBrain': 1}),
  'B': OptionProfile(profile: 'analytical', vector: {'tech': 2, 'engineering': 2, 'leftBrain': 2}),
  'C': OptionProfile(profile: 'creative', vector: {'creative': 3, 'rightBrain': 2}),
  'D': OptionProfile(profile: 'social', vector: {'social': 3, 'rightBrain': 2}),
  'E': OptionProfile(profile: 'action', vector: {'business': 3, 'social': 1, 'leftBrain': 1}),
  'F': OptionProfile(profile: 'balanced', vector: {'business': 1, 'tech': 1, 'social': 1, 'leftBrain': 1, 'rightBrain': 1}),
  'G': OptionProfile(profile: 'balanced', vector: {'creative': 1, 'social': 1, 'leftBrain': 1, 'rightBrain': 1}),
};

const Map<String, OptionProfile> scoreTagProfiles = {
  'analytical': OptionProfile(profile: 'analytical', vector: {'tech': 2, 'engineering': 2, 'leftBrain': 2}),
  'creative': OptionProfile(profile: 'creative', vector: {'creative': 3, 'rightBrain': 2}),
  'social': OptionProfile(profile: 'social', vector: {'social': 3, 'rightBrain': 2}),
  'practical': OptionProfile(profile: 'practical', vector: {'engineering': 3, 'tech': 1, 'leftBrain': 1}),
  'business': OptionProfile(profile: 'action', vector: {'business': 3, 'social': 1, 'leftBrain': 1}),
  'balanced': OptionProfile(profile: 'balanced', vector: {'business': 1, 'tech': 1, 'social': 1, 'leftBrain': 1, 'rightBrain': 1}),
  'action': OptionProfile(profile: 'action', vector: {'business': 3, 'social': 1, 'leftBrain': 1}),
  'tech': OptionProfile(profile: 'analytical', vector: {'tech': 3, 'engineering': 1, 'leftBrain': 2}),
  'engineering': OptionProfile(profile: 'practical', vector: {'engineering': 3, 'tech': 1, 'leftBrain': 2}),
};

OptionProfile inferOptionProfile(Map<String, dynamic> option) {
  final scoreTag = option['scoreTag']?.toString().trim().toLowerCase();
  if (scoreTag != null && scoreTagProfiles.containsKey(scoreTag)) {
    return scoreTagProfiles[scoreTag]!;
  }

  final content = option['content']?.toString().toLowerCase() ?? '';
  if (content.contains('nghiên cứu') || content.contains('dữ liệu') || content.contains('phân tích')) {
    return optionCodeProfiles['B']!;
  }
  if (content.contains('vẽ') || content.contains('thiết kế') || content.contains('sáng tạo')) {
    return optionCodeProfiles['C']!;
  }
  if (content.contains('hỗ trợ') || content.contains('hướng dẫn') || content.contains('giúp đỡ')) {
    return optionCodeProfiles['D']!;
  }
  if (content.contains('kinh doanh') || content.contains('lãnh đạo') || content.contains('thuyết phục')) {
    return optionCodeProfiles['E']!;
  }
  if (content.contains('sắp xếp') || content.contains('quản lý')) {
    return optionCodeProfiles['F']!;
  }

  final code = option['optionCode']?.toString().trim().toUpperCase();
  return optionCodeProfiles[code] ?? optionCodeProfiles['F']!;
}

const Map<String, Map<String, Map<String, String>>> insightProfiles = {
  'analytical': {
    'personality': {
      'en': 'analytical, structured, and logic-driven',
      'vi': 'phân tích tốt, có cấu trúc và thiên về logic',
    },
    'interest': {
      'en': 'clear frameworks, data, and measurable outcomes',
      'vi': 'khung kiến thức rõ ràng, dữ liệu và kết quả đo lường được',
    },
    'brain': {
      'en': 'left-brain dominant',
      'vi': 'thiên về bán cầu não trái',
    },
  },
  'creative': {
    'personality': {
      'en': 'creative, intuitive, and expressive',
      'vi': 'sáng tạo, trực giác tốt và giàu biểu đạt',
    },
    'interest': {
      'en': 'ideas, visuals, and new perspectives',
      'vi': 'ý tưởng mới, trực quan và góc nhìn khác biệt',
    },
    'brain': {
      'en': 'right-brain dominant',
      'vi': 'thiên về bán cầu não phải',
    },
  },
  'social': {
    'personality': {
      'en': 'social, collaborative, and people-oriented',
      'vi': 'hướng ngoại, hợp tác tốt và thiên về con người',
    },
    'interest': {
      'en': 'communication, teamwork, and collective growth',
      'vi': 'giao tiếp, phối hợp và phát triển tập thể',
    },
    'brain': {
      'en': 'right-brain social tendency',
      'vi': 'xu hướng xã hội thiên về bán cầu não phải',
    },
  },
  'practical': {
    'personality': {
      'en': 'practical, grounded, and execution-focused',
      'vi': 'thực tế, rõ ràng và tập trung thực thi',
    },
    'interest': {
      'en': 'hands-on application and solving real problems',
      'vi': 'ứng dụng thực hành và xử lý vấn đề thực tế',
    },
    'brain': {
      'en': 'slightly left-brain oriented',
      'vi': 'hơi nghiêng về bán cầu não trái',
    },
  },
  'balanced': {
    'personality': {
      'en': 'balanced between logic and intuition',
      'vi': 'cân bằng giữa lý trí và trực giác',
    },
    'interest': {
      'en': 'combining analysis with flexibility',
      'vi': 'kết hợp phân tích với sự linh hoạt',
    },
    'brain': {
      'en': 'balanced left-right brain profile',
      'vi': 'cân bằng giữa hai bán cầu não',
    },
  },
  'action': {
    'personality': {
      'en': 'decisive, adaptive, and action-oriented',
      'vi': 'quyết đoán, linh hoạt và thiên hành động',
    },
    'interest': {
      'en': 'quick execution and rapid experimentation',
      'vi': 'thực thi nhanh và thử nghiệm liên tục',
    },
    'brain': {
      'en': 'flexible left-right usage',
      'vi': 'sử dụng linh hoạt hai bán cầu não',
    },
  },
};

const List<QuizQuestion> quizQuestions = [
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000001',
    prompt: {
      'en': 'Which activity do you enjoy more?',
      'vi': 'Bạn thích tham gia hoạt động nào hơn?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000011',
        label: { 'en': 'Academic research', 'vi': 'Nghiên cứu học thuật' },
        profile: 'analytical',
        vector: { 'tech': 2, 'engineering': 2, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000012',
        label: { 'en': 'Art performance', 'vi': 'Biểu diễn nghệ thuật' },
        profile: 'creative',
        vector: { 'creative': 3, 'social': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000013',
        label: { 'en': 'Social activities', 'vi': 'Hoạt động xã hội' },
        profile: 'social',
        vector: { 'social': 3, 'business': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000014',
        label: { 'en': 'Technical hands-on practice', 'vi': 'Thực hành kỹ thuật' },
        profile: 'practical',
        vector: { 'engineering': 3, 'tech': 1, 'leftBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000002',
    prompt: {
      'en': 'How do you usually learn most effectively?',
      'vi': 'Bạn thường học hiệu quả nhất bằng cách nào?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000021',
        label: { 'en': 'Read detailed documents', 'vi': 'Đọc tài liệu chi tiết' },
        profile: 'analytical',
        vector: { 'tech': 1, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000022',
        label: { 'en': 'Watch visual examples', 'vi': 'Xem ví dụ minh họa' },
        profile: 'creative',
        vector: { 'creative': 2, 'social': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000023',
        label: { 'en': 'Direct practice', 'vi': 'Thực hành trực tiếp' },
        profile: 'practical',
        vector: { 'engineering': 2, 'tech': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000024',
        label: { 'en': 'Group discussion', 'vi': 'Thảo luận nhóm' },
        profile: 'social',
        vector: { 'social': 2, 'business': 1, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000003',
    prompt: {
      'en': 'What type of person are you closer to?',
      'vi': 'Bạn thiên về kiểu người nào?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000031',
        label: { 'en': 'Calm and thoughtful', 'vi': 'Trầm tĩnh, hay suy nghĩ' },
        profile: 'analytical',
        vector: { 'tech': 1, 'business': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000032',
        label: { 'en': 'Dreamy and creative', 'vi': 'Bay bổng, sáng tạo' },
        profile: 'creative',
        vector: { 'creative': 3, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000033',
        label: { 'en': 'Friendly and outgoing', 'vi': 'Hòa đồng, hướng ngoại' },
        profile: 'social',
        vector: { 'social': 3, 'business': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000034',
        label: { 'en': 'Practical and clear', 'vi': 'Thực tế, rõ ràng' },
        profile: 'practical',
        vector: { 'engineering': 2, 'business': 1, 'leftBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000004',
    prompt: {
      'en': 'When doing something, what is your natural tendency?',
      'vi': 'Khi làm điều gì đó, bạn có xu hướng như thế nào?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000041',
        label: { 'en': 'Think before doing', 'vi': 'Suy nghĩ trước khi làm' },
        profile: 'analytical',
        vector: { 'tech': 1, 'business': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000042',
        label: { 'en': 'Act by inspiration', 'vi': 'Làm theo cảm hứng' },
        profile: 'creative',
        vector: { 'creative': 2, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000043',
        label: { 'en': 'Ask others for input', 'vi': 'Hỏi ý kiến người khác' },
        profile: 'social',
        vector: { 'social': 2, 'business': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000044',
        label: { 'en': 'Take action right away', 'vi': 'Hành động ngay' },
        profile: 'action',
        vector: { 'engineering': 2, 'business': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000005',
    prompt: {
      'en': 'Which subject group do you feel stronger in?',
      'vi': 'Bạn cảm thấy mình nổi trội hơn ở nhóm môn nào?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000051',
        label: { 'en': 'Calculation and data analysis', 'vi': 'Các môn tính toán và phân tích số liệu' },
        profile: 'analytical',
        vector: { 'tech': 2, 'engineering': 2, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000052',
        label: { 'en': 'Writing, argument, and social topics', 'vi': 'Các môn viết, lập luận và xã hội' },
        profile: 'social',
        vector: { 'social': 2, 'business': 2, 'rightBrain': 1, 'leftBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000053',
        label: { 'en': 'Quite balanced between both groups', 'vi': 'Cả hai nhóm khá cân bằng' },
        profile: 'balanced',
        vector: { 'tech': 1, 'business': 1, 'engineering': 1, 'social': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000054',
        label: { 'en': 'Other group (arts, ...)', 'vi': 'Nhóm môn khác (nghệ thuật,...)' },
        profile: 'creative',
        vector: { 'creative': 3, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000006',
    prompt: {
      'en': 'Can you focus for a long duration easily?',
      'vi': 'Bạn có dễ tập trung trong thời gian dài không?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000061',
        label: { 'en': 'Very easy in cognitive work', 'vi': 'Rất dễ khi làm việc trí óc' },
        profile: 'analytical',
        vector: { 'tech': 1, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000062',
        label: { 'en': 'Easy when the content is interesting', 'vi': 'Dễ khi nội dung thú vị' },
        profile: 'creative',
        vector: { 'creative': 2, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000063',
        label: { 'en': 'Easy with hands-on activity', 'vi': 'Dễ khi có hoạt động tay chân' },
        profile: 'practical',
        vector: { 'engineering': 2, 'tech': 1, 'leftBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000064',
        label: { 'en': 'Easy with interaction', 'vi': 'Dễ khi có người tương tác' },
        profile: 'social',
        vector: { 'social': 2, 'business': 1, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000007',
    prompt: {
      'en': 'How good are you at self-learning?',
      'vi': 'Bạn có khả năng tự học tốt không?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000071',
        label: { 'en': 'Very good and disciplined', 'vi': 'Rất tốt và kỷ luật' },
        profile: 'analytical',
        vector: { 'tech': 1, 'business': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000072',
        label: { 'en': 'Good when interested', 'vi': 'Tốt khi có hứng thú' },
        profile: 'creative',
        vector: { 'creative': 2, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000073',
        label: { 'en': 'Good with practical guidance', 'vi': 'Tốt khi có người hướng dẫn thực tế' },
        profile: 'practical',
        vector: { 'engineering': 2, 'social': 1, 'leftBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000074',
        label: { 'en': 'Good with a learning partner', 'vi': 'Tốt khi có bạn đồng hành' },
        profile: 'social',
        vector: { 'social': 2, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000008',
    prompt: {
      'en': 'How do you usually plan?',
      'vi': 'Bạn thường lập kế hoạch như thế nào?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000081',
        label: { 'en': 'Very detailed plan', 'vi': 'Lập rất chi tiết' },
        profile: 'analytical',
        vector: { 'business': 2, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000082',
        label: { 'en': 'Plan by main framework', 'vi': 'Lập khung chính' },
        profile: 'balanced',
        vector: { 'business': 2, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000083',
        label: { 'en': 'Figure out while doing', 'vi': 'Làm đến đâu tính đến đó' },
        profile: 'action',
        vector: { 'engineering': 1, 'creative': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000084',
        label: { 'en': 'Plan with the team', 'vi': 'Lập cùng nhóm' },
        profile: 'social',
        vector: { 'social': 2, 'business': 1, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000009',
    prompt: {
      'en': 'What type of content do you enjoy reading most?',
      'vi': 'Bạn thích đọc nội dung nào nhất?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000091',
        label: { 'en': 'Science and technology', 'vi': 'Khoa học và công nghệ' },
        profile: 'analytical',
        vector: { 'tech': 2, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000092',
        label: { 'en': 'Culture and arts', 'vi': 'Vàn hóa và nghệ thuật' },
        profile: 'creative',
        vector: { 'creative': 2, 'social': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000093',
        label: { 'en': 'Health and lifestyle', 'vi': 'Sức khỏe và đời sống' },
        profile: 'balanced',
        vector: { 'social': 1, 'creative': 1, 'business': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000094',
        label: { 'en': 'Business and society', 'vi': 'Kinh doanh và xã hội' },
        profile: 'social',
        vector: { 'business': 3, 'social': 2, 'rightBrain': 1, 'leftBrain': 1 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000010',
    prompt: {
      'en': 'When do you learn fastest?',
      'vi': 'Bạn học nhanh nhất khi nào?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000101',
        label: { 'en': 'When there is a clear formula', 'vi': 'Khi có công thức rõ ràng' },
        profile: 'analytical',
        vector: { 'tech': 1, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000102',
        label: { 'en': 'When there are illustrated examples', 'vi': 'Khi có ví dụ minh họa' },
        profile: 'creative',
        vector: { 'creative': 2, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000103',
        label: { 'en': 'When practicing directly', 'vi': 'Khi được thực hành' },
        profile: 'practical',
        vector: { 'engineering': 2, 'tech': 1, 'leftBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000104',
        label: { 'en': 'When discussing with others', 'vi': 'Khi được thảo luận' },
        profile: 'social',
        vector: { 'social': 2, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000011',
    prompt: {
      'en': 'What do you rely on when making decisions?',
      'vi': 'Khi ra quyết định, bạn dựa vào điều gì?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000111',
        label: { 'en': 'Logic', 'vi': 'Logic' },
        profile: 'analytical',
        vector: { 'tech': 1, 'business': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000112',
        label: { 'en': 'Emotion', 'vi': 'Cảm xúc' },
        profile: 'creative',
        vector: { 'creative': 2, 'social': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000113',
        label: { 'en': 'Experience', 'vi': 'Trải nghiệm' },
        profile: 'practical',
        vector: { 'engineering': 1, 'business': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000114',
        label: { 'en': 'Collective opinion', 'vi': 'Tập thể' },
        profile: 'social',
        vector: { 'social': 3, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000012',
    prompt: {
      'en': 'Which subject makes you most confident in surprise tests?',
      'vi': 'Môn nào khiến bạn tự tin khi kiểm tra đột xuất?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000121',
        label: { 'en': 'Natural sciences', 'vi': 'Các môn tự nhiên' },
        profile: 'analytical',
        vector: { 'tech': 2, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000122',
        label: { 'en': 'Social subjects', 'vi': 'Các môn xã hội' },
        profile: 'social',
        vector: { 'social': 2, 'business': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000123',
        label: { 'en': 'Practice-based subjects', 'vi': 'Môn có thực hành' },
        profile: 'practical',
        vector: { 'engineering': 2, 'tech': 1, 'leftBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000124',
        label: { 'en': 'Other foreign languages (e.g., Japanese, ...)', 'vi': 'Môn ngoại ngữ khác (Tiếng Nhật,...)' },
        profile: 'balanced',
        vector: { 'social': 1, 'creative': 1, 'business': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000013',
    prompt: {
      'en': 'How does your concentration usually work?',
      'vi': 'Bạn có khả năng tập trung như thế nào?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000131',
        label: { 'en': 'Many continuous hours', 'vi': 'Nhiều giờ liên tục' },
        profile: 'analytical',
        vector: { 'tech': 1, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000132',
        label: { 'en': 'When I am interested', 'vi': 'Khi có hứng thú' },
        profile: 'creative',
        vector: { 'creative': 2, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000133',
        label: { 'en': 'When I have a specific goal', 'vi': 'Khi có mục tiêu cụ thể' },
        profile: 'practical',
        vector: { 'business': 2, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000134',
        label: { 'en': 'When working with others', 'vi': 'Khi làm cùng người khác' },
        profile: 'social',
        vector: { 'social': 2, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000014',
    prompt: {
      'en': 'When facing a very long text, what do you do first?',
      'vi': 'Gặp một bài dài ngoằng nhìn muốn xỉu, bạn sẽ làm gì?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000141',
        label: { 'en': 'Highlight then analyze each point', 'vi': 'Highlight rồi phân tích từng ý' },
        profile: 'analytical',
        vector: { 'tech': 1, 'business': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000142',
        label: {
          'en': 'Read all first then summarize in my own words',
          'vi': 'Đọc xong hết rồi tự tóm tắt lại theo cách hiểu',
        },
        profile: 'balanced',
        vector: { 'business': 1, 'creative': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000143',
        label: {
          'en': 'Pick usable info first and apply immediately',
          'vi': 'Tìm thông tin nào trước thì áp dụng làm trước',
        },
        profile: 'practical',
        vector: { 'engineering': 2, 'business': 1, 'leftBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000144',
        label: { 'en': 'Ask others to discuss and reduce overload', 'vi': 'Rủ người khác bàn cho đỡ ngợp' },
        profile: 'social',
        vector: { 'social': 2, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'd0000000-0000-0000-0000-000000000015',
    prompt: {
      'en': 'When too many tasks come at once, what do you do?',
      'vi': 'Khi có quá nhiều việc cùng lúc, bạn sẽ làm gì?',
    },
    options: [
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000151',
        label: { 'en': 'Prioritize by importance', 'vi': 'Sắp xếp theo mức ưu tiên' },
        profile: 'analytical',
        vector: { 'business': 2, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000152',
        label: { 'en': 'Do what I like first', 'vi': 'Làm cái mình thích trước' },
        profile: 'creative',
        vector: { 'creative': 2, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000153',
        label: { 'en': 'Do the easiest task first', 'vi': 'Làm cái dễ trước' },
        profile: 'action',
        vector: { 'engineering': 1, 'business': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'd0000000-0000-0000-000a-000000000154',
        label: { 'en': 'Ask others for support', 'vi': 'Hỏi người khác hỗ trợ mình' },
        profile: 'social',
        vector: { 'social': 3, 'rightBrain': 2 },
      ),
    ],
  ),
];

String buildInsightText(QuizOption option, String locale) {
  final profileData = insightProfiles[option.profile] ?? insightProfiles['balanced']!;
  final personality = profileData['personality']![locale]!;
  final interest = profileData['interest']![locale]!;
  final brain = profileData['brain']![locale]!;

  if (locale == 'vi') {
    return 'Bạn có xu hướng $personality. Bạn phù hợp với $interest, và hiện tại $brain.';
  }
  return 'You are $personality. You show strong interest in $interest, and currently look $brain.';
}
