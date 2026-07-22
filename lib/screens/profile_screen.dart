import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/user.dart';
import '../models/payment_transaction.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../utils/auth_validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _changePasswordFormKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _gpaController;
  late TextEditingController _mathController;
  late TextEditingController _englishController;
  late TextEditingController _scienceController;

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late String _location;
  late double _maxTuition;
  late String _studyMode;

  bool _isSaving = false;
  bool _isLoggingOut = false;
  bool _isUploadingAvatar = false;
  bool _isChangingPassword = false;
  bool _showChangePassword = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isInitialized = false;
  String? _changePasswordError;

  List<PaymentTransaction>? _transactions;
  bool _isLoadingTransactions = false;
  String? _transactionsError;
  bool _isTransactionsExpanded = false;

  static const _locations = ['TP. Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng', 'Cần Thơ'];
  static const _studyModes = ['Tiếng Việt', 'Tiếng Anh', 'Song ngữ'];

  final AuthService _authService = AuthService.instance;

  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTransactions = true;
      _transactionsError = null;
    });
    try {
      final list = await PaymentService.instance.getMyTransactionHistory();
      if (!mounted) return;
      setState(() {
        _transactions = list;
        _isLoadingTransactions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _transactionsError = _authService.getErrorMessage(error);
        _isLoadingTransactions = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final profile = AppState.of(context, listen: false).currentUser!;
    _fullNameController = TextEditingController(text: profile.fullName);
    _dobController = TextEditingController(text: profile.dateOfBirth);
    _addressController = TextEditingController(text: profile.address);
    _phoneController = TextEditingController(text: profile.phoneNumber);
    _gpaController = TextEditingController(text: profile.gpa.toString());
    _mathController = TextEditingController(text: profile.mathScore.toString());
    _englishController = TextEditingController(text: profile.englishScore.toString());
    _scienceController = TextEditingController(text: profile.scienceScore.toString());
    _location = _locations.contains(profile.preferredLocation)
        ? profile.preferredLocation
        : _locations.first;
    _maxTuition = profile.maxTuition;
    _studyMode = _studyModes.contains(profile.studyMode)
        ? profile.studyMode
        : _studyModes.first;
    _isInitialized = true;
    _fetchTransactions();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gpaController.dispose();
    _mathController.dispose();
    _englishController.dispose();
    _scienceController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;

    XFile? image;
    try {
      image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showSnackBar(
        error.code == 'photo_access_denied'
            ? 'Ứng dụng chưa có quyền truy cập ảnh. Hãy cấp quyền trong Settings.'
            : 'Không mở được thư viện ảnh. Vui lòng thử lại.',
        isError: true,
      );
      return;
    }

    if (image == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    final appState = AppState.of(context, listen: false);

    try {
      await appState.uploadAvatar(image.path);
      if (!mounted) return;
      _showSnackBar('Cập nhật ảnh đại diện thành công.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(appState.getAuthErrorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final appState = AppState.of(context, listen: false);
    final updatedProfile = appState.currentUser!.copyWith(
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _dobController.text,
      address: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      gpa: double.tryParse(_gpaController.text) ?? 7.5,
      mathScore: double.tryParse(_mathController.text) ?? 75.0,
      englishScore: double.tryParse(_englishController.text) ?? 70.0,
      scienceScore: double.tryParse(_scienceController.text) ?? 65.0,
      preferredLocation: _location,
      maxTuition: _maxTuition,
      studyMode: _studyMode,
    );

    appState.updateUserProfile(updatedProfile);
    setState(() => _isSaving = false);
    _showSnackBar('Lưu thông tin hồ sơ thành công!');
  }

  Future<void> _changePassword() async {
    if (!_changePasswordFormKey.currentState!.validate()) return;

    setState(() {
      _isChangingPassword = true;
      _changePasswordError = null;
    });

    try {
      await _authService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _isChangingPassword = false;
        _showChangePassword = false;
      });
      _showSnackBar('Đổi mật khẩu thành công.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isChangingPassword = false;
        _changePasswordError = _authService.getErrorMessage(error);
      });
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final appState = AppState.of(context, listen: false);
    final navigator = Navigator.of(context);

    setState(() => _isLoggingOut = true);
    await appState.logout();

    if (!mounted) return;
    navigator.pop();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF0ED8AB),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final user = appState.currentUser;
    final currentPlan = user?.currentPlan ?? 'free';

    return Scaffold(
      backgroundColor: const Color(0xFF081326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E36),
        title: const Text(
          'Hồ sơ & Tài khoản',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (user != null) ...[
                  _buildProfileHeader(user),
                  const SizedBox(height: 28),
                ],
                _buildSectionHeader('Gói đăng ký hiện tại', Icons.card_membership),
                const SizedBox(height: 12),
                _buildActivePlanBanner(currentPlan),
                const SizedBox(height: 28),
                _buildTransactionHistorySection(),
                const SizedBox(height: 28),
                _buildSectionHeader('Thông tin cá nhân', Icons.person_outline),
                const SizedBox(height: 12),
                _buildGlassCard(child: _buildPersonalInfoFields()),
                const SizedBox(height: 28),
                _buildSectionHeader('Thông tin học tập', Icons.school_outlined),
                const SizedBox(height: 12),
                _buildGlassCard(child: _buildAcademicFields()),
                const SizedBox(height: 28),
                _buildSectionHeader('Tùy chọn học tập', Icons.settings_suggest_outlined),
                const SizedBox(height: 12),
                _buildGlassCard(child: _buildPreferenceFields()),
                const SizedBox(height: 28),
                _buildChangePasswordSection(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 16),
                _buildLogoutButton(appState),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile user) {
    final avatarUrl = user.avatarUrl.trim();
    final role = user.role.trim();

    return _buildGlassCard(
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
            child: SizedBox(
              height: 92,
              width: 92,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFECC741).withOpacity(0.6),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: avatarUrl.isEmpty
                            ? _buildAvatarFallback()
                            : Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                              ),
                      ),
                    ),
                  ),
                  if (_isUploadingAvatar)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.35),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFECC741),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (role.isNotEmpty) _buildProfileBadge(role),
                    _buildProfileBadge(user.currentPlan.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFF132D30),
      child: const Icon(Icons.person, color: Color(0xFFECC741), size: 40),
    );
  }

  Widget _buildProfileBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECC741).withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFECC741).withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFECC741),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoFields() {
    return Column(
      children: [
        _buildTextField(
          label: 'Họ và tên *',
          controller: _fullNameController,
          validator: (value) =>
              value!.trim().isEmpty ? 'Nhập họ tên' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Ngày sinh *',
          controller: _dobController,
          readOnly: true,
          onTap: _pickDateOfBirth,
        ),
        const SizedBox(height: 16),
        _buildTextField(label: 'Địa chỉ', controller: _addressController),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Số điện thoại',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildAcademicFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Điểm GPA (0-10)',
                controller: _gpaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Điểm Toán (0-100)',
                controller: _mathController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Điểm Anh (0-100)',
                controller: _englishController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Điểm Khoa học (0-100)',
                controller: _scienceController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferenceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDropdownField(
          label: 'Khu vực ưu tiên',
          value: _location,
          items: _locations,
          onChanged: (value) => setState(() => _location = value!),
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Hình thức học giảng dạy',
          value: _studyMode,
          items: _studyModes,
          onChanged: (value) => setState(() => _studyMode = value!),
        ),
        const SizedBox(height: 16),
        Text(
          'Học phí tối đa tham khảo: ${_maxTuition.toInt()}M VNĐ/năm',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Slider(
          value: _maxTuition,
          min: 10,
          max: 200,
          divisions: 19,
          activeColor: const Color(0xFFECC741),
          inactiveColor: Colors.white10,
          label: '${_maxTuition.toInt()} triệu/năm',
          onChanged: (value) => setState(() => _maxTuition = value),
        ),
      ],
    );
  }

  Widget _buildChangePasswordSection() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _isChangingPassword
                ? null
                : () {
                    setState(() {
                      _showChangePassword = !_showChangePassword;
                      _changePasswordError = null;
                    });
                  },
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Color(0xFFECC741), size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Đổi mật khẩu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  _showChangePassword
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
          if (_showChangePassword) ...[
            const SizedBox(height: 18),
            if (_changePasswordError != null) ...[
              _buildInlineError(_changePasswordError!),
              const SizedBox(height: 14),
            ],
            Form(
              key: _changePasswordFormKey,
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Mật khẩu hiện tại',
                    controller: _oldPasswordController,
                    obscureText: !_showOldPassword,
                    suffixIcon: _buildPasswordToggle(
                      visible: _showOldPassword,
                      onPressed: () => setState(
                        () => _showOldPassword = !_showOldPassword,
                      ),
                    ),
                    validator: (value) => AuthValidators.validateRequired(
                      value,
                      'Vui lòng nhập mật khẩu hiện tại',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    label: 'Mật khẩu mới',
                    controller: _newPasswordController,
                    obscureText: !_showNewPassword,
                    suffixIcon: _buildPasswordToggle(
                      visible: _showNewPassword,
                      onPressed: () => setState(
                        () => _showNewPassword = !_showNewPassword,
                      ),
                    ),
                    validator: AuthValidators.validateStrongPassword,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    label: 'Xác nhận mật khẩu mới',
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    suffixIcon: _buildPasswordToggle(
                      visible: _showConfirmPassword,
                      onPressed: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      ),
                    ),
                    validator: (value) => AuthValidators.validateConfirmPassword(
                      value,
                      _newPasswordController.text,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isChangingPassword ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFECC741),
                        foregroundColor: const Color(0xFF0F1E36),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isChangingPassword
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0F1E36),
                              ),
                            )
                          : const Text(
                              'Cập nhật mật khẩu',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordToggle({
    required bool visible,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility : Icons.visibility_off,
        color: Colors.white60,
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildInlineError(String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withOpacity(0.28)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFFF8A8A), fontSize: 13),
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

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0ED8AB),
        foregroundColor: const Color(0xFF0F1E36),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0F1E36),
              ),
            )
          : const Text(
              'Lưu Thay Đổi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildLogoutButton(AppState appState) {
    final isBusy = _isLoggingOut || appState.isLoggingOut;

    return OutlinedButton(
      onPressed: isBusy ? null : _logout,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.redAccent,
        side: const BorderSide(color: Colors.redAccent),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isBusy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.redAccent,
              ),
            )
          : const Text(
              'Đăng Xuất',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildSectionHeader(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFECC741), size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    bool obscureText = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          obscureText: obscureText,
          onTap: onTap,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                );
              }).toList(),
              dropdownColor: const Color(0xFF0F1E36),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivePlanBanner(String plan) {
    Color badgeColor;
    String planName;
    String desc;

    if (plan == 'pro') {
      badgeColor = const Color(0xFFECC741);
      planName = 'PRO ACCOUNT';
      desc = 'Mở khóa không giới hạn chatbot AI & phân tích hồ sơ chuyên sâu.';
    } else if (plan == 'edu') {
      badgeColor = const Color(0xFF7F8CFF);
      planName = 'EDU PARTNER';
      desc = 'Hành trình định hướng liên kết từ nhà trường và giáo viên.';
    } else {
      badgeColor = const Color(0xFF0ED8AB);
      planName = 'FREE TIER';
      desc = 'Bạn đang sử dụng gói trải nghiệm miễn phí với lượt hỏi giới hạn.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: plan == 'pro'
              ? [const Color(0xFF1E3552), const Color(0xFF284872)]
              : plan == 'edu'
                  ? [const Color(0xFF192A4D), const Color(0xFF273F74)]
                  : [const Color(0xFF132D30), const Color(0xFF1B494D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  planName,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.stars, color: Color(0xFFECC741), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Lịch sử thanh toán', Icons.receipt_long_outlined),
        const SizedBox(height: 12),
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoadingTransactions)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(
                      color: Color(0xFFECC741),
                    ),
                  ),
                )
              else if (_transactionsError != null)
                Column(
                  children: [
                    Text(
                      _transactionsError!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _fetchTransactions,
                      icon: const Icon(Icons.refresh, color: Color(0xFFECC741), size: 16),
                      label: const Text(
                        'Thử lại',
                        style: TextStyle(color: Color(0xFFECC741), fontSize: 13),
                      ),
                    ),
                  ],
                )
              else if (_transactions == null || _transactions!.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Không có lịch sử giao dịch nào.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _isTransactionsExpanded
                      ? _transactions!.length
                      : (_transactions!.length > 3 ? 3 : _transactions!.length),
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.white.withOpacity(0.08),
                    height: 24,
                  ),
                  itemBuilder: (context, index) {
                    final tx = _transactions![index];
                    final isPaid = tx.status.toLowerCase() == 'paid' ||
                        tx.status.toLowerCase() == 'completed' ||
                        tx.status.toLowerCase() == 'success';
                    final isPending = tx.status.toLowerCase() == 'pending';
                    final amountFormatted = NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: 'đ',
                      decimalDigits: 0,
                    ).format(tx.amount);

                    final isEduPlan = tx.planName.toUpperCase().contains('EDU');
                    final displayCode = isEduPlan
                        ? (tx.transactionCode.toUpperCase().startsWith('EDU-')
                            ? tx.transactionCode.substring(4)
                            : tx.transactionCode)
                        : tx.transactionCode;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.planName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEduPlan ? 'Mã kích hoạt: $displayCode' : 'Mã GD: $displayCode',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isEduPlan ? 'Trường tài trợ' : amountFormatted,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? const Color(0xFF0ED8AB).withOpacity(0.12)
                                    : isPending
                                        ? const Color(0xFFECC741).withOpacity(0.12)
                                        : Colors.redAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isPaid
                                      ? const Color(0xFF0ED8AB).withOpacity(0.3)
                                      : isPending
                                          ? const Color(0xFFECC741).withOpacity(0.3)
                                          : Colors.redAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                isPaid
                                    ? 'Thành công'
                                    : isPending
                                        ? 'Chờ xử lý'
                                        : 'Thất bại',
                                style: TextStyle(
                                  color: isPaid
                                      ? const Color(0xFF0ED8AB)
                                      : isPending
                                          ? const Color(0xFFECC741)
                                          : Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                if (_transactions!.length > 3) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isTransactionsExpanded = !_isTransactionsExpanded;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFECC741),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        _isTransactionsExpanded
                            ? 'Thu gọn'
                            : 'Xem tất cả (${_transactions!.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
