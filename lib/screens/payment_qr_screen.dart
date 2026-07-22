import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/payment_service.dart';

class PaymentQRScreen extends StatefulWidget {
  final Map<String, dynamic> paymentInfo;
  const PaymentQRScreen({super.key, required this.paymentInfo});

  @override
  State<PaymentQRScreen> createState() => _PaymentQRScreenState();
}

class _PaymentQRScreenState extends State<PaymentQRScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  int _timeLeft = 300; // 5 minutes (PayOS expiration)
  Timer? _countdownTimer;
  Timer? _pollingTimer;
  bool _isDisposed = false;
  bool _isProcessingCancel = false;
  bool _isDownloading = false;
  String _initialPlanCode = 'free';

  @override
  void initState() {
    super.initState();
    // Cache the user's initial plan code to detect the change.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = AppState.of(context, listen: false);
      _initialPlanCode = appState.currentUser?.currentPlan ?? 'free';
    });

    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isDisposed) return;
      if (_timeLeft <= 1) {
        timer.cancel();
        await _handleTimeout();
      } else {
        setState(() {
          _timeLeft--;
        });
      }
    });
  }

  Future<void> _handleTimeout() async {
    if (_isProcessingCancel) return;
    _isProcessingCancel = true;

    try {
      await _cancelPaymentOnBackend();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giao dịch thanh toán đã hết hạn và bị hủy bỏ!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isDisposed) return;
      try {
        final profile = await AuthService.instance.getMe();
        if (_isDisposed) return;

        if (profile.currentPlan.toLowerCase() != _initialPlanCode.toLowerCase()) {
          // Success!
          timer.cancel();
          _countdownTimer?.cancel();

          // Push local notification
          final planName = widget.paymentInfo['planName'] ?? widget.paymentInfo['PlanName'] ?? 'Pro';
          await NotificationService.instance.showNotification(
            title: 'Thanh toán thành công',
            body: 'Gói $planName của bạn đã được kích hoạt thành công!',
          );

          if (mounted) {
            // Update global AppState
            AppState.of(context, listen: false).updateUserProfile(profile);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chúc mừng! Gói $planName đã kích hoạt thành công!'),
                backgroundColor: const Color(0xFF0ED8AB),
              ),
            );

            // Pop back to root home screen
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      } catch (_) {
        // Suppress network/polling errors to avoid throwing during transient drops
      }
    });
  }

  Future<void> _cancelPaymentOnBackend() async {
    final transactionCode = widget.paymentInfo['transactionCode'] ?? widget.paymentInfo['TransactionCode'] ?? '';
    if (transactionCode.isNotEmpty) {
      await PaymentService.instance.cancelPaymentTransaction(transactionCode);
    }
  }

  Future<void> _handleManualCancel() async {
    if (_isProcessingCancel) return;
    setState(() {
      _isProcessingCancel = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFECC741)),
      ),
    );

    try {
      await _cancelPaymentOnBackend();
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop(); // dismiss loading dialog
      Navigator.of(context).pop(); // pop payment screen
    }
  }

  Future<void> _downloadQRCard() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    try {
      // 1. Capture widget to image
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Không tìm thấy khung ảnh cần tải xuống');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Lỗi chuyển đổi dữ liệu hình ảnh');
      }
      final bytes = byteData.buffer.asUint8List();

      // 2. Request permissions and save to gallery
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          throw StateError('Quyền truy cập thư viện ảnh bị từ chối');
        }
      }

      await Gal.putImageBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tải hình ảnh QR thanh toán vào thư viện ảnh!'),
            backgroundColor: Color(0xFF0ED8AB),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải ảnh: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text, String fieldLabel) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $fieldLabel vào bộ nhớ tạm!'),
        backgroundColor: const Color(0xFF0F1E36),
        duration: const Duration(seconds: 2),
      ),
    );
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
    final qrCode = widget.paymentInfo['qrCode'] ?? widget.paymentInfo['QrCode'] ?? '';
    final bankName = widget.paymentInfo['bankName'] ?? widget.paymentInfo['bank'] ?? widget.paymentInfo['Bin'] ?? widget.paymentInfo['bin'] ?? 'VietQR';
    final accountNumber = widget.paymentInfo['accountNumber'] ?? widget.paymentInfo['AccountNumber'] ?? '';
    final accountName = widget.paymentInfo['accountName'] ?? widget.paymentInfo['AccountName'] ?? '';
    final amount = (widget.paymentInfo['amount'] ?? widget.paymentInfo['Amount'] ?? 0.0) as num;
    final description = widget.paymentInfo['description'] ?? widget.paymentInfo['Description'] ?? '';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleManualCancel();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF081326),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1E36),
          title: const Text(
            'Thanh Toán Đăng Ký',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _handleManualCancel,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Quét mã QR để Thanh toán',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mở ứng dụng ngân hàng hoặc ví điện tử để quét mã.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // VietQR Frame Card
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.82,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.55),
                          blurRadius: 34,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: AspectRatio(
                        aspectRatio: 960 / 1079,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/vietqr-frame.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Stack(
                                    children: [
                                      Positioned(
                                        left: constraints.maxWidth * 0.208,
                                        top: constraints.maxHeight * 0.20,
                                        width: constraints.maxWidth * 0.59,
                                        height: constraints.maxWidth * 0.59,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0EFEA),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: qrCode.isNotEmpty
                                              ? QrImageView(
                                                  data: qrCode,
                                                  version: QrVersions.auto,
                                                  backgroundColor: Colors.white,
                                                )
                                              : const Center(
                                                  child: Text(
                                                    'Đang tạo mã QR...',
                                                    style: TextStyle(color: Colors.black45, fontSize: 12),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Countdown Timer
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Thời gian còn lại',
                        style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(_timeLeft),
                        style: const TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Ngân hàng', bankName.toUpperCase(), isCopyable: false),
                      const Divider(color: Colors.white10, height: 24),
                      _buildDetailRow('Số tài khoản', accountNumber, isCopyable: true, fieldName: 'số tài khoản'),
                      const Divider(color: Colors.white10, height: 24),
                      _buildDetailRow('Chủ tài khoản', accountName.toUpperCase(), isCopyable: false),
                      const Divider(color: Colors.white10, height: 24),
                      _buildDetailRow('Số tiền', _formatVnd(amount.toDouble()), isCopyable: false),
                      const Divider(color: Colors.white10, height: 24),
                      _buildDetailRow('Nội dung chuyển khoản', description, isCopyable: true, fieldName: 'nội dung', isHighlight: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _isDownloading ? null : _downloadQRCard,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFECC741),
                          foregroundColor: const Color(0xFF0F1E36),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F1E36)),
                              )
                            : const Icon(Icons.download, size: 18),
                        label: Text(
                          _isDownloading ? 'Đang lưu...' : 'Tải xuống ảnh QR',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Đang chờ thanh toán trực tuyến...',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {required bool isCopyable, String? fieldName, bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: isHighlight ? const Color(0xFFECC741) : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCopyable) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _copyToClipboard(value, fieldName ?? ''),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.copy, size: 14, color: Colors.white70),
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
