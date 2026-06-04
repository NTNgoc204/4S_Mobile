import 'package:flutter/material.dart';

class PricingTab extends StatelessWidget {
  const PricingTab({super.key});

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
      child: ListView(
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
          _PricingCard(
            title: 'Free',
            description: 'Phù hợp để khám phá và bắt đầu',
            amount: 0,
            isFree: true,
            period: '/ trọn đời',
            accentColor: Color(0xFF0ED8AB),
            badge: '',
            features: const [
              'Tư vấn hướng nghiệp AI cơ bản',
              'Truy cập 50+ trường đại học',
              'Gợi ý ngành học cơ bản',
              'Giới hạn số lượt hỏi AI mỗi ngày',
              'Thông tin tuyển sinh cơ bản',
            ],
          ),
          const SizedBox(height: 14),
          _PricingCard(
            title: 'Pro',
            description: 'Dành cho học sinh cần định hướng chuyên sâu',
            amount: 270000,
            isFree: false,
            period: '/ tháng',
            accentColor: Color(0xFFECC741),
            badge: 'Phổ Biến Nhất',
            features: const [
              'Tư vấn AI không giới hạn',
              'Truy cập 200+ trường đại học',
              'Phân tích độ phù hợp nghề nghiệp nâng cao',
              'Gợi ý ngành học cá nhân hóa',
              'Ưu tiên tốc độ phản hồi AI',
            ],
          ),
          const SizedBox(height: 14),
          _PricingCard(
            title: 'Edu',
            description: 'Dành cho trường học & tổ chức giáo dục',
            amount: 0,
            isFree: false,
            period: '',
            accentColor: Color(0xFF7F8CFF),
            badge: 'Dành Cho Trường',
            features: const [
              'Bao gồm toàn bộ tính năng Pro',
              'Dashboard phân tích hướng nghiệp học sinh',
              'Quản lý nhiều tài khoản học sinh',
              'Đánh giá hướng nghiệp AI cho học sinh',
              'Bảng điều khiển quản trị nhà trường',
              'Kho dữ liệu ngành học & trường đại học',
            ],
          ),
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
    this.isFree = false,
    required this.period,
    required this.accentColor,
    required this.badge,
    required this.features,
  });

  final String title;
  final String description;
  final int amount;
  final bool isFree;
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
              // action placeholder - parent can wrap or replace this widget
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withOpacity(0.35)),
              ),
              child: Text(
                _ctaLabel(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
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
    if (isFree) return 'Hoàn tất đăng ký';
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
