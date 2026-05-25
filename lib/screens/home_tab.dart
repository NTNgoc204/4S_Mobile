import 'package:flutter/material.dart';
import '../main.dart';
import 'profile_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _activeTestimonialIndex = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _testimonials = [
    {
      'quote': 'Dữ liệu học phí thực tế giúp mình lập ngân sách dễ dàng hơn và không còn chi phí ẩn.',
      'name': 'Thư Hương Lê',
      'role': 'Sinh viên đại học',
    },
    {
      'quote': 'Nhờ bài trắc nghiệm tính cách và bán cầu não mà mình tìm được ngành IT vô cùng phù hợp tại Bách Khoa.',
      'name': 'Trần Hoàng Long',
      'role': 'Cựu học sinh THPT',
    },
    {
      'quote': 'Chatbot AI trả lời rất thông minh và đưa ra lời khuyên rất cụ thể về học bổng và cơ hội nghề nghiệp.',
      'name': 'Minh Thư Nguyễn',
      'role': 'Học sinh lớp 12',
    }
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showStatBottomSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1E36),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFECC741)),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),
              Text(
                content,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFECC741),
                  foregroundColor: const Color(0xFF0F1E36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Đồng ý', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final user = appState.currentUser!;
    final plan = user.currentPlan;

    return RefreshIndicator(
      color: const Color(0xFFECC741),
      backgroundColor: const Color(0xFF0F1E36),
      onRefresh: () async {
        // Native mobile pull to refresh experience
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật bảng tin định hướng mới nhất!'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF0ED8AB),
            ),
          );
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh always triggers
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. App Introduction Hero
            _buildHeroCard(user),
            const SizedBox(height: 18),

            // 2. Plan Quick Action Banner
            _buildPlanCard(plan),
            const SizedBox(height: 18),

            // 3. Stats Section (Tappable for details)
            _buildStatsSection(),
            const SizedBox(height: 24),

            // 4. Feature Highlights
            const Text(
              'Tính năng cốt lõi',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.chat_bubble_outline,
              title: 'Trợ lý AI Chatbot',
              desc: 'Trò chuyện tự nhiên với AI để tìm ngành học phù hợp, so sánh học phí và học bổng tuyển sinh.',
              color: const Color(0xFFECC741),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.monetization_on_outlined,
              title: 'Học phí thực tế',
              desc: 'Tổng hợp mức học phí tự học, phụ phí từ sinh viên các trường để bạn chuẩn bị tài chính tốt nhất.',
              color: const Color(0xFF0ED8AB),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.radar_outlined,
              title: 'Điểm tương thích chuyên sâu',
              desc: 'Đánh giá mức độ hòa hợp của bạn với từng trường dựa vào sở thích và điểm thi trung bình.',
              color: const Color(0xFF7F8CFF),
            ),
            const SizedBox(height: 24),

            // 5. Testimonial Section (Swipeable PageView)
            const Text(
              'Đánh giá từ người dùng',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3),
            ),
            const SizedBox(height: 12),
            _buildTestimonials(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3451).withOpacity(0.9),
            const Color(0xFF182C47).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECC741).withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFECC741), size: 12),
                SizedBox(width: 4),
                Text(
                  'CÔNG NGHỆ AI DẪN LỐI',
                  style: TextStyle(color: Color(0xFFECC741), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Chào ${user.fullName.split(' ').last},',
            style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text(
            'La Bàn AI dẫn lối tương lai học tập',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Khám phá trường đại học và lộ trình nghề nghiệp phù hợp với năng lực, sở thích và tài chính của bạn bằng dữ liệu thực tế từ sinh viên.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String plan) {
    Color planColor = plan == 'pro'
        ? const Color(0xFFECC741)
        : plan == 'edu'
            ? const Color(0xFF7F8CFF)
            : const Color(0xFF0ED8AB);

    String planLabel = plan.toUpperCase();

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: planColor.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: planColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.star_border_purple500, color: planColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tài khoản của bạn', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    'Gói dịch vụ: $planLabel',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTappableStatItem(
            value: '10,000+',
            label: 'Sinh viên',
            onTap: () => _showStatBottomSheet(
              'Số lượng học sinh đã hỗ trợ',
              'Hơn 10,000+ học sinh THPT trên toàn quốc đã hoàn tất khảo sát trắc nghiệm và sử dụng chatbot CareerGuidanceAI để lựa chọn đúng nguyện vọng trong kỳ thi THPT Quốc Gia.',
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white10),
          _buildTappableStatItem(
            value: '200+',
            label: 'Trường học',
            onTap: () => _showStatBottomSheet(
              'Hệ thống trường đại học',
              'Thông tin chi tiết của hơn 200+ trường Đại học, Cao đẳng, Học viện công lập và tư thục trên cả nước với đầy đủ dữ liệu học phí thực tế và các chương trình học bổng.',
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white10),
          _buildTappableStatItem(
            value: '4.9/5',
            label: 'Đánh giá',
            onTap: () => _showStatBottomSheet(
              'Mức độ hài lòng người dùng',
              'Điểm số trung bình dựa trên đánh giá trực tiếp từ phụ huynh và học sinh về độ chính xác của bài kiểm tra tính cách và tính hữu ích của chatbot AI trong định hướng tương lai.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableStatItem({
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(color: Color(0xFFECC741), fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
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
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonials() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3451).withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3451).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.format_quote, color: Color(0xFFECC741), size: 32),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _testimonials.length,
              onPageChanged: (index) {
                setState(() {
                  _activeTestimonialIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final item = _testimonials[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['quote']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item['name']!,
                        style: const TextStyle(color: Color(0xFFECC741), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        item['role']!,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _testimonials.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _activeTestimonialIndex == index ? const Color(0xFFECC741) : Colors.white24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
