import 'package:flutter/material.dart';

import '../main.dart';
import '../models/quiz.dart';
import '../models/university.dart';
import '../services/api_client.dart';

class QuizTab extends StatefulWidget {
  const QuizTab({super.key});

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  List<QuizQuestion> _questions = quizQuestions;
  final Map<String, String> _answers = {};
  final Map<String, String> _insights = {};
  bool _isLoading = true;
  bool _isThinking = false;
  String? _loadError;
  String? _thinkingQuestionId;

  Map<String, int> _profile = _createEmptyProfile();

  static Map<String, int> _createEmptyProfile() => {
        'tech': 0,
        'business': 0,
        'engineering': 0,
        'creative': 0,
        'social': 0,
        'leftBrain': 0,
        'rightBrain': 0,
      };

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    List<QuizQuestion> loadedQuestions = [];
    List<Map<String, dynamic>> savedAnswerRows = [];

    // 1. Tải câu hỏi từ Backend
    try {
      final results = await Future.wait([
        ApiClient.instance.getQuestions(),
        ApiClient.instance.getQuestionOptions(),
      ]);

      final questionRows = results[0]
          .where((question) => question['isActice']?.toString() != 'No')
          .toList()
        ..sort(
          (a, b) => ((a['displayOrder'] as num?)?.toInt() ?? 0).compareTo(
            ((b['displayOrder'] as num?)?.toInt() ?? 0),
          ),
        );
      final optionRows = results[1];

      loadedQuestions = questionRows
          .map((question) => QuizQuestion.fromApi(question, optionRows))
          .where((question) => question.id.isNotEmpty && question.options.isNotEmpty)
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('Lỗi tải câu hỏi từ Backend: $e. Sử dụng bộ câu hỏi mặc định làm fallback.');
    }

    // Nếu tải từ backend rỗng hoặc lỗi, fallback về bộ câu hỏi mặc định có ID dạng Guid
    if (loadedQuestions.isEmpty) {
      loadedQuestions = List.from(quizQuestions);
    }

    // 2. Tải câu trả lời đã lưu từ Backend
    try {
      savedAnswerRows = await ApiClient.instance.getUserAnswers();
    } catch (e) {
      // ignore: avoid_print
      print('Lỗi tải câu trả lời đã lưu từ Backend: $e');
    }

    final restoredAnswers = _mapSavedAnswers(savedAnswerRows, loadedQuestions);
    final restoredProfile = _buildProfileFromAnswers(loadedQuestions, restoredAnswers);
    final restoredInsights = <String, String>{
      for (final questionId in restoredAnswers.keys)
        questionId: _buildInsightForAnswer(loadedQuestions, restoredAnswers, questionId),
    };

    if (!mounted) return;
    setState(() {
      _questions = loadedQuestions;
      _answers
        ..clear()
        ..addAll(restoredAnswers);
      _insights
        ..clear()
        ..addAll(restoredInsights);
      _profile = restoredProfile;
      _isLoading = false;
    });

