class AuthValidators {
  AuthValidators._();

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email không được để trống';
    if (!_emailRegex.hasMatch(email)) return 'Email không hợp lệ';
    return null;
  }

  static String? validateRequired(String? value, String message) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }

  static String? validateOtp(String? value) {
    final otp = value?.trim() ?? '';
    if (otp.isEmpty) return 'Vui lòng nhập mã OTP';
    if (otp.length != 6) return 'Mã OTP phải gồm 6 ký tự';
    return null;
  }

  static String? validateStrongPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (password.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
    if (!RegExp(r'[A-Z]').hasMatch(password))
      return 'Mật khẩu phải có ít nhất 1 chữ hoa';
    if (!RegExp(r'[a-z]').hasMatch(password))
      return 'Mật khẩu phải có ít nhất 1 chữ thường';
    if (!RegExp(r'[0-9]').hasMatch(password))
      return 'Mật khẩu phải có ít nhất 1 chữ số';
    if (!RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]').hasMatch(password))
      return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt';
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (value != password) return 'Mật khẩu xác nhận không khớp';
    return null;
  }
}
