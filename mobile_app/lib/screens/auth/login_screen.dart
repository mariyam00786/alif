import 'package:flutter/material.dart';
import '../../components/button.dart';
import '../../components/input.dart';
import '../../constants/app_theme.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';
import '../../services/api_service.dart';

enum LoginStep { role, phone, otp }

enum UserRole { student, parent }

/// Mobile login screen for students and parents
///
/// Features:
/// - Phone-based OTP login
/// - Student/Parent selector
/// - Role-based navigation
/// - Form validation
/// - Bilingual support
class MobileLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const MobileLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  LoginStep _step = LoginStep.role;
  UserRole _selectedRole = UserRole.student;
  UserRole? _hoveredRole;
  String _phone = '';
  String _otp = '';
  String? _error;
  bool _isLoading = false;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;

    return Scaffold(
      backgroundColor: ColorPalette.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: ColorPalette.primaryMuted.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              right: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: ColorPalette.secondaryMuted.withValues(alpha: 0.32),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SpacingScale.lg,
                    vertical: SpacingScale.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 460),
                    child: Container(
                      padding: EdgeInsets.all(SpacingScale.xl),
                      decoration: BoxDecoration(
                        color: ColorPalette.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: ColorPalette.neutral200),
                        boxShadow: [
                          BoxShadow(
                            color: ColorPalette.primaryDark.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 30,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(isMalayalam),
                          SizedBox(height: SpacingScale.xl),
                          if (_step == LoginStep.role)
                            _buildRoleSelector(isMalayalam)
                          else if (_step == LoginStep.phone)
                            _buildPhoneForm(isMalayalam)
                          else
                            _buildOtpForm(isMalayalam),
                          SizedBox(height: SpacingScale.lg),
                          if (_error != null) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(SpacingScale.md),
                              decoration: BoxDecoration(
                                color: ColorPalette.ratingNeedsImprovement
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ColorPalette.ratingNeedsImprovement
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: ColorPalette.ratingNeedsImprovement,
                                  fontSize: 14,
                                ),
                                textDirection: isMalayalam
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                              ),
                            ),
                            SizedBox(height: SpacingScale.lg),
                          ],
                          if (_step != LoginStep.role)
                            AlifButton(
                              label: isMalayalam ? 'വിതരണം ചെയ്യുക' : 'Submit',
                              onPressed: _isLoading ? null : _handleSubmit,
                              isLoading: _isLoading,
                              variant: ButtonVariant.primary,
                              size: ButtonSize.large,
                              width: double.infinity,
                              borderRadius: BorderRadius.circular(14),
                              isMalayalam: isMalayalam,
                            ),
                          if (_step != LoginStep.role) ...[
                            SizedBox(height: SpacingScale.sm),
                            TextButton(
                              onPressed: _goBackToRoleStep,
                              child: Text(
                                isMalayalam
                                    ? 'ഭൂമികയിലേക്ക് ഗ്സ് ചെയ്യുക'
                                    : 'Back to Role',
                                textDirection: isMalayalam
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                              ),
                            ),
                          ],
                          SizedBox(height: SpacingScale.lg),
                          Text(
                            isMalayalam
                                ? '© 2026 അലിഫ് ഓൻലൈൻ നൈതിക സ്കൂൾ'
                                : '© 2026 Alif Online Moral School',
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorPalette.neutral600,
                            ),
                            textDirection: isMalayalam
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMalayalam) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SpacingScale.md,
            vertical: SpacingScale.xs,
          ),
          decoration: BoxDecoration(
            color: ColorPalette.primaryMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: ColorPalette.primaryLight.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            isMalayalam ? 'വിദ്യാർഥി പ്രവേശനം' : 'Student Access Portal',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorPalette.primaryDark,
            ),
            textDirection: isMalayalam ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
        SizedBox(height: SpacingScale.md),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: ColorPalette.primaryDark,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ColorPalette.primaryDark.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.school, size: 40, color: Colors.white),
        ),
        SizedBox(height: SpacingScale.lg),
        Text(
          isMalayalam ? 'അലിഫ് കണക്കിൽ' : 'Alif Student Portal',
          style: TextStyle(
            fontSize: 34,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: ColorPalette.primaryDark,
          ),
          textDirection: isMalayalam ? TextDirection.rtl : TextDirection.ltr,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: SpacingScale.sm),
        Text(
          isMalayalam
              ? 'വിദ്യാർഥി അല്ലെങ്കിൽ രക്ഷകർതൃ പ്രവേശനം'
              : 'Student or Parent Login',
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: ColorPalette.neutral600,
          ),
          textDirection: isMalayalam ? TextDirection.rtl : TextDirection.ltr,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoleSelector(bool isMalayalam) {
    return Column(
      children: [
        Text(
          isMalayalam ? 'നിങ്ങൾ ആരാണ്?' : 'Who are you?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ColorPalette.textPrimary,
          ),
          textDirection: isMalayalam ? TextDirection.rtl : TextDirection.ltr,
        ),
        SizedBox(height: SpacingScale.md),
        _buildRoleCard(
          role: UserRole.student,
          isMalayalam: isMalayalam,
          accent: ColorPalette.primaryLight,
          icon: Icons.person_outline,
          title: isMalayalam ? 'വിദ്യാർഥി' : 'Student',
          subtitle: isMalayalam
              ? 'നിങ്ങളുടെ നിത്യ പ്രവർത്തനങ്ങൾ ചിതിരിക്കുക'
              : 'Track your daily activities',
          onTap: () => setState(() {
            _selectedRole = UserRole.student;
            _step = LoginStep.phone;
          }),
        ),
        SizedBox(height: SpacingScale.lg),
        _buildRoleCard(
          role: UserRole.parent,
          isMalayalam: isMalayalam,
          accent: ColorPalette.secondary,
          icon: Icons.family_restroom,
          title: isMalayalam ? 'അഭിഭാഷകൻ' : 'Parent',
          subtitle: isMalayalam
              ? 'കുട്ടിയുടെ പുരോഗതി നിരീക്ഷണ ചെയ്യുക'
              : 'Monitor your child\'s progress',
          onTap: () => setState(() {
            _selectedRole = UserRole.parent;
            _step = LoginStep.phone;
          }),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required bool isMalayalam,
    required Color accent,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredRole == role;
    final isSelected = _selectedRole == role;
    final shouldHighlight = isHovered || isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRole = role),
      onExit: (_) => setState(() => _hoveredRole = null),
      child: AnimatedScale(
        scale: shouldHighlight ? 1.01 : 1,
        duration: Duration(milliseconds: 160),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 180),
              width: double.infinity,
              padding: EdgeInsets.all(SpacingScale.md),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: shouldHighlight ? 0.14 : 0.08),
                border: Border.all(
                  color: shouldHighlight
                      ? accent
                      : accent.withValues(alpha: 0.72),
                  width: shouldHighlight ? 2.3 : 2,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: shouldHighlight
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.2),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: ColorPalette.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 30, color: accent),
                  ),
                  SizedBox(width: SpacingScale.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                          textDirection: isMalayalam
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                        ),
                        SizedBox(height: SpacingScale.xs),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: ColorPalette.neutral600,
                            height: 1.35,
                          ),
                          textDirection: isMalayalam
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: SpacingScale.sm),
                  Icon(Icons.arrow_forward_rounded, color: accent, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm(bool isMalayalam) {
    return Form(
      key: _formKey,
      child: _buildFormStepShell(
        accent: ColorPalette.primaryLight,
        icon: Icons.phone_iphone,
        child: Column(
          children: [
            Text(
              isMalayalam ? 'ഫോൺ നമ്പർ നൽകുക' : 'Enter your phone number',
              style: TextStyle(fontSize: 14, color: ColorPalette.neutral600),
              textDirection: isMalayalam
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SpacingScale.md),
            AlifInput(
              label: isMalayalam ? 'ഫോൺ നമ്പർ' : 'Phone Number',
              placeholder: isMalayalam ? '+966...' : '+966...',
              type: InputType.phone,
              controller: _phoneController,
              onChanged: (value) {
                setState(() => _phone = value);
              },
              required: true,
              validator: _validatePhone,
              isMalayalam: isMalayalam,
              helperText: isMalayalam
                  ? 'ദേശ കോഡ് സഹിതം'
                  : 'Include country code',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpForm(bool isMalayalam) {
    return Form(
      key: _formKey,
      child: _buildFormStepShell(
        accent: ColorPalette.secondary,
        icon: Icons.verified_user_outlined,
        child: Column(
          children: [
            Text(
              isMalayalam ? 'OTP നമ്പർ നൽകുക' : 'Enter OTP sent to $_phone',
              style: TextStyle(fontSize: 14, color: ColorPalette.neutral600),
              textDirection: isMalayalam
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SpacingScale.md),
            AlifInput(
              label: isMalayalam ? 'OTP' : 'OTP',
              placeholder: isMalayalam ? '000000' : '000000',
              type: InputType.number,
              controller: _otpController,
              onChanged: (value) {
                setState(() => _otp = value);
              },
              required: true,
              validator: _validateOtp,
              isMalayalam: isMalayalam,
              helperText: isMalayalam
                  ? '6-അക്ഷര കോഡ്'
                  : '6-digit code from SMS',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormStepShell({
    required Color accent,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SpacingScale.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ColorPalette.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          SizedBox(height: SpacingScale.md),
          child,
        ],
      ),
    );
  }

  String? _validatePhone(String? value) {
    final normalizedPhone = _normalizePhone(value);

    if (normalizedPhone == null) {
      return 'Phone number is required';
    }
    if (!normalizedPhone.startsWith('+') || normalizedPhone.length < 12) {
      return 'Invalid phone number format';
    }
    return null;
  }

  String? _normalizePhone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }

    if (raw.startsWith('+')) {
      return raw;
    }

    return '+$raw';
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    return null;
  }

  void _handleSubmit() {
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    if (_step == LoginStep.phone) {
      _handlePhoneSubmit();
    } else {
      _handleOtpSubmit();
    }
  }

  void _handlePhoneSubmit() async {
    final normalizedPhone = _normalizePhone(_phone);
    if (normalizedPhone == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = 'Phone number is required';
      });
      return;
    }

    final result = await MobileApiService.requestOtp(normalizedPhone);
    if (!mounted) {
      return;
    }

    if (!result.success) {
      setState(() {
        _isLoading = false;
        _error = result.message ?? 'Failed to request OTP';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _step = LoginStep.otp;
    });
  }

  void _handleOtpSubmit() async {
    final normalizedPhone = _normalizePhone(_phone);
    if (normalizedPhone == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = 'Phone number is required';
      });
      return;
    }

    final result = await MobileApiService.verifyOtp(
      normalizedPhone,
      _otp.trim(),
    );
    if (!mounted) {
      return;
    }

    if (!result.success) {
      setState(() {
        _isLoading = false;
        _error = result.message ?? 'Invalid OTP';
      });
      return;
    }

    setState(() => _isLoading = false);

    widget.onLoginSuccess();
  }

  void _goBackToRoleStep() {
    setState(() {
      _step = LoginStep.role;
      _phoneController.clear();
      _otpController.clear();
      _error = null;
    });
  }
}