    if (restoredAnswers.length == loadedQuestions.length && loadedQuestions.isNotEmpty) {
      AppState.of(context, listen: false).completeQuiz(restoredProfile);
    }
  }

  Map<String, String> _mapSavedAnswers(
    List<Map<String, dynamic>> savedAnswers,
    List<QuizQuestion> questions,
  ) {
    final mapped = <String, String>{};

    for (final answer in savedAnswers) {
      final questionId = answer['questionId']?.toString() ?? answer['QuestionId']?.toString();
      final answerValue = answer['answer']?.toString() ?? answer['Answer']?.toString();
      if (questionId == null || answerValue == null) continue;

      final question = _firstWhereOrNull(questions, (item) => item.id == questionId);
      final option = question == null
          ? null
          : _firstWhereOrNull(
              question.options,
              (item) =>
                  item.id == answerValue ||
                  item.answerValue == answerValue ||
                  item.optionCode == answerValue ||
                  item.label['vi'] == answerValue,
            );

      if (option != null) {
        mapped[questionId] = option.id;
      }
    }

    return mapped;
  }

  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  Map<String, int> _buildProfileFromAnswers(
    List<QuizQuestion> questions,
    Map<String, String> answers,
  ) {
    final profile = _createEmptyProfile();

    for (final question in questions) {
      final selectedOptionId = answers[question.id];
      final option = _firstWhereOrNull(question.options, (item) => item.id == selectedOptionId);
      if (option == null) continue;

      option.vector.forEach((key, value) {
        profile[key] = (profile[key] ?? 0) + value;
      });
    }

    return profile;
  }

  String _buildInsightForAnswer(
    List<QuizQuestion> questions,
    Map<String, String> answers,
    String questionId,
  ) {
    final question = _firstWhereOrNull(questions, (item) => item.id == questionId);
    final option = question == null
        ? null
        : _firstWhereOrNull(question.options, (item) => item.id == answers[questionId]);
    return option == null ? '' : buildInsightText(option, 'vi');
  }

  Future<void> _onSelectOption(QuizQuestion question, QuizOption option) async {
    if (_isThinking || _answers.containsKey(question.id)) return;

    final previousAnswers = Map<String, String>.from(_answers);
    final previousInsights = Map<String, String>.from(_insights);
    final previousProfile = Map<String, int>.from(_profile);

    setState(() {
      _answers[question.id] = option.id;
      option.vector.forEach((key, value) {
        _profile[key] = (_profile[key] ?? 0) + value;
      });
      _insights[question.id] = buildInsightText(option, 'vi');
      _isThinking = true;
      _thinkingQuestionId = question.id;
    });

    try {
      await ApiClient.instance.createUserAnswer(
        questionId: question.id,
        answer: option.answerValue,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _answers
          ..clear()
          ..addAll(previousAnswers);
        _insights
          ..clear()
          ..addAll(previousInsights);
        _profile = previousProfile;
        _isThinking = false;
        _thinkingQuestionId = null;
      });
      return;
    }

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() {
      _isThinking = false;
      _thinkingQuestionId = null;
    });

    if (_answers.length == _questions.length) {
      AppState.of(context, listen: false).completeQuiz(_profile);
    }
  }

  Future<void> _resetQuiz() async {
    try {
      await ApiClient.instance.deleteUserAnswers();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _answers.clear();
      _insights.clear();
      _isThinking = false;
      _thinkingQuestionId = null;
      _profile = _createEmptyProfile();
    });
    AppState.of(context, listen: false).resetQuiz();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0ED8AB)),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFECC741), size: 40),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadQuiz,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final isDone = _answers.length == _questions.length;
    if (isDone) {
      return _buildResultsScreen();
    }

    final progress = _questions.isEmpty ? 0.0 : _answers.length / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã trả lời ${_answers.length}/${_questions.length} câu',
                style: const TextStyle(color: Color(0xFFECC741), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '${(progress * 100).toInt()}% Hoàn thành',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0ED8AB)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),
          ..._questions.asMap().entries.map(
                (entry) => _buildQuestionCard(entry.key, entry.value),
              ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, QuizQuestion question) {
    final selectedOptionId = _answers[question.id];
    final isAnswered = selectedOptionId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Câu ${index + 1}: ${question.prompt['vi'] ?? ''}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 16),
          ...question.options.map((option) => _buildOptionTile(question, option, isAnswered, selectedOptionId)),
          if (_isThinking && _thinkingQuestionId == question.id)
            _buildThinkingBox()
          else if (_insights[question.id]?.isNotEmpty == true)
            _buildInsightBox(_insights[question.id]!),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    QuizQuestion question,
    QuizOption option,
    bool isAnswered,
    String? selectedOptionId,
  ) {
    final isSelected = selectedOptionId == option.id;
    Color cardBorder = Colors.white.withOpacity(0.08);
    Color cardFill = Colors.white.withOpacity(0.04);
    Color textColor = Colors.white70;

    if (isSelected) {
      cardBorder = const Color(0xFFECC741);
      cardFill = const Color(0xFFECC741).withOpacity(0.08);
      textColor = const Color(0xFFECC741);
    } else if (isAnswered) {
      textColor = Colors.white30;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isAnswered || _isThinking ? null : () => _onSelectOption(question, option),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.label['vi'] ?? '',
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFECC741), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0ED8AB).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0ED8AB).withOpacity(0.12)),
      ),
      child: const Row(
        children: [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0ED8AB)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI đang phân tích câu trả lời mới...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightBox(String insight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology_outlined, color: Color(0xFFECC741), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insight,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    final left = _profile['leftBrain'] ?? 0;
    final right = _profile['rightBrain'] ?? 0;

    final brainProfile = left == right
        ? 'Cân bằng hai bán cầu não'
        : left > right
            ? 'Thiên về bán cầu não trái'
            : 'Thiên về bán cầu não phải';

    final labelMap = {
      'tech': 'Định hướng công nghệ',
      'business': 'Tư duy kinh doanh',
      'engineering': 'Tư duy kỹ thuật',
      'creative': 'Khuynh hướng sáng tạo',
      'social': 'Thiên hướng giao tiếp - xã hội',
    };

    final strengths = scoreKeys.map((key) => MapEntry(key, _profile[key] ?? 0)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topStrengths = strengths.take(2).toList();
    final rankedSchools = rankUniversities(_profile);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(Icons.emoji_events_outlined, color: Color(0xFFECC741), size: 48),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hồ sơ định hướng của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Dựa trên phân tích ${_questions.length} câu hỏi của bạn',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 24),
          _buildSummaryCard(
            title: 'Tư duy đặc trưng',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brainProfile,
                  style: const TextStyle(color: Color(0xFF0ED8AB), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Điểm chi tiết: Bán cầu Trái ($left) | Bán cầu Phải ($right)',
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            title: 'Xu hướng năng lực nổi trội',
            child: Column(
              children: topStrengths.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: Color(0xFFECC741), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          labelMap[entry.key] ?? entry.key,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Trường đại học gợi ý phù hợp',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...rankedSchools.map(_buildSchoolCard),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _resetQuiz,
            icon: const Icon(Icons.replay),
            label: const Text('Làm lại bài trắc nghiệm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildSchoolCard(UniversityWithScore school) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school.name['vi']!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngành: ${school.major['vi']!}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Học phí: ${school.tuition['vi']!}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECC741).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${school.score}%',
              style: const TextStyle(color: Color(0xFFECC741), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
