import 'package:flutter/material.dart';

import '../main.dart';
import '../models/quiz.dart';
import '../services/api_client.dart';
import 'quiz_results_screen.dart';


class QuizTab extends StatefulWidget {
  const QuizTab({super.key});

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  List<QuizQuestion> _questions = [];
  List<String> _categoryIds = [];
  int _activeCategoryIndex = 0;
  final Map<String, String> _answers = {};
  final Map<String, String> _insights = {};
  bool _isLoading = true;
  bool _isCategoryThinking = false;
  bool _isOverallLoading = false;
  String _overallSummary = "";
  List<AiUniversityRecommendation> _aiRecommendations = [];
  String? _loadError;
  String? _thinkingQuestionId;
  final ScrollController _scrollController = ScrollController();
  bool _showResults = false;
  String? _activeCustomQuestionId;
  final TextEditingController _customTextController = TextEditingController();

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

  @override
  void dispose() {
    _scrollController.dispose();
    _customTextController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    List<QuizQuestion> loadedQuestions = [];
    List<Map<String, dynamic>> savedAnswerRows = [];
    List<String> loadedCategoryIds = [];

    // 1. Tải Categories và Câu hỏi từ Backend
    try {
      final results = await Future.wait([
        ApiClient.instance.getQuestions(),
        ApiClient.instance.getQuestionOptions(),
        ApiClient.instance.getQuestionCategories(),
      ]);

      final rawQuestions = results[0];
      final rawOptions = results[1];
      final rawCategories = results[2];

      // Parse categories
      final parsedCategories = rawCategories
          .map((cat) => QuestionCategory.fromApi(cat))
          .where((cat) =>
              cat.id != 'b1a2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d' &&
              cat.name != 'Trò chuyện hướng nghiệp AI')
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      // Create a map of category ID to category index/name
      final categoryMap = <String, MapEntry<int, String>>{};
      for (int i = 0; i < parsedCategories.length; i++) {
        categoryMap[parsedCategories[i].id] = MapEntry(i, parsedCategories[i].name);
      }

      // Filter and parse questions
      final parsedQuestions = rawQuestions
          .where((q) {
            if (q['isActice']?.toString() == 'No') return false;
            final catId = q['categoryId']?.toString() ?? q['CategoryId']?.toString();
            final catName = q['categoryName']?.toString() ?? q['CategoryName']?.toString();
            if (catId == 'b1a2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d' ||
                catName == 'Trò chuyện hướng nghiệp AI') {
              return false;
            }
            return true;
          })
          .map((q) {
            final catId = q['categoryId']?.toString() ?? q['CategoryId']?.toString() ?? '';
            final catEntry = categoryMap[catId];
            final catName = catEntry?.value ?? q['categoryName']?.toString() ?? q['CategoryName']?.toString();
            return QuizQuestion.fromApi(q, rawOptions, categoryName: catName);
          })
          .where((q) => q.id.isNotEmpty && q.options.isNotEmpty)
          .toList();

      // Sort questions: by category index first, then question displayOrder
      parsedQuestions.sort((a, b) {
        final aCatId = a.categoryId ?? '';
        final bCatId = b.categoryId ?? '';
        final aCatIndex = categoryMap[aCatId]?.key ?? 999;
        final bCatIndex = categoryMap[bCatId]?.key ?? 999;
        if (aCatIndex != bCatIndex) {
          return aCatIndex.compareTo(bCatIndex);
        }
        return a.displayOrder.compareTo(b.displayOrder);
      });

      loadedQuestions = parsedQuestions;

      // Thu thập các category ID theo thứ tự sắp xếp
      for (final q in loadedQuestions) {
        if (q.categoryId != null && q.categoryId!.isNotEmpty && !loadedCategoryIds.contains(q.categoryId)) {
          loadedCategoryIds.add(q.categoryId!);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Lỗi tải dữ liệu từ Backend: $e');
      if (!mounted) return;
      setState(() {
        _loadError = 'Lỗi kết nối máy chủ. Vui lòng kiểm tra lại mạng.';
        _isLoading = false;
      });
      return;
    }

    if (loadedQuestions.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Không tìm thấy câu hỏi trắc nghiệm nào trên máy chủ.';
        _isLoading = false;
      });
      return;
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

    // Nhóm câu hỏi theo danh mục để tải lại insight
    final categoryQuestionsMap = <String, List<QuizQuestion>>{};
    for (final q in loadedQuestions) {
      if (q.categoryId != null && q.categoryId!.isNotEmpty) {
        categoryQuestionsMap.putIfAbsent(q.categoryId!, () => []).add(q);
      }
    }

    final restoredInsights = <String, String>{};

    // Tải các đánh giá danh mục cũ hoặc kích hoạt đánh giá nếu đã làm xong
    for (final entry in categoryQuestionsMap.entries) {
      final catId = entry.key;
      final qList = entry.value;
      final isCompleted = qList.every((q) => restoredAnswers.containsKey(q.id));
      if (isCompleted && qList.isNotEmpty) {
        final lastQuestion = qList.last;
        try {
          final evalRes = await ApiClient.instance.getCategoryEvaluation(catId);
          if (evalRes != null && evalRes['success'] == true && evalRes['data'] != null) {
            final evalData = evalRes['data'];
            final textVal = evalData is String
                ? evalData
                : (evalData['evaluationText']?.toString() ?? '');
            restoredInsights[lastQuestion.id] = textVal;
          } else {
            // Không tìm thấy trong DB, kích hoạt sinh mới
            final genRes = await ApiClient.instance.evaluateCategory(catId);
            if (genRes != null && genRes['success'] == true && genRes['data'] != null) {
              restoredInsights[lastQuestion.id] = genRes['data'].toString();
            }
          }
        } catch (e) {
          // Thử gọi sinh mới, nếu không được thì báo lỗi
          try {
            final genRes = await ApiClient.instance.evaluateCategory(catId);
            if (genRes != null && genRes['success'] == true && genRes['data'] != null) {
              restoredInsights[lastQuestion.id] = genRes['data'].toString();
            } else {
              restoredInsights[lastQuestion.id] = 'Đã có lỗi xảy ra khi gọi AI phân tích chuyên mục này. Vui lòng thử lại sau.';
            }
          } catch (_) {
            restoredInsights[lastQuestion.id] = 'Đã có lỗi xảy ra khi gọi AI phân tích chuyên mục này. Vui lòng thử lại sau.';
          }
        }
      }
    }

    // Tải kết quả đánh giá tổng quan nếu đã xong hết câu hỏi
    String restoredOverallSummary = "";
    List<AiUniversityRecommendation> restoredAiRecommendations = [];
    final isAllDone = restoredAnswers.length == loadedQuestions.length && loadedQuestions.isNotEmpty;

    if (isAllDone) {
      try {
        final overallRes = await ApiClient.instance.getOverallSummary();
        if (overallRes != null && overallRes['success'] == true && overallRes['data'] != null) {
          final summaryData = overallRes['data'] as Map<String, dynamic>;
          restoredOverallSummary = summaryData['summaryText']?.toString() ?? summaryData['SummaryText']?.toString() ?? '';
          restoredAiRecommendations = _mapAiRecommendations(summaryData);
        } else {
          // Kích hoạt sinh tổng quan
          final genOverallRes = await ApiClient.instance.evaluateOverall();
          if (genOverallRes != null && genOverallRes['success'] == true && genOverallRes['data'] != null) {
            final summaryData = genOverallRes['data'] as Map<String, dynamic>;
            restoredOverallSummary = summaryData['summaryText']?.toString() ?? summaryData['SummaryText']?.toString() ?? '';
            restoredAiRecommendations = _mapAiRecommendations(summaryData);
          }
        }
      } catch (e) {
        // Fallback offline
      }
    }

    // Xác định index của category hiện tại chưa hoàn thành
    int restoredActiveCategoryIndex = 0;
    for (int i = 0; i < loadedCategoryIds.length; i++) {
      final catId = loadedCategoryIds[i];
      final catQuestions = loadedQuestions.where((q) => q.categoryId == catId).toList();
      final isCompleted = catQuestions.every((q) => restoredAnswers.containsKey(q.id));
      if (!isCompleted) {
        restoredActiveCategoryIndex = i;
        break;
      } else {
        if (i == loadedCategoryIds.length - 1) {
          restoredActiveCategoryIndex = i;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _questions = loadedQuestions;
      _categoryIds = loadedCategoryIds;
      _answers
        ..clear()
        ..addAll(restoredAnswers);
      _insights
        ..clear()
        ..addAll(restoredInsights);
      _profile = restoredProfile;
      _activeCategoryIndex = restoredActiveCategoryIndex;
      _showResults = isAllDone;
      _overallSummary = restoredOverallSummary;
      _aiRecommendations = restoredAiRecommendations;
      _isLoading = false;
    });

    _scrollToBottom();

    if (isAllDone) {
      AppState.of(context, listen: false).completeQuiz(restoredProfile);
    }
  }

  List<AiUniversityRecommendation> _mapAiRecommendations(Map<String, dynamic> data) {
    final List<AiUniversityRecommendation> list = [];
    dynamic readProperty(String camelKey, String pascalKey) {
      return data[camelKey] ?? data[pascalKey];
    }
    
    final topRaw = readProperty('top3Universities', 'Top3Universities');
    if (topRaw is List) {
      for (final item in topRaw) {
        if (item is Map<String, dynamic>) {
          list.add(AiUniversityRecommendation.fromJson(item, 'top3'));
        }
      }
    }

    final otherRaw = readProperty('next5Universities', 'Next5Universities');
    if (otherRaw is List) {
      for (final item in otherRaw) {
        if (item is Map<String, dynamic>) {
          list.add(AiUniversityRecommendation.fromJson(item, 'next5'));
        }
      }
    }

    return list;
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
      if (question == null) continue;

      final option = _firstWhereOrNull(
        question.options,
        (item) =>
            item.id == answerValue ||
            item.answerValue == answerValue ||
            item.optionCode == answerValue ||
            item.label['vi'] == answerValue ||
            item.label['en'] == answerValue,
      );

      if (option != null) {
        if (isOptionActuallyOther(option)) {
          mapped[questionId] = answerValue;
        } else {
          mapped[questionId] = option.id;
        }
      } else {
        mapped[questionId] = answerValue;
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
      if (selectedOptionId == null) continue;

      var option = _firstWhereOrNull(question.options, (item) => item.id == selectedOptionId);
      if (option == null) {
        option = _firstWhereOrNull(question.options, (item) => isOptionActuallyOther(item));
      }
      if (option == null) continue;

      option.vector.forEach((key, value) {
        profile[key] = (profile[key] ?? 0) + value;
      });
    }

    return profile;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  bool _isLastQuestionOfCategory(QuizQuestion question) {
    final qIndex = _questions.indexWhere((q) => q.id == question.id);
    if (qIndex == -1) return false;
    if (qIndex == _questions.length - 1) return true;
    return _questions[qIndex].categoryId != _questions[qIndex + 1].categoryId;
  }

  List<Widget> _buildVisibleQuestions() {
    final visible = <QuizQuestion>[];
    for (int i = 0; i <= _activeCategoryIndex && i < _categoryIds.length; i++) {
      final catId = _categoryIds[i];
      visible.addAll(_questions.where((q) => q.categoryId == catId));
    }

    return visible.asMap().entries.map((entry) {
      return _buildQuestionCard(entry.key, entry.value);
    }).toList();
  }

  bool _isActiveCategoryFullyAnswered() {
    if (_categoryIds.isEmpty || _activeCategoryIndex >= _categoryIds.length) return false;
    final activeCatId = _categoryIds[_activeCategoryIndex];
    final activeCatQuestions = _questions.where((q) => q.categoryId == activeCatId).toList();
    return activeCatQuestions.every((q) => _answers.containsKey(q.id));
  }

  Future<void> _evaluateActiveCategory(String categoryId, String lastQuestionId, {bool shouldScroll = false}) async {
    setState(() {
      _isCategoryThinking = true;
      _thinkingQuestionId = lastQuestionId;
      _insights.remove(lastQuestionId);
    });
    if (shouldScroll) {
      _scrollToBottom();
    }

    String categoryEvalText = "";
    try {
      final evalRes = await ApiClient.instance.evaluateCategory(categoryId);
      if (evalRes != null && evalRes['success'] == true && evalRes['data'] != null) {
        categoryEvalText = evalRes['data'].toString();
      } else {
        categoryEvalText = 'Đã có lỗi xảy ra khi gọi AI phân tích chuyên mục này. Vui lòng thử lại sau.';
      }
    } catch (_) {
      categoryEvalText = 'Đã có lỗi xảy ra khi gọi AI phân tích chuyên mục này. Vui lòng thử lại sau.';
    }

    if (!mounted) return;
    setState(() {
      _insights[lastQuestionId] = categoryEvalText;
      _isCategoryThinking = false;
      _thinkingQuestionId = null;
    });
    if (shouldScroll) {
      _scrollToBottom();
    }
  }

  Future<void> _onSelectOption(QuizQuestion question, QuizOption option, {String? customText}) async {
    if (_isCategoryThinking || _isOverallLoading) return;

    final isAlreadyAnswered = _answers.containsKey(question.id);
    final answerValue = customText ?? option.label['vi'] ?? option.label['en'] ?? option.id;

    setState(() {
      _answers[question.id] = customText ?? option.id;
      _profile = _buildProfileFromAnswers(_questions, _answers);
    });

    try {
      if (isAlreadyAnswered) {
        await ApiClient.instance.updateUserAnswer(
          questionId: question.id,
          answer: answerValue,
        );
      } else {
        await ApiClient.instance.createUserAnswer(
          questionId: question.id,
          answer: answerValue,
        );
      }
    } catch (_) {
      // Revert optional
    }

    // Nếu toàn bộ danh mục hiện tại đã được trả lời xong, gọi phân tích AI
    if (_isActiveCategoryFullyAnswered()) {
      final activeCatId = _categoryIds[_activeCategoryIndex];
      final activeCatQuestions = _questions.where((q) => q.categoryId == activeCatId).toList();
      final lastQuestionOfCategory = activeCatQuestions.last;

      final isLastQuestion = question.id == lastQuestionOfCategory.id;
      final shouldScroll = isLastQuestion && !isAlreadyAnswered;
      _evaluateActiveCategory(activeCatId, lastQuestionOfCategory.id, shouldScroll: shouldScroll);
    } else {
      // Nếu có câu chưa trả lời (do sửa đáp án hoặc bỏ trống), xóa insight cũ để đợi hoàn thành lại
      final activeCatId = _categoryIds[_activeCategoryIndex];
      final activeCatQuestions = _questions.where((q) => q.categoryId == activeCatId).toList();
      final lastQuestionOfCategory = activeCatQuestions.last;
      if (_insights.containsKey(lastQuestionOfCategory.id)) {
        setState(() {
          _insights.remove(lastQuestionOfCategory.id);
        });
      }
    }
  }

  void _goToNextCategory() {
    if (_activeCategoryIndex < _categoryIds.length - 1) {
      final double previousMaxScroll = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : 0;

      setState(() {
        _activeCategoryIndex++;
      });

      if (previousMaxScroll > 0) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              previousMaxScroll,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  Future<void> _completeQuizAndNavigate() async {
    setState(() {
      _isOverallLoading = true;
    });

    // Hiển thị vòng xoay loading tổng hợp kết quả
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: const Color(0xFF081A30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFECC741)),
                  const SizedBox(height: 20),
                  const Text(
                    'AI đang tổng hợp hồ sơ định hướng và gợi ý trường...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vui lòng đợi trong giây lát.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    String overallSummaryText = "";
    List<AiUniversityRecommendation> recommendationsList = [];

    try {
      final overallRes = await ApiClient.instance.evaluateOverall();
      if (overallRes != null && overallRes['success'] == true && overallRes['data'] != null) {
        final summaryData = overallRes['data'] as Map<String, dynamic>;
        overallSummaryText = summaryData['summaryText']?.toString() ?? summaryData['SummaryText']?.toString() ?? '';
        recommendationsList = _mapAiRecommendations(summaryData);
      } else {
        final summaryRes = await ApiClient.instance.getOverallSummary();
        if (summaryRes != null && summaryRes['success'] == true && summaryRes['data'] != null) {
          final summaryData = summaryRes['data'] as Map<String, dynamic>;
          overallSummaryText = summaryData['summaryText']?.toString() ?? summaryData['SummaryText']?.toString() ?? '';
          recommendationsList = _mapAiRecommendations(summaryData);
        }
      }
    } catch (_) {
      try {
        final summaryRes = await ApiClient.instance.getOverallSummary();
        if (summaryRes != null && summaryRes['success'] == true && summaryRes['data'] != null) {
          final summaryData = summaryRes['data'] as Map<String, dynamic>;
          overallSummaryText = summaryData['summaryText']?.toString() ?? summaryData['SummaryText']?.toString() ?? '';
          recommendationsList = _mapAiRecommendations(summaryData);
        }
      } catch (_) {}
    }

    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Tắt Dialog loading
    }

    if (overallSummaryText.isEmpty) {
      setState(() {
        _isOverallLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI đang bận hoặc kết nối mạng không ổn định. Vui lòng nhấn lại nút hoàn thành.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _overallSummary = overallSummaryText;
      _aiRecommendations = recommendationsList;
      _isOverallLoading = false;
      _showResults = true;
    });

    AppState.of(context, listen: false).completeQuiz(_profile);

    _navigateToResultsScreen();
  }

  void _navigateToResultsScreen() {
    if (_overallSummary.isEmpty) {
      _completeQuizAndNavigate();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => QuizResultsScreen(
          overallSummary: _overallSummary,
          aiRecommendations: _aiRecommendations,
          onReset: _resetQuiz,
        ),
      ),
    );
  }

  Future<void> _resetQuiz() async {
    try {
      await ApiClient.instance.deleteUserAnswers();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _answers.clear();
      _insights.clear();
      _isCategoryThinking = false;
      _isOverallLoading = false;
      _overallSummary = "";
      _aiRecommendations.clear();
      _thinkingQuestionId = null;
      _profile = _createEmptyProfile();
      _activeCategoryIndex = 0;
      _showResults = false;
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

    if (_showResults) {
      return _buildCompletedQuizCard();
    }

    final progress = _questions.isEmpty ? 0.0 : _answers.length / _questions.length;

    return SingleChildScrollView(
      controller: _scrollController,
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
          ..._buildVisibleQuestions(),
        ],
      ),
    );
  }

  Widget _buildCompletedQuizCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_outlined, color: Color(0xFFECC741), size: 64),
              const SizedBox(height: 16),
              const Text(
                'Bạn đã hoàn thành bài trắc nghiệm!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI đã tổng hợp xong hồ sơ định hướng nghề nghiệp và gợi ý các trường đại học phù hợp nhất cho bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToResultsScreen,
                icon: const Icon(Icons.analytics_outlined, color: Color(0xFF11243B)),
                label: const Text(
                  'Xem kết quả phân tích',
                  style: TextStyle(color: Color(0xFF11243B), fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFECC741),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _resetQuiz,
                icon: const Icon(Icons.replay, color: Colors.white54, size: 16),
                label: const Text(
                  'Làm lại trắc nghiệm',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, QuizQuestion question) {
    final selectedOptionId = _answers[question.id];
    final isAnswered = selectedOptionId != null;

    final isFirstOfCategory = index == 0 || _questions[index - 1].categoryId != question.categoryId;
    final categoryName = question.categoryName ?? 'Trắc nghiệm';
    final questionCategoryIndex = _categoryIds.indexOf(question.categoryId ?? '');
    final canAnswer = questionCategoryIndex == _activeCategoryIndex && !_isCategoryThinking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isFirstOfCategory) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0ED8AB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF0ED8AB),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: questionCategoryIndex == _activeCategoryIndex
                  ? const Color(0xFF0ED8AB).withOpacity(0.15)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Câu ${index + 1}: ${question.prompt['vi'] ?? ''}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
              ),
              const SizedBox(height: 16),
              ...question.options.map((option) => _buildOptionTile(question, option, isAnswered, selectedOptionId, canAnswer)),
              if (_activeCustomQuestionId == question.id) ...[
                const SizedBox(height: 12),
                _buildCustomInputField(question),
              ],
            ],
          ),
        ),
        if (_isLastQuestionOfCategory(question)) ...[
          if (_isCategoryThinking && _thinkingQuestionId == question.id)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _buildThinkingBox(),
            )
          else if (_insights[question.id]?.isNotEmpty == true) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _buildInsightBox(_insights[question.id]!),
            ),
            if (questionCategoryIndex == _activeCategoryIndex)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: ElevatedButton.icon(
                  onPressed: questionCategoryIndex < _categoryIds.length - 1
                      ? _goToNextCategory
                      : _completeQuizAndNavigate,
                  icon: Icon(
                    questionCategoryIndex < _categoryIds.length - 1 ? Icons.arrow_forward : Icons.check_circle_outline,
                    size: 16,
                    color: const Color(0xFF11243B),
                  ),
                  label: Text(
                    questionCategoryIndex < _categoryIds.length - 1 ? 'Tiếp tục' : 'Hoàn thành',
                    style: const TextStyle(
                      color: Color(0xFF11243B),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFECC741),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _buildOptionTile(
    QuizQuestion question,
    QuizOption option,
    bool isAnswered,
    String? selectedOptionId,
    bool canAnswer,
  ) {
    final isOther = isOptionActuallyOther(option);
    final bool isSelected;
    if (_activeCustomQuestionId == question.id) {
      isSelected = isOther;
    } else {
      if (isOther) {
        isSelected = selectedOptionId != null &&
            !question.options.any((o) => o.id == selectedOptionId && !isOptionActuallyOther(o));
      } else {
        isSelected = selectedOptionId == option.id;
      }
    }
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

    final String displayLabel;
    if (isSelected && isOther) {
      if (_activeCustomQuestionId == question.id || selectedOptionId == null) {
        displayLabel = option.label['vi'] ?? '';
      } else {
        final isPrevAnswerCustom = !question.options.any((o) => o.id == selectedOptionId && !isOptionActuallyOther(o));
        if (isPrevAnswerCustom) {
          displayLabel = 'Khác: $selectedOptionId';
        } else {
          displayLabel = option.label['vi'] ?? '';
        }
      }
    } else {
      displayLabel = option.label['vi'] ?? '';
    }

    final onTapHandler = canAnswer ? () {
      if (isOther) {
        setState(() {
          _activeCustomQuestionId = question.id;
          final isPrevAnswerCustom = selectedOptionId != null &&
              !question.options.any((o) => o.id == selectedOptionId && !isOptionActuallyOther(o));
          if (isPrevAnswerCustom) {
            _customTextController.text = selectedOptionId;
          } else {
            _customTextController.clear();
          }
        });
      } else {
        setState(() {
          _activeCustomQuestionId = null;
        });
        _onSelectOption(question, option);
      }
    } : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTapHandler,
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
                  displayLabel,
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

  Widget _buildCustomInputField(QuizQuestion question) {
    final customOtherOption = _firstWhereOrNull(question.options, (o) => isOptionActuallyOther(o));
    if (customOtherOption == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customTextController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nhập câu trả lời của bạn...',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.04),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFECC741)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _activeCustomQuestionId = null;
                });
              },
              child: const Text('Hủy', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final textVal = _customTextController.text.trim();
                if (textVal.isNotEmpty) {
                  setState(() {
                    _activeCustomQuestionId = null;
                  });
                  _onSelectOption(question, customOtherOption, customText: textVal);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFECC741),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(color: Color(0xFF11243B), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
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
              'AI đang phân tích câu trả lời của bộ câu hỏi này...',
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
}
