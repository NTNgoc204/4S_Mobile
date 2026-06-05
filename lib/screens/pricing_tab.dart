import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../services/auth_service.dart';

class PricingTab extends StatefulWidget {
  const PricingTab({super.key});

  @override
  State<PricingTab> createState() => _PricingTabState();
}

class _PricingTabState extends State<PricingTab> {
  final AuthService _authService = AuthService.instance;
  List<PricingPlan> _plans = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final plans = await _authService.getPlans();
      // Sort plans so 'free' is first, then 'pro', then 'edu'
      final sortOrder = {'free': 0, 'pro': 1, 'edu': 2};
      plans.sort((a, b) => (sortOrder[a.planCode] ?? 99).compareTo(sortOrder[b.planCode] ?? 99));

      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _authService.getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  List<PricingPlan> get _displayPlans {
    if (_plans.isNotEmpty) return _plans;
    // Fallback static plans in case backend response is empty
    return [
      PricingPlan(id: 'free', name: 'Free', description: 'Phù hợp để khám phá và bắt đầu', price: 0.0),
      PricingPlan(id: 'pro', name: 'Pro', description: 'Dành cho học sinh cần định hướng chuyên sâu', price: 270000.0),
      PricingPlan(id: 'edu', name: 'Edu', description: 'Dành cho trường học & tổ chức giáo dục', price: 0.0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F1E36), Color(0xFF081326)],
        ),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFECC741),
              ),
            )
          : _errorMessage != null && _plans.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _fetchPlans();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFECC741),
                            foregroundColor: const Color(0xFF0F1E36),
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Bảng Giá Minh Bạch & Đơn Giản',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bắt đầu miễn phí hoặc mở khóa toàn bộ tính năng cao cấp.',
                      style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    ..._displayPlans.map((plan) {
                      final planCode = plan.planCode;
                      Color accentColor;
                      String badge;
                      List<String> features;
                      String period;

                      if (planCode == 'free') {
                        accentColor = const Color(0xFF0ED8AB);
                        badge = '';
                        period = '/ trọn đời';
                        features = const [
                          'Tư vấn hướng nghiệp AI cơ bản',
                          'Truy cập 50+ trường đại học',
                          'Gợi ý ngành học cơ bản',
                          'Giới hạn số lượt hỏi AI mỗi ngày',
                          'Thông tin tuyển sinh cơ bản',
                        ];
                      } else if (planCode == 'pro') {
                        accentColor = const Color(0xFFECC741);
                        badge = 'Phổ Biến Nhất';
                        period = '/ tháng';
                        features = const [
                          'Tư vấn AI không giới hạn',
                          'Truy cập 200+ trường đại học',
                          'Phân tích độ phù hợp nghề nghiệp nâng cao',
                          'Gợi ý ngành học cá nhân hóa',
                          'Ưu tiên tốc độ phản hồi AI',
                        ];
                      } else {
                        accentColor = const Color(0xFF7F8CFF);
                        badge = 'Dành Cho Trường';
                        period = '';
                        features = const [
                          'Bao gồm toàn bộ tính năng Pro',
                          'Dashboard phân tích hướng nghiệp học sinh',
                          'Quản lý nhiều tài khoản học sinh',
                          'Đánh giá hướng nghiệp AI cho học sinh',
                          'Bảng điều khiển quản trị nhà trường',
                          'Kho dữ liệu ngành học & trường đại học',
                        ];
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: _PricingCard(
                          title: plan.name,
                          description: plan.description,
                          amount: plan.price.toInt(),
                          isFree: planCode == 'free',
                          planCode: planCode,
                          period: period,
                          accentColor: accentColor,
                          badge: badge,
                          features: features,
                        ),
                      );
                    }),
                    const SizedBox(height: 18),
                    const Text(
                      'Tất cả gói đều bao gồm bảo mật dữ liệu và cam kết uptime 99.9%.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.title,
    required this.description,
    required this.amount,
    required this.isFree,
    required this.planCode,
    required this.period,
    required this.accentColor,
    required this.badge,
    required this.features,
  });

  final String title;
  final String description;
  final int amount;
  final bool isFree;
  final String planCode;
  final String period;
  final Color accentColor;
  final String badge;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (badge.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _displayPrice(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                period,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 14),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: accentColor, size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              if (isFree) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bạn đang sử dụng gói ${title.toUpperCase()}!'),
                    backgroundColor: accentColor,
                  ),
                );
                return;
              }
              if (!isFree && amount == 0) {
                // Contact
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng liên hệ với nhà trường để đăng ký gói này!'),
                    backgroundColor: Color(0xFF7F8CFF),
                  ),
                );
                return;
              }
              // Inform user that checkout should be done on the website
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng thanh toán trên ứng dụng di động đang được phát triển. Vui lòng thực hiện trên website!'),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: accentColor, // Solid color background
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _ctaLabel(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: planCode == 'pro' ? const Color(0xFF081326) : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _displayPrice() {
    if (isFree) return 'Miễn phí';
    if (!isFree && amount == 0) return 'Liên hệ';
    return _formatVnd(amount);
  }

  String _ctaLabel() {
    if (isFree) return 'Đang sử dụng';
    if (!isFree && amount == 0) return 'Liên hệ ngay';
    return 'Thanh toán';
  }

  String _formatVnd(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write(',');
    }
    final formatted = buffer.toString().split('').reversed.join();
    return '$formatted ₫';
  }
}
