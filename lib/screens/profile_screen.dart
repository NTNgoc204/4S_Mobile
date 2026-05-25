import 'package:flutter/material.dart';
import '../main.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  late TextEditingController _gpaController;
  late TextEditingController _mathController;
  late TextEditingController _englishController;
  late TextEditingController _scienceController;

  late String _location;
  late double _maxTuition;
  late String _studyMode;

  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final UserProfile profile = AppState.of(context, listen: false).currentUser!;

      _fullNameController = TextEditingController(text: profile.fullName);
      _dobController = TextEditingController(text: profile.dateOfBirth);
      _addressController = TextEditingController(text: profile.address);
      _phoneController = TextEditingController(text: profile.phoneNumber);

      _gpaController = TextEditingController(text: profile.gpa.toString());
      _mathController = TextEditingController(text: profile.mathScore.toString());
      _englishController = TextEditingController(text: profile.englishScore.toString());
      _scienceController = TextEditingController(text: profile.scienceScore.toString());

      _location = profile.preferredLocation;
      _maxTuition = profile.maxTuition;
      _studyMode = profile.studyMode;
      _isInitialized = true;
    }
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
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final appState = AppState.of(context, listen: false);
    final UserProfile updatedProfile = appState.currentUser!.copyWith(
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

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lưu thông tin hồ sơ thành công!'),
        backgroundColor: Color(0xFF0ED8AB),
      ),
    );
  }

  void _upgradePlan(String planId) {
    AppState.of(context, listen: false).upgradeSubscription(planId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nâng cấp thành công gói: ${planId.toUpperCase()}'),
        backgroundColor: planId == 'pro' ? const Color(0xFFECC741) : const Color(0xFF7F8CFF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final currentPlan = appState.currentUser?.currentPlan ?? 'free';

    return Scaffold(
      backgroundColor: const Color(0xFF081326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E36),
        title: const Text('Hồ sơ & Tài khoản', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
            colors: [
              Color(0xFF0F1E36),
              Color(0xFF081326),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SECTION 1: Plan Upgrade Banner
                _buildSectionHeader('Gói đăng ký hiện tại', Icons.card_membership),
                const SizedBox(height: 12),
                _buildActivePlanBanner(currentPlan),
                const SizedBox(height: 16),
                _buildUpgradePlansSlider(currentPlan),
                const SizedBox(height: 28),

                // SECTION 2: Personal Information
                _buildSectionHeader('Thông tin cá nhân', Icons.person_outline),
                const SizedBox(height: 12),
                _buildGlassCard(
                  child: Column(
                    children: [
                      _buildTextField(label: 'Họ và tên *', controller: _fullNameController, validator: (v) => v!.trim().isEmpty ? 'Nhập họ tên' : null),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Ngày sinh *',
                        controller: _dobController,
                        readOnly: true,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2008),
                            firstDate: DateTime(1990),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(label: 'Địa chỉ', controller: _addressController),
                      const SizedBox(height: 16),
                      _buildTextField(label: 'Số điện thoại', controller: _phoneController, keyboardType: TextInputType.phone),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // SECTION 3: Academic Profile
                _buildSectionHeader('Thông tin học tập', Icons.school_outlined),
                const SizedBox(height: 12),
                _buildGlassCard(
                  child: Column(
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
                  ),
                ),
                const SizedBox(height: 28),

                // SECTION 4: Preferences
                _buildSectionHeader('Tùy chọn học tập', Icons.settings_suggest_outlined),
                const SizedBox(height: 12),
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDropdownField(
                        label: 'Khu vực ưu tiên',
                        value: _location,
                        items: ['TP. Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng', 'Cần Thơ'],
                        onChanged: (val) => setState(() => _location = val!),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        label: 'Hình thức học giảng dạy',
                        value: _studyMode,
                        items: ['Tiếng Việt', 'Tiếng Anh', 'Song ngữ'],
                        onChanged: (val) => setState(() => _studyMode = val!),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Học phí tối đa tham khảo: ${_maxTuition.toInt()}M VNĐ/năm',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: _maxTuition,
                        min: 10,
                        max: 200,
                        divisions: 19,
                        activeColor: const Color(0xFFECC741),
                        inactiveColor: Colors.white10,
                        label: '${_maxTuition.toInt()} triệu/năm',
                        onChanged: (val) => setState(() => _maxTuition = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // SAVE BUTTON
                ElevatedButton(
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F1E36)),
                        )
                      : const Text('Lưu Thay Đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),

                // LOGOUT BUTTON
                OutlinedButton(
                  onPressed: () {
                    appState.logout();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Đăng Xuất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
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
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
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
              value: value,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 14)),
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
                  style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              const Spacer(),
              const Icon(Icons.stars, color: Color(0xFFECC741), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildUpgradePlansSlider(String activePlan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Thay đổi gói của bạn',
          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPlanUpgradeCard(
                planId: 'free',
                title: 'Free Plan',
                price: '\$0',
                period: '/trọn đời',
                features: ['Tư vấn AI cơ bản', 'Gợi ý ngành học', 'Giới hạn số lượt hỏi'],
                activePlan: activePlan,
                accentColor: const Color(0xFF0ED8AB),
              ),
              const SizedBox(width: 12),
              _buildPlanUpgradeCard(
                planId: 'pro',
                title: 'Pro Plan',
                price: '\$27',
                period: '/tháng',
                features: ['Hỏi AI không giới hạn', 'Gợi ý cá nhân hóa', 'Độ ưu tiên tốc độ cao'],
                activePlan: activePlan,
                accentColor: const Color(0xFFECC741),
              ),
              const SizedBox(width: 12),
              _buildPlanUpgradeCard(
                planId: 'edu',
                title: 'Edu Plan',
                price: 'Liên hệ',
                period: '',
                features: ['Mọi tính năng của Pro', 'Dashboard cho giáo viên', 'Định hướng lớp học'],
                activePlan: activePlan,
                accentColor: const Color(0xFF7F8CFF),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanUpgradeCard({
    required String planId,
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required String activePlan,
    required Color accentColor,
  }) {
    final bool isCurrent = planId == activePlan;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCurrent ? accentColor : Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(color: isCurrent ? accentColor : Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                period,
                style: const TextStyle(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...features.map((f) => Row(
                children: [
                  Icon(Icons.check, color: accentColor, size: 10),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(color: Colors.white70, fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )),
          const Spacer(),
          ElevatedButton(
            onPressed: isCurrent ? null : () => _upgradePlan(planId),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrent ? Colors.white10 : accentColor,
              foregroundColor: const Color(0xFF0F1E36),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isCurrent ? 'Đang dùng' : 'Chọn gói',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.white38 : const Color(0xFF0F1E36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
