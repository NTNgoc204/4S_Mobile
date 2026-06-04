import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/auth_validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService.instance;

  int _step = 1;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.forgotPassword(_email);
      if (!mounted) return;
      setState(() {
        _step = 2;
        _isLoading = false;
      });
      _showSnackBar('Mã OTP đã được gửi đến email của bạn.');
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> _verifyOtpLocally() async {
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() {
      _step = 3;
      _errorMessage = null;
    });
  }

  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.resetPassword(
        email: _email,
        otp: _otpController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      _showSnackBar('Đặt lại mật khẩu thành công. Vui lòng đăng nhập.');
      Navigator.of(context).pop();
    } catch (error) {
      _setError(error);
    }
  }

  String get _email => _emailController.text.trim().toLowerCase();

  void _setError(Object error) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = _authService.getErrorMessage(error);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF0ED8AB)),
    );
  }

  void _goBack() {
    if (_isLoading) return;
    if (_step == 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _step -= 1;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E36),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _goBack,
        ),
        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1E36), Color(0xFF081326)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  _buildErrorBox(_errorMessage!),
                  const SizedBox(height: 20),
                ],
                if (_step == 1)
                  _buildEmailForm()
                else if (_step == 2)
                  _buildOtpForm()
                else
                  _buildPasswordForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = _step == 1
        ? 'Nhận mã OTP'
        : _step == 2
            ? 'Xác thực OTP'
            : 'Đặt mật khẩu mới';
    final subtitle = _step == 1
        ? 'Nhập email tài khoản để nhận mã xác minh.'
        : _step == 2
            ? 'Nhập mã OTP đã được gửi đến $_email.'
            : 'Tạo mật khẩu mới cho tài khoản của bạn.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset, color: Color(0xFFECC741), size: 46),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFieldLabel('Email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('name@example.com'),
            validator: AuthValidators.validateEmail,
          ),
          const SizedBox(height: 28),
          _buildPrimaryButton('Gửi mã OTP', _sendOtp),
        ],
      ),
    );
  }

  Widget _buildOtpForm() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFieldLabel('Mã OTP'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _otpController,
            enabled: !_isLoading,
            maxLength: 6,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, letterSpacing: 4),
            decoration: _inputDecoration('Nhập mã 6 ký tự').copyWith(counterText: ''),
            validator: AuthValidators.validateOtp,
          ),
          const SizedBox(height: 28),
          _buildPrimaryButton('Tiếp tục', _verifyOtpLocally),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFieldLabel('Mật khẩu mới'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('••••••••').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white60,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            validator: AuthValidators.validateStrongPassword,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Xác nhận mật khẩu mới'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            enabled: !_isLoading,
            obscureText: !_showConfirmPassword,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('••••••••').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white60,
                ),
                onPressed: () => setState(
                  () => _showConfirmPassword = !_showConfirmPassword,
                ),
              ),
            ),
            validator: (value) => AuthValidators.validateConfirmPassword(
              value,
              _passwordController.text,
            ),
          ),
          const SizedBox(height: 28),
          _buildPrimaryButton('Đặt lại mật khẩu', _resetPassword),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String label, Future<void> Function() onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0F1E36),
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFFF8A8A), fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
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
