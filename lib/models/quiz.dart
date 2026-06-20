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

class QuestionCategory {
  final String id;
  final String name;
  final int displayOrder;

  const QuestionCategory({
    required this.id,
    required this.name,
    this.displayOrder = 0,
  });

  factory QuestionCategory.fromApi(Map<String, dynamic> json) {
    return QuestionCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class QuizQuestion {
  final String id;
  final Map<String, String> prompt;
  final List<QuizOption> options;
  final int displayOrder;
  final String? categoryId;
  final String? categoryName;

  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    this.displayOrder = 0,
    this.categoryId,
    this.categoryName,
  });

  factory QuizQuestion.fromApi(
    Map<String, dynamic> json,
    List<Map<String, dynamic>> options, {
    String? categoryName,
  }) {
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

    final parsedOptions = questionOptions.map(QuizOption.fromApi).toList();
    final hasOther = parsedOptions.any((o) {
      final labelVi = (o.label['vi'] ?? '').trim().toLowerCase();
      return labelVi == 'khác' || o.id.startsWith('custom_other_');
    });

    if (!hasOther) {
      parsedOptions.add(QuizOption(
        id: 'custom_other_$questionId',
        label: const {'vi': 'Khác', 'en': 'Other'},
        profile: 'balanced',
        vector: const {'leftBrain': 0, 'rightBrain': 0},
      ));
    }

    return QuizQuestion(
      id: questionId,
      prompt: {'en': content, 'vi': content},
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      categoryId: json['categoryId']?.toString() ?? json['CategoryId']?.toString(),
      categoryName: categoryName ?? json['categoryName']?.toString() ?? json['CategoryName']?.toString(),
      options: parsedOptions,
    );
  }
}

bool isOptionActuallyOther(QuizOption option) {
  final labelVi = (option.label['vi'] ?? '').trim().toLowerCase();
  return labelVi == 'khác' || option.id.startsWith('custom_other_');
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

class AiUniversityRecommendation {
  final String id;
  final Map<String, String> name;
  final Map<String, String> major;
  final Map<String, String> place;
  final int matchPercent;
  final String tier; // 'top3' or 'next5'

  const AiUniversityRecommendation({
    required this.id,
    required this.name,
    required this.major,
    required this.place,
    required this.matchPercent,
    required this.tier,
  });

  factory AiUniversityRecommendation.fromJson(Map<String, dynamic> json, String tier) {
    dynamic readProperty(String camelCaseKey, String pascalCaseKey) {
      return json[camelCaseKey] ?? json[pascalCaseKey];
    }

    final id = (readProperty('universityId', 'UniversityId') ?? readProperty('id', 'Id') ?? '').toString();
    final nameVal = (readProperty('name', 'Name') ?? '').toString();
    final shortNameVal = (readProperty('shortName', 'ShortName') ?? '').toString();
    final locationVal = (readProperty('location', 'Location') ?? '').toString();

    final majorsRaw = readProperty('suitableMajors', 'SuitableMajors');
    final List<dynamic> majorsList = majorsRaw is List ? majorsRaw : [];
    final majorNames = majorsList
        .map((m) => (m is Map ? (m['name'] ?? m['Name'] ?? '') : m).toString().trim())
        .where((n) => n.isNotEmpty)
        .join(', ');

    final matchRaw = readProperty('matchPercentage', 'MatchPercentage');
    int matchVal = 0;
    if (matchRaw != null) {
      final parsed = num.tryParse(matchRaw.toString());
      if (parsed != null) {
        matchVal = parsed.clamp(0, 100).round();
      }
    }

    return AiUniversityRecommendation(
      id: id,
      name: {
        'vi': nameVal,
        'en': shortNameVal.isNotEmpty ? shortNameVal : nameVal,
      },
      major: {
        'vi': majorNames,
        'en': majorNames,
      },
      place: {
        'vi': locationVal,
        'en': locationVal,
      },
      matchPercent: matchVal,
      tier: tier,
    );
  }
}

