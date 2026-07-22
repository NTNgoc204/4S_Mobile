import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../services/payment_service.dart';
import '../utils/auth_validators.dart';
import '../utils/phone_validator.dart';

class SchoolRegisterDialog extends StatefulWidget {
  final PricingPlan plan;

  const SchoolRegisterDialog({super.key, required this.plan});

  static Future<bool?> show(BuildContext context, PricingPlan plan) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => SchoolRegisterDialog(plan: plan),
    );
  }

  @override
  State<SchoolRegisterDialog> createState() => _SchoolRegisterDialogState();
}

class _SchoolRegisterDialogState extends State<SchoolRegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _representativeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentCountController = TextEditingController(text: '500');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _representativeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentCountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await PaymentService.instance.registerSchool(
        schoolName: _schoolNameController.text.trim(),
        contactName: _representativeController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        phoneNumber: _phoneController.text.trim(),
        studentCount: int.tryParse(_studentCountController.text) ?? 500,
        notes: 'Gói đăng ký đề xuất: ${widget.plan.name}',
        planId: widget.plan.id,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã có lỗi xảy ra: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xEE1A2F4C),
                  Color(0xEE0B1528),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Đăng Ký Tư Vấn Học Đường',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Sora',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    const SizedBox(height: 8),

                    _buildTextField(
                      label: 'Tên trường học',
                      controller: _schoolNameController,
                      placeholder: 'Ví dụ: Trường THPT Nguyễn Thượng Hiền',
                      validator: (v) => AuthValidators.validateRequired(
                        v,
                        'Tên trường không được để trống',
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: 'Người đại diện',
                      controller: _representativeController,
                      placeholder: 'Ví dụ: Thầy Nguyễn Văn An',
                      validator: (v) => AuthValidators.validateRequired(
                        v,
                        'Tên người đại diện không được để trống',
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: 'Số điện thoại',
                      controller: _phoneController,
                      placeholder: 'Ví dụ: 0912345678',
                      keyboardType: TextInputType.phone,
                      validator: PhoneValidator.validateVietnamPhone,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: 'Email nhận báo giá',
                      controller: _emailController,
                      placeholder: 'school.email@edu.vn',
                      keyboardType: TextInputType.emailAddress,
                      validator: AuthValidators.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: 'Số lượng học sinh',
                      controller: _studentCountController,
                      placeholder: '500',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val <= 0) {
                          return 'Số lượng học sinh phải là số nguyên dương';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          child: const Text('Hủy bỏ'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFECC741),
                            foregroundColor: const Color(0xFF0F1E36),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Color(0xFF0F1E36)),
                                  ),
                                )
                              : const Text(
                                  'Đăng ký liên hệ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFECC741)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
