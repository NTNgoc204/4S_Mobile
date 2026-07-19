import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/auth_validators.dart';
import '../utils/phone_validator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;
  String? _verifyToken;

  final AuthService _authService = AuthService.instance;

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

  Future<void> _handleStep1Submit() async {
    if (!_step1FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.registerStep1(
        email: _email,
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
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

  Future<void> _handleVerifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final verifyToken = await _authService.verifyRegisterOtp(
        email: _email,
        otp: _otpController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _verifyToken = verifyToken;
        _step = 3;
        _isLoading = false;
      });
      _showSnackBar('Xác thực OTP thành công.');
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> _handleRegisterSubmit() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    final verifyToken = _verifyToken;
    if (verifyToken == null || verifyToken.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng xác thực OTP trước.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.registerStep3(
        verifyToken: verifyToken,
        password: _passwordController.text,
      );
      if (!mounted) return;
      _showSnackBar('Đăng ký thành công. Vui lòng đăng nhập.');
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
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0ED8AB),
      ),
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
      if (_step < 3) {
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
      if (_step < 2) {
        _otpController.clear();
        _verifyToken = null;
      }
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
        title: Text(
          _title,
          style: const TextStyle(
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
                _buildStepHeader(),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  _buildErrorBox(_errorMessage!),
                  const SizedBox(height: 20),
                ],
                if (_step == 1)
                  _buildStep1Form()
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

  String get _title {
    if (_step == 1) return 'Đăng ký tài khoản';
    if (_step == 2) return 'Xác thực OTP';
    return 'Tạo mật khẩu';
  }

  Widget _buildStepHeader() {
    final subtitle = _step == 1
        ? 'Nhập thông tin cá nhân để nhận mã OTP.'
        : _step == 2
        ? 'Nhập mã OTP đã được gửi đến $_email.'
        : 'Tạo mật khẩu mạnh để hoàn tất đăng ký.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1Form() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFieldLabel('Email *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            decoration: _inputDecoration('name@example.com'),
            validator: AuthValidators.validateEmail,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Họ và tên *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fullNameController,
            style: const TextStyle(color: Colors.white),
            enabled: !_isLoading,
            decoration: _inputDecoration('Nhập họ và tên'),
            validator: (value) => AuthValidators.validateRequired(
              value,
              'Họ tên không được để trống',
            ),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Ngày sinh *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _dobController,
            style: const TextStyle(color: Colors.white),
            enabled: !_isLoading,
            readOnly: true,
            decoration: _inputDecoration('YYYY-MM-DD').copyWith(
              suffixIcon: const Icon(
                Icons.calendar_today,
                color: Colors.white60,
              ),
            ),
            onTap: _pickDateOfBirth,
            validator: (value) => AuthValidators.validateRequired(
              value,
              'Vui lòng chọn ngày sinh',
            ),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Địa chỉ *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            style: const TextStyle(color: Colors.white),
            enabled: !_isLoading,
            decoration: _inputDecoration('Nhập địa chỉ của bạn'),
            validator: (value) => AuthValidators.validateRequired(
              value,
              'Địa chỉ không được để trống',
            ),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Số điện thoại *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            enabled: !_isLoading,
            decoration: _inputDecoration('Nhập số điện thoại'),
            validator: PhoneValidator.validateVietnamPhone,
          ),
          const SizedBox(height: 32),
          _buildPrimaryButton('Gửi mã OTP', _handleStep1Submit),
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
          _buildFieldLabel('Mã OTP *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _otpController,
            style: const TextStyle(color: Colors.white, letterSpacing: 4),
            keyboardType: TextInputType.number,
            enabled: !_isLoading,
            maxLength: 6,
            textAlign: TextAlign.center,
            decoration: _inputDecoration(
              'Nhập mã 6 ký tự',
            ).copyWith(counterText: ''),
            validator: AuthValidators.validateOtp,
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton('Xác thực OTP', _handleVerifyOtp),
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
          _buildFieldLabel('Mật khẩu *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white),
            enabled: !_isLoading,
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
          _buildFieldLabel('Xác nhận mật khẩu *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            style: const TextStyle(color: Colors.white),
            enabled: !_isLoading,
            decoration: _inputDecoration('••••••••').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
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
          const SizedBox(height: 32),
          _buildPrimaryButton('Hoàn tất đăng ký', _handleRegisterSubmit),
        ],
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2008),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;
    setState(() {
      _dobController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
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
