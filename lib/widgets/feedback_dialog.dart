import 'dart:ui';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/feedback_service.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => const FeedbackDialog(),
    );
  }

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _questions = [];
  final Map<String, String> _answers = {}; // questionId -> answerText

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final activeQuestions = await FeedbackService.instance.getActiveQuestions();
      // Sort by Order ascending
      activeQuestions.sort((a, b) => (a['order'] as num? ?? 0).compareTo(b['order'] as num? ?? 0));
      
      if (mounted) {
        setState(() {
          _questions = activeQuestions;
          for (var q in _questions) {
            _answers[q['id'].toString()] = '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải câu hỏi khảo sát: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _submit() async {
    // Validate that all questions are answered
    final unanswered = _questions.any((q) => _answers[q['id'].toString()]!.trim().isEmpty);
    if (unanswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng trả lời đầy đủ tất cả các câu hỏi khảo sát!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appState = AppState.of(context);
      final user = appState.currentUser;
      final userEmail = user?.email ?? '';
      final userFullName = user?.fullName ?? '';

      final List<Map<String, dynamic>> submitAnswers = [];
      _answers.forEach((qId, text) {
        submitAnswers.add({
          'questionId': qId,
          'answerText': text,
        });
      });

      await FeedbackService.instance.submitFeedback(
        userEmail: userEmail,
        userFullName: userFullName,
        answers: submitAnswers,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn ý kiến đóng góp quý báu của bạn dành cho 4S!'),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi phản hồi thất bại: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xEE1A2F4C),
                  Color(0xEE0B1528),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: _isLoading
                ? const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFECC741)),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Khảo Sát Ý Kiến Người Dùng',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Sora',
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Góp ý của bạn giúp cải thiện dịch vụ của 4S',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      
                      if (_questions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Không có khảo sát nào đang hoạt động.',
                              style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(_questions.length, (index) {
                                final q = _questions[index];
                                final qId = q['id'].toString();
                                final qText = q['questionText'] ?? '';
                                final qType = q['questionType'] ?? 'Text';
                                final qOptions = q['options'] ?? '';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${index + 1}. $qText',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildQuestionInput(qId, qType, qOptions),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      
                      if (_questions.isNotEmpty) ...[
                        const Divider(color: Colors.white12, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white60,
                              ),
                              child: const Text('Đóng'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0ED8AB),
                                foregroundColor: const Color(0xFF081326),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF081326),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Gửi phản hồi',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionInput(String qId, String qType, String options) {
    final currentValue = _answers[qId] ?? '';

    switch (qType) {
      case 'Rating':
        final currentRating = int.tryParse(currentValue) ?? 0;
        return Row(
          children: List.generate(5, (starIdx) {
            final val = starIdx + 1;
            final isFilled = val <= currentRating;
            return IconButton(
              icon: Icon(
                isFilled ? Icons.star : Icons.star_border,
                color: isFilled ? const Color(0xFFECC741) : Colors.white24,
                size: 28,
              ),
              onPressed: () {
                setState(() {
                  _answers[qId] = val.toString();
                });
              },
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(),
            );
          }),
        );

      case 'YesNo':
        return Row(
          children: [
            Expanded(
              child: _buildChoiceButton(
                label: 'Có',
                isSelected: currentValue == 'Yes',
                onTap: () => setState(() => _answers[qId] = 'Yes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChoiceButton(
                label: 'Không',
                isSelected: currentValue == 'No',
                onTap: () => setState(() => _answers[qId] = 'No'),
              ),
            ),
          ],
        );

      case 'MultipleChoice':
        final optionList = options
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        return Column(
          children: optionList.map((opt) {
            final isSelected = currentValue == opt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _answers[qId] = opt),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0x220ED8AB)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0ED8AB)
                          : Colors.white.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          opt,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Container(
                        height: 18,
                        width: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0ED8AB) : Colors.white30,
                            width: 1.5,
                          ),
                          color: isSelected ? const Color(0xFF0ED8AB) : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(Icons.check, size: 10, color: Color(0xFF081326)),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );

      case 'Text':
      default:
        return TextField(
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          onChanged: (text) => _answers[qId] = text,
          decoration: InputDecoration(
            hintText: 'Nhập câu trả lời hoặc góp ý của bạn...',
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0ED8AB)),
            ),
          ),
        );
    }
  }

  Widget _buildChoiceButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x220ED8AB) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0ED8AB) : Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
