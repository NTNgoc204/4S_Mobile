class PaymentTransaction {
  final String transactionId;
  final String planName;
  final double amount;
  final String paymentMethod;
  final String transactionCode;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String status;

  const PaymentTransaction({
    required this.transactionId,
    required this.planName,
    required this.amount,
    required this.paymentMethod,
    required this.transactionCode,
    required this.createdAt,
    this.paidAt,
    required this.status,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      transactionId: json['transactionId'] as String? ?? '',
      planName: json['planName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      transactionCode: json['transactionCode'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'] as String)
          : null,
      status: json['status'] as String? ?? '',
    );
  }
}
