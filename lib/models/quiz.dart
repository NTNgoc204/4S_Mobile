class QuizOption {
  final String id;
  final Map<String, String> label;
  final String profile;
  final Map<String, int> vector;

  const QuizOption({
    required this.id,
    required this.label,
    required this.profile,
    required this.vector,
  });
}

class QuizQuestion {
  final String id;
  final Map<String, String> prompt;
  final List<QuizOption> options;

  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });
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
    id: 'q01_activity',
    prompt: {
      'en': 'Which activity do you enjoy more?',
      'vi': 'Bạn thích tham gia hoạt động nào hơn?',
    },
    options: [
      QuizOption(
        id: 'academic_research',
        label: { 'en': 'Academic research', 'vi': 'Nghiên cứu học thuật' },
        profile: 'analytical',
        vector: { 'tech': 2, 'engineering': 2, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'art_performance',
        label: { 'en': 'Art performance', 'vi': 'Biểu diễn nghệ thuật' },
        profile: 'creative',
        vector: { 'creative': 3, 'social': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'social_activity',
        label: { 'en': 'Social activities', 'vi': 'Hoạt động xã hội' },
        profile: 'social',
        vector: { 'social': 3, 'business': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'technical_practice',
        label: { 'en': 'Technical hands-on practice', 'vi': 'Thực hành kỹ thuật' },
        profile: 'practical',
        vector: { 'engineering': 3, 'tech': 1, 'leftBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q02_learning_method',
    prompt: {
      'en': 'How do you usually learn most effectively?',
      'vi': 'Bạn thường học hiệu quả nhất bằng cách nào?',
    },
    options: [
      QuizOption(
        id: 'read_detailed_docs',
        label: { 'en': 'Read detailed documents', 'vi': 'Đọc tài liệu chi tiết' },
        profile: 'analytical',
        vector: { 'tech': 1, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'visual_examples',
        label: { 'en': 'Watch visual examples', 'vi': 'Xem ví dụ minh họa' },
        profile: 'creative',
        vector: { 'creative': 2, 'social': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'direct_practice',
        label: { 'en': 'Direct practice', 'vi': 'Thực hành trực tiếp' },
        profile: 'practical',
        vector: { 'engineering': 2, 'tech': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'group_discussion',
        label: { 'en': 'Group discussion', 'vi': 'Thảo luận nhóm' },
        profile: 'social',
        vector: { 'social': 2, 'business': 1, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q03_person_type',
    prompt: {
      'en': 'What type of person are you closer to?',
      'vi': 'Bạn thiên về kiểu người nào?',
    },
    options: [
      QuizOption(
        id: 'calm_thinker',
        label: { 'en': 'Calm and thoughtful', 'vi': 'Trầm tĩnh, hay suy nghĩ' },
        profile: 'analytical',
        vector: { 'tech': 1, 'business': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'dreamy_creative',
        label: { 'en': 'Dreamy and creative', 'vi': 'Bay bổng, sáng tạo' },
        profile: 'creative',
        vector: { 'creative': 3, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'outgoing_social',
        label: { 'en': 'Friendly and outgoing', 'vi': 'Hòa đồng, hướng ngoại' },
        profile: 'social',
        vector: { 'social': 3, 'business': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'practical_clear',
        label: { 'en': 'Practical and clear', 'vi': 'Thực tế, rõ ràng' },
        profile: 'practical',
        vector: { 'engineering': 2, 'business': 1, 'leftBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q04_tendency',
    prompt: {
      'en': 'When doing something, what is your natural tendency?',
      'vi': 'Khi làm điều gì đó, bạn có xu hướng như thế nào?',
    },
    options: [
      QuizOption(
        id: 'think_before_do',
        label: { 'en': 'Think before doing', 'vi': 'Suy nghĩ trước khi làm' },
        profile: 'analytical',
        vector: { 'tech': 1, 'business': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'follow_inspiration',
        label: { 'en': 'Act by inspiration', 'vi': 'Làm theo cảm hứng' },
        profile: 'creative',
        vector: { 'creative': 2, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'ask_others',
        label: { 'en': 'Ask others for input', 'vi': 'Hỏi ý kiến người khác' },
        profile: 'social',
        vector: { 'social': 2, 'business': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'act_immediately',
        label: { 'en': 'Take action right away', 'vi': 'Hành động ngay' },
        profile: 'action',
        vector: { 'engineering': 2, 'business': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q05_subject_strength',
    prompt: {
      'en': 'Which subject group do you feel stronger in?',
      'vi': 'Bạn cảm thấy mình nổi trội hơn ở nhóm môn nào?',
    },
    options: [
      QuizOption(
        id: 'calculation_analysis',
        label: { 'en': 'Calculation and data analysis', 'vi': 'Các môn tính toán và phân tích số liệu' },
        profile: 'analytical',
        vector: { 'tech': 2, 'engineering': 2, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'writing_argument_social',
        label: { 'en': 'Writing, argument, and social topics', 'vi': 'Các môn viết, lập luận và xã hội' },
        profile: 'social',
        vector: { 'social': 2, 'business': 2, 'rightBrain': 1, 'leftBrain': 1 },
      ),
      QuizOption(
        id: 'balanced_both',
        label: { 'en': 'Quite balanced between both groups', 'vi': 'Cả hai nhóm khá cân bằng' },
        profile: 'balanced',
        vector: { 'tech': 1, 'business': 1, 'engineering': 1, 'social': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'other_arts',
        label: { 'en': 'Other group (arts, ...)', 'vi': 'Nhóm môn khác (nghệ thuật,...)' },
        profile: 'creative',
        vector: { 'creative': 3, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q06_long_focus',
    prompt: {
      'en': 'Can you focus for a long duration easily?',
      'vi': 'Bạn có dễ tập trung trong thời gian dài không?',
    },
    options: [
      QuizOption(
        id: 'mental_work',
        label: { 'en': 'Very easy in cognitive work', 'vi': 'Rất dễ khi làm việc trí óc' },
        profile: 'analytical',
        vector: { 'tech': 1, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'interesting_content',
        label: { 'en': 'Easy when the content is interesting', 'vi': 'Dễ khi nội dung thú vị' },
        profile: 'creative',
        vector: { 'creative': 2, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'physical_activity',
        label: { 'en': 'Easy with hands-on activity', 'vi': 'Dễ khi có hoạt động tay chân' },
        profile: 'practical',
        vector: { 'engineering': 2, 'tech': 1, 'leftBrain': 1 },
      ),
      QuizOption(
        id: 'interactive_context',
        label: { 'en': 'Easy with interaction', 'vi': 'Dễ khi có người tương tác' },
        profile: 'social',
        vector: { 'social': 2, 'business': 1, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q07_self_study',
    prompt: {
      'en': 'How good are you at self-learning?',
      'vi': 'Bạn có khả năng tự học tốt không?',
    },
    options: [
      QuizOption(
        id: 'very_good_disciplined',
        label: { 'en': 'Very good and disciplined', 'vi': 'Rất tốt và kỷ luật' },
        profile: 'analytical',
        vector: { 'tech': 1, 'business': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'good_when_interested',
        label: { 'en': 'Good when interested', 'vi': 'Tốt khi có hứng thú' },
        profile: 'creative',
        vector: { 'creative': 2, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'good_with_practical_mentor',
        label: { 'en': 'Good with practical guidance', 'vi': 'Tốt khi có người hướng dẫn thực tế' },
        profile: 'practical',
        vector: { 'engineering': 2, 'social': 1, 'leftBrain': 1 },
      ),
      QuizOption(
        id: 'good_with_partner',
        label: { 'en': 'Good with a learning partner', 'vi': 'Tốt khi có bạn đồng hành' },
        profile: 'social',
        vector: { 'social': 2, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q08_planning_style',
    prompt: {
      'en': 'How do you usually plan?',
      'vi': 'Bạn thường lập kế hoạch như thế nào?',
    },
    options: [
      QuizOption(
        id: 'very_detailed_plan',
        label: { 'en': 'Very detailed plan', 'vi': 'Lập rất chi tiết' },
        profile: 'analytical',
        vector: { 'business': 2, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'main_framework_plan',
        label: { 'en': 'Plan by main framework', 'vi': 'Lập khung chính' },
        profile: 'balanced',
        vector: { 'business': 2, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'plan_as_you_go',
        label: { 'en': 'Figure out while doing', 'vi': 'Làm đến đâu tính đến đó' },
        profile: 'action',
        vector: { 'engineering': 1, 'creative': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'group_planning',
        label: { 'en': 'Plan with the team', 'vi': 'Lập cùng nhóm' },
        profile: 'social',
        vector: { 'social': 2, 'business': 1, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q09_content_preference',
    prompt: {
      'en': 'What type of content do you enjoy reading most?',
      'vi': 'Bạn thích đọc nội dung nào nhất?',
    },
    options: [
      QuizOption(
        id: 'science_tech',
        label: { 'en': 'Science and technology', 'vi': 'Khoa học và công nghệ' },
        profile: 'analytical',
        vector: { 'tech': 2, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'culture_arts',
        label: { 'en': 'Culture and arts', 'vi': 'Văn hóa và nghệ thuật' },
        profile: 'creative',
        vector: { 'creative': 2, 'social': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'health_lifestyle',
        label: { 'en': 'Health and lifestyle', 'vi': 'Sức khỏe và đời sống' },
        profile: 'balanced',
        vector: { 'social': 1, 'creative': 1, 'business': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'business_society',
        label: { 'en': 'Business and society', 'vi': 'Kinh doanh và xã hội' },
        profile: 'social',
        vector: { 'business': 3, 'social': 2, 'rightBrain': 1, 'leftBrain': 1 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q10_fastest_learning',
    prompt: {
      'en': 'When do you learn fastest?',
      'vi': 'Bạn học nhanh nhất khi nào?',
    },
    options: [
      QuizOption(
        id: 'clear_formula',
        label: { 'en': 'When there is a clear formula', 'vi': 'Khi có công thức rõ ràng' },
        profile: 'analytical',
        vector: { 'tech': 1, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'illustrated_example',
        label: { 'en': 'When there are illustrated examples', 'vi': 'Khi có ví dụ minh họa' },
        profile: 'creative',
        vector: { 'creative': 2, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'through_practice',
        label: { 'en': 'When practicing directly', 'vi': 'Khi được thực hành' },
        profile: 'practical',
        vector: { 'engineering': 2, 'tech': 1, 'leftBrain': 1 },
      ),
      QuizOption(
        id: 'through_discussion',
        label: { 'en': 'When discussing with others', 'vi': 'Khi được thảo luận' },
        profile: 'social',
        vector: { 'social': 2, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q11_decision_basis',
    prompt: {
      'en': 'What do you rely on when making decisions?',
      'vi': 'Khi ra quyết định, bạn dựa vào điều gì?',
    },
    options: [
      QuizOption(
        id: 'logic_basis',
        label: { 'en': 'Logic', 'vi': 'Logic' },
        profile: 'analytical',
        vector: { 'tech': 1, 'business': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'emotion_basis',
        label: { 'en': 'Emotion', 'vi': 'Cảm xúc' },
        profile: 'creative',
        vector: { 'creative': 2, 'social': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'experience_basis',
        label: { 'en': 'Experience', 'vi': 'Trải nghiệm' },
        profile: 'practical',
        vector: { 'engineering': 1, 'business': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'collective_basis',
        label: { 'en': 'Collective opinion', 'vi': 'Tập thể' },
        profile: 'social',
        vector: { 'social': 3, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q12_confident_subject',
    prompt: {
      'en': 'Which subject makes you most confident in surprise tests?',
      'vi': 'Môn nào khiến bạn tự tin khi kiểm tra đột xuất?',
    },
    options: [
      QuizOption(
        id: 'natural_subjects',
        label: { 'en': 'Natural sciences', 'vi': 'Các môn tự nhiên' },
        profile: 'analytical',
        vector: { 'tech': 2, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'social_subjects',
        label: { 'en': 'Social subjects', 'vi': 'Các môn xã hội' },
        profile: 'social',
        vector: { 'social': 2, 'business': 1, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'practical_subjects',
        label: { 'en': 'Practice-based subjects', 'vi': 'Môn có thực hành' },
        profile: 'practical',
        vector: { 'engineering': 2, 'tech': 1, 'leftBrain': 1 },
      ),
      QuizOption(
        id: 'other_language',
        label: { 'en': 'Other foreign languages (e.g., Japanese, ...)', 'vi': 'Môn ngoại ngữ khác (Tiếng Nhật,...)' },
        profile: 'balanced',
        vector: { 'social': 1, 'creative': 1, 'business': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q13_concentration_pattern',
    prompt: {
      'en': 'How does your concentration usually work?',
      'vi': 'Bạn có khả năng tập trung như thế nào?',
    },
    options: [
      QuizOption(
        id: 'many_hours',
        label: { 'en': 'Many continuous hours', 'vi': 'Nhiều giờ liên tục' },
        profile: 'analytical',
        vector: { 'tech': 1, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'when_interested',
        label: { 'en': 'When I am interested', 'vi': 'Khi có hứng thú' },
        profile: 'creative',
        vector: { 'creative': 2, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'with_specific_goal',
        label: { 'en': 'When I have a specific goal', 'vi': 'Khi có mục tiêu cụ thể' },
        profile: 'practical',
        vector: { 'business': 2, 'engineering': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'with_other_people',
        label: { 'en': 'When working with others', 'vi': 'Khi làm cùng người khác' },
        profile: 'social',
        vector: { 'social': 2, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q14_long_text_strategy',
    prompt: {
      'en': 'When facing a very long text, what do you do first?',
      'vi': 'Gặp một bài dài ngoằng nhìn muốn xỉu, bạn sẽ làm gì?',
    },
    options: [
      QuizOption(
        id: 'highlight_analyze',
        label: { 'en': 'Highlight then analyze each point', 'vi': 'Highlight rồi phân tích từng ý' },
        profile: 'analytical',
        vector: { 'tech': 1, 'business': 1, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'read_then_summarize',
        label: {
          'en': 'Read all first then summarize in my own words',
          'vi': 'Đọc xong hết rồi tự tóm tắt lại theo cách hiểu',
        },
        profile: 'balanced',
        vector: { 'business': 1, 'creative': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'find_apply_first',
        label: {
          'en': 'Pick usable info first and apply immediately',
          'vi': 'Tìm thông tin nào trước thì áp dụng làm trước',
        },
        profile: 'practical',
        vector: { 'engineering': 2, 'business': 1, 'leftBrain': 1 },
      ),
      QuizOption(
        id: 'discuss_with_others',
        label: { 'en': 'Ask others to discuss and reduce overload', 'vi': 'Rủ người khác bàn cho đỡ ngợp' },
        profile: 'social',
        vector: { 'social': 2, 'rightBrain': 2 },
      ),
    ],
  ),
  QuizQuestion(
    id: 'q15_many_tasks',
    prompt: {
      'en': 'When too many tasks come at once, what do you do?',
      'vi': 'Khi có quá nhiều việc cùng lúc, bạn sẽ làm gì?',
    },
    options: [
      QuizOption(
        id: 'prioritize',
        label: { 'en': 'Prioritize by importance', 'vi': 'Sắp xếp theo mức ưu tiên' },
        profile: 'analytical',
        vector: { 'business': 2, 'leftBrain': 2 },
      ),
      QuizOption(
        id: 'do_favorite_first',
        label: { 'en': 'Do what I like first', 'vi': 'Làm cái mình thích trước' },
        profile: 'creative',
        vector: { 'creative': 2, 'rightBrain': 2 },
      ),
      QuizOption(
        id: 'do_easy_first',
        label: { 'en': 'Do the easiest task first', 'vi': 'Làm cái dễ trước' },
        profile: 'action',
        vector: { 'engineering': 1, 'business': 1, 'leftBrain': 1, 'rightBrain': 1 },
      ),
      QuizOption(
        id: 'ask_for_support',
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
