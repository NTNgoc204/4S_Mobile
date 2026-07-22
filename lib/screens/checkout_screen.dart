import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../main.dart';
import '../models/plan.dart';
import '../services/payment_service.dart';
import 'payment_qr_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final PricingPlan plan;
  const CheckoutScreen({super.key, required this.plan});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final PaymentService _paymentService = PaymentService.instance;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleConfirm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _paymentService.createPaymentTransaction(widget.plan.id);

      if (!mounted) return;

      if (data.isEmpty) {
        throw StateError('Không nhận được dữ liệu thanh toán từ máy chủ');
      }

      // Navigate to QR payment screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentQRScreen(paymentInfo: data),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e is DioException) {
          final errorData = e.response?.data;
          if (errorData is String) {
            _errorMessage = errorData;
          } else if (errorData is Map<String, dynamic>) {
            _errorMessage = errorData['message'] ?? errorData['error'] ?? 'Lỗi tạo giao dịch';
          } else {
            _errorMessage = 'Lỗi kết nối máy chủ';
          }
        } else {
          _errorMessage = e.toString();
        }
      });
    }
  }

  String _formatVnd(double value) {
    final s = value.toInt().toString();
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

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF081326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E36),
        title: const Text(
          'Xác Nhận Đăng Ký',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1E36), Color(0xFF081326)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Thông Tin Đăng Ký',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Customer details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'THÔNG TIN KHÁCH HÀNG',
                          style: TextStyle(
                            color: Color(0xFFECC741),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Họ và tên:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                user?.fullName ?? user?.email.split('@')[0] ?? '',
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Email:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                user?.email ?? '',
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Plan details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'THÔNG TIN GÓI DỊCH VỤ',
                          style: TextStyle(
                            color: Color(0xFFECC741),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Gói đăng ký:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                            Text(
                              widget.plan.name == 'PRO' ? 'Pro Pack' : widget.plan.name == 'EDU' ? 'Edu Pack' : widget.plan.name,
                              style: const TextStyle(color: Color(0xFFECC741), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Đơn giá:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                            Text(
                              widget.plan.price == 0 ? 'Liên hệ' : '${_formatVnd(widget.plan.price)}${widget.plan.planCode == 'pro' ? ' / tháng' : ''}',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng tiền:', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(
                              widget.plan.price == 0 ? 'Liên hệ' : _formatVnd(widget.plan.price),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.12)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Quay lại', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFECC741),
                            foregroundColor: const Color(0xFF0F1E36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(color: Color(0xFF0F1E36), strokeWidth: 2),
                                )
                              : const Text('Xác nhận', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
