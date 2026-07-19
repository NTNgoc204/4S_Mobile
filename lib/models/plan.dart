class PricingPlan {
  final String id;
  final String name;
  final String description;
  final double price;

  PricingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  factory PricingPlan.fromJson(Map<String, dynamic> json) {
    return PricingPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get planCode {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('free')) return 'free';
    if (nameLower.contains('pro')) return 'pro';
    return 'edu';
  }
}
