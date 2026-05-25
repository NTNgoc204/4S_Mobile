import 'package:flutter/material.dart';
import '../main.dart';
import '../models/quiz.dart';
import '../models/university.dart';

class QuizTab extends StatefulWidget {
  const QuizTab({super.key});

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  int _activeIndex = 0;
  final Map<String, String> _answers = {};
  final Map<String, String> _insights = {};
  bool _isThinking = false;
  String? _thinkingQuestionId;

  Map<String, int> _profile = {
    'tech': 0,
    'business': 0,
    'engineering': 0,
    'creative': 0,
    'social': 0,
    'leftBrain': 0,
    'rightBrain': 0,
  };

  void _onSelectOption(QuizQuestion question, QuizOption option) async {
    if (_isThinking || _answers.containsKey(question.id)) return;

    setState(() {
      _answers[question.id] = option.id;
      // Add vector parameters
      option.vector.forEach((key, value) {
        _profile[key] = (_profile[key] ?? 0) + value;
      });

      _isThinking = true;
      _thinkingQuestionId = question.id;
      _insights[question.id] = buildInsightText(option, 'vi');
    });

    // Provide delayed pacing between questions to simulate AI calculations
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    setState(() {
      _isThinking = false;
      _thinkingQuestionId = null;
      if (_activeIndex < quizQuestions.length - 1) {
        _activeIndex++;
      } else {
        // Quiz completed, notify global AppState to merge scores
        AppState.of(context, listen: false).completeQuiz(_profile);
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      _activeIndex = 0;
      _answers.clear();
      _insights.clear();
      _isThinking = false;
      _thinkingQuestionId = null;
      _profile = {
        'tech': 0,
        'business': 0,
        'engineering': 0,
        'creative': 0,
        'social': 0,
        'leftBrain': 0,
        'rightBrain': 0,
      };
    });
    AppState.of(context, listen: false).resetQuiz();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = _answers.length == quizQuestions.length;

    if (isDone) {
      return _buildResultsScreen();
    }

    final currentQuestion = quizQuestions[_activeIndex];
    final progress = (_activeIndex + 1) / quizQuestions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Progress Indicator Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu hỏi ${_activeIndex + 1}/${quizQuestions.length}',
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

          // 2. Question Prompt Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Text(
              currentQuestion.prompt['vi']!,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Option Selection List
          ...currentQuestion.options.map((option) {
            final isSelected = _answers[currentQuestion.id] == option.id;
            final isAnySelected = _answers.containsKey(currentQuestion.id);

            Color cardBorder = Colors.white.withOpacity(0.08);
            Color cardFill = Colors.white.withOpacity(0.04);
            Color textColor = Colors.white70;

            if (isSelected) {
              cardBorder = const Color(0xFFECC741);
              cardFill = const Color(0xFFECC741).withOpacity(0.08);
              textColor = const Color(0xFFECC741);
            } else if (isAnySelected) {
              textColor = Colors.white30;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: isAnySelected ? null : () => _onSelectOption(currentQuestion, option),
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
                          option.label['vi']!,
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Color(0xFFECC741), size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),

          // 4. Live AI Insight
          const SizedBox(height: 12),
          if (_isThinking && _thinkingQuestionId == currentQuestion.id) ...[
            Container(
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
            ),
          ] else if (_answers.containsKey(currentQuestion.id) && _insights.containsKey(currentQuestion.id)) ...[
            Container(
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
                      _insights[currentQuestion.id]!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    // Process final stats
    final left = _profile['leftBrain'] ?? 0;
    final right = _profile['rightBrain'] ?? 0;

    String brainProfile;
    if (left == right) {
      brainProfile = 'Cân bằng hai bán cầu não';
    } else {
      brainProfile = left > right ? 'Thiên về bán cầu não trái' : 'Thiên về bán cầu não phải';
    }

    final labelMap = {
      'tech': 'Định hướng công nghệ',
      'business': 'Tư duy kinh doanh',
      'engineering': 'Tư duy kỹ thuật',
      'creative': 'Khuynh hướng sáng tạo',
      'social': 'Thiên hướng giao tiếp - xã hội',
    };

    final List<MapEntry<String, int>> strengths = scoreKeys
        .map((key) => MapEntry(key, _profile[key] ?? 0))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topStrengths = strengths.take(2).toList();
    final rankedSchools = rankUniversities(_profile);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Title
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
          const Text(
            'Dựa trên phân tích 15 câu hỏi của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // 1. Brain Profile Snapshot
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tư duy đặc trưng', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
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

          // 2. Top Career Tendencies
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Xu hướng năng lực nổi trội', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 12),
                ...topStrengths.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Color(0xFFECC741), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          labelMap[entry.key]!,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Recommended Universities
          const Text(
            'Trường đại học gợi ý phù hợp',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...rankedSchools.map((school) {
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
          }),
          const SizedBox(height: 24),

          // Reset button
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
}
