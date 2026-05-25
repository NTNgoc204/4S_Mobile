import 'package:flutter/material.dart';
import '../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  int _step = 1; // 1 or 2
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1 Controllers
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2 Controllers
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _otpVerified = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleStep1Submit() async {
    if (!_step1FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate OTP sending API
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _step = 2; // Transition to OTP validation
    });
  }

  void _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (otp == '123456') {
      setState(() {
        _isLoading = false;
        _otpVerified = true;
      });
    } else {
      setState(() {
        _isLoading = false;
        _otpVerified = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã OTP không đúng. Thử lại với "123456".')),
      );
    }
  }

  void _handleStep2Submit() async {
    if (!_step2FormKey.currentState!.validate()) return;

    if (!_otpVerified) {
      setState(() {
        _errorMessage = 'Vui lòng xác thực mã OTP trước khi tiếp tục.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate account creation
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    // Login directly using global AppState
    AppState.of(context, listen: false).login(
      email: _emailController.text.trim().toLowerCase(),
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _dobController.text,
      address: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    // Close register stack and return to home
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E36),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_step == 2) {
              setState(() {
                _step = 1;
                _otpVerified = false;
                _otpController.clear();
                _passwordController.clear();
                _confirmPasswordController.clear();
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _step == 1 ? 'Đăng ký tài khoản (1/2)' : 'Xác thực OTP & Mật khẩu (2/2)',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F1E36),
              Color(0xFF081326),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFFF8A8A), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_step == 1) _buildStep1Form() else _buildStep2Form(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Form() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email
          _buildFieldLabel('Email *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            decoration: _getInputDecoration('name@example.com'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Email không được để trống';
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Họ tên
          _buildFieldLabel('Họ và tên *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fullNameController,
            style: const TextStyle(color: Colors.white),
            enabled: !_isLoading,
            decoration: _getInputDecoration('Nhập họ và tên'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Họ tên không được để trống';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Ngày sinh
          _buildFieldLabel('Ngày sinh *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _dobController,
            style: const TextStyle(color: Colors.white),
            enabled: !_isLoading,
            readOnly: true,
            decoration: _getInputDecoration('YYYY-MM-DD').copyWith(
              suffixIcon: const Icon(Icons.calendar_today, color: Colors.white60),
            ),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2008),
                firstDate: DateTime(1990),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _dobController.text = picked.toIsoverbatim();
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng chọn ngày sinh';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Địa chỉ
          _buildFieldLabel('Địa chỉ *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            style: const TextStyle(color: Colors.white),
            enabled: !_isLoading,
            decoration: _getInputDecoration('Nhập địa chỉ của bạn'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Địa chỉ không được để trống';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Số điện thoại
          _buildFieldLabel('Số điện thoại *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            enabled: !_isLoading,
            decoration: _getInputDecoration('Nhập số điện thoại'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Số điện thoại không được để trống';
              return null;
            },
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isLoading ? null : _handleStep1Submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFECC741),
              foregroundColor: const Color(0xFF0F1E36),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F1E36)),
                  )
                : const Text('Tiếp tục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Form() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0ED8AB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0ED8AB).withOpacity(0.2)),
            ),
            child: Text(
              'Mã OTP đã được gửi đến:\n${_emailController.text}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),

          // OTP
          _buildFieldLabel('Mã OTP *'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _otpController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  enabled: !_isLoading && !_otpVerified,
                  maxLength: 6,
                  decoration: _getInputDecoration('Nhập mã 6 số').copyWith(counterText: ''),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading || _otpVerified ? null : _handleVerifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _otpVerified ? const Color(0xFF0ED8AB) : const Color(0xFFECC741),
                  foregroundColor: const Color(0xFF0F1E36),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_otpVerified ? 'Đã xác thực' : 'Kiểm tra OTP'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Demo: Nhập mã "123456"',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Mật khẩu
          _buildFieldLabel('Mật khẩu *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white),
            enabled: !_isLoading && _otpVerified,
            decoration: _getInputDecoration('••••••••').copyWith(
              suffixIcon: _otpVerified
                  ? IconButton(
                      icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.white60),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Mật khẩu không được để trống';
              if (value.length < 6) return 'Mật khẩu phải từ 6 ký tự trở lên';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Xác nhận mật khẩu
          _buildFieldLabel('Xác nhận mật khẩu *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            style: const TextStyle(color: Colors.white),
            enabled: !_isLoading && _otpVerified,
            decoration: _getInputDecoration('••••••••').copyWith(
              suffixIcon: _otpVerified
                  ? IconButton(
                      icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off, color: Colors.white60),
                      onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Xác nhận lại mật khẩu';
              if (value != _passwordController.text) return 'Mật khẩu không khớp';
              return null;
            },
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isLoading || !_otpVerified ? null : _handleStep2Submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFECC741),
              foregroundColor: const Color(0xFF0F1E36),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: const Color(0xFFECC741).withOpacity(0.4),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F1E36)),
                  )
                : const Text('Hoàn tất đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFECC741)),
      ),
    );
  }
}

extension VerbatimDate on DateTime {
  String toIsoverbatim() {
    String year = this.year.toString();
    String month = this.month.toString().padLeft(2, '0');
    String day = this.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
