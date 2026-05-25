import 'package:flutter/material.dart';
import '../main.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate API call matching backend delay
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final appState = AppState.of(context, listen: false);
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    // Standard login validation or demo user login
    if (email == 'demo@4s.com' && password == '123456') {
      appState.login(
        email: email,
        fullName: 'Nguyễn Văn Demo',
        dateOfBirth: '2008-10-12',
        address: 'Hồ Chí Minh, Việt Nam',
        phoneNumber: '0987654321',
      );
    } else if (password.length >= 6) {
      // Allow any user with password >= 6 characters for ease of testing
      appState.login(
        email: email,
        fullName: email.split('@')[0].toUpperCase(),
        dateOfBirth: '2008-01-01',
        address: 'TP. Hồ Chí Minh',
        phoneNumber: '0912345678',
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Email hoặc mật khẩu không chính xác (mật khẩu phải từ 6 ký tự).';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F1E36), // Deep blue-indigo
              Color(0xFF081326), // Dark midnight blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo Area
                    Center(
                      child: Container(
                        height: 76,
                        width: 76,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFE16D), Color(0xFFDEB320)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEDC42E).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.explore,
                          size: 40,
                          color: Color(0xFF0F1E36),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Titles
                    const Text(
                      'Chào mừng trở lại',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng nhập để tiếp tục lộ trình định hướng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error Message
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

                    // Email Field
                    const Text(
                      'Địa chỉ Email',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        hintText: 'name@example.com',
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFECC741)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email không được để trống';
                        }
                        final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    const Text(
                      'Mật khẩu',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: const TextStyle(color: Colors.white),
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: Colors.white30),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white60,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFECC741)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mật khẩu không được để trống';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải chứa ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFECC741),
                        foregroundColor: const Color(0xFF0F1E36),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        disabledBackgroundColor: const Color(0xFFECC741).withOpacity(0.5),
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
                          : const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_isLoading) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              color: Color(0xFFECC741),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
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
      ),
    );
  }
}
