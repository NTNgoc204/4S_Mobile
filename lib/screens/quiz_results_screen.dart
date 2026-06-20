import 'package:flutter/material.dart';
import '../models/quiz.dart';

class QuizResultsScreen extends StatelessWidget {
  final String overallSummary;
  final List<AiUniversityRecommendation> aiRecommendations;
  final VoidCallback onReset;

  const QuizResultsScreen({
    super.key,
    required this.overallSummary,
    required this.aiRecommendations,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020D1A),
      appBar: AppBar(
        title: const Text('Kết Quả Phân Tích', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF081A30),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(Icons.emoji_events_outlined, color: Color(0xFFECC741), size: 56),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hồ sơ định hướng của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dựa trên phân tích toàn diện từ AI',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _buildSummaryCard(
              title: 'Tóm tắt phân tích định hướng từ AI',
              child: Text(
                overallSummary.isNotEmpty
                    ? overallSummary
                    : 'Không tìm thấy kết quả phân tích định hướng từ AI. Vui lòng liên hệ quản trị viên hoặc thử lại sau.',
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Trường đại học gợi ý phù hợp',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (aiRecommendations.isNotEmpty)
              ...aiRecommendations.map(_buildAiRecommendationCard)
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: const Text(
                    'Không tìm thấy gợi ý trường học từ AI. Hãy thử lại hoặc liên hệ quản trị viên.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                onReset();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.replay, color: Colors.white),
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

  Widget _buildAiRecommendationCard(AiUniversityRecommendation school) {
    final isTop3 = school.tier == 'top3';
    final Color accentColor = isTop3 ? const Color(0xFFECC741) : const Color(0xFF0ED8AB);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(isTop3 ? 0.3 : 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        school.name['vi'] ?? school.name['en'] ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isTop3 ? 'Tốt nhất' : 'Phù hợp',
                        style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Ngành đề xuất: ${school.major['vi'] ?? school.major['en'] ?? ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (school.place['vi']?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Địa điểm: ${school.place['vi']!}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${school.matchPercent}%',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
