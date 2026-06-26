import 'package:flutter/material.dart';
import '../../components/input.dart';
import '../../components/otp_box_field.dart';
import '../../constants/app_theme.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';
import '../../services/api_service.dart';
import '../../services/google_auth_service.dart';

enum LoginStep { phone, otp }

/// Which portal the user is signing in to. Shown as a selector at the top so it
/// is always clear whether you are entering the student / parent side or the
/// teacher side. Parent access lives inside the student portal as a switch.
enum LoginPortal { studentParent, teacher }

/// Mobile login screen.
///
/// Primary method: **phone number + OTP**. The same flow is used by students,
/// parents and teachers — the backend resolves the actual role from the
/// verified account, so there is no role/portal selection before sign-in.
/// Accounts are switched from inside the app afterwards (like a Google account
/// switcher). Email + password is offered only as an optional secondary method.
class MobileLoginScreen extends StatefulWidget {
  final void Function(String role, {bool hasParentAccess}) onLoginSuccess;

  const MobileLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  /// Country code automatically prepended to the 10-digit local number.
  static const String _countryCode = '+91';

  LoginStep _step = LoginStep.phone;

  /// The portal selected at the top of the screen. Decides which board opens
  /// after a successful sign-in.
  LoginPortal _portal = LoginPortal.studentParent;

  /// When true the optional email + password form is shown instead of the
  /// primary phone + OTP flow.
  bool _useEmail = false;

  /// When true the screen is in "create account" mode instead of sign-in.
  bool _isRegister = false;

  String _phone = '';
  String _otp = '';
  String? _error;
  bool _isLoading = false;

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;

    return Scaffold(
      backgroundColor: ColorPalette.backgroundLight,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorPalette.white, ColorPalette.neutral100],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: SpacingScale.lg,
                vertical: SpacingScale.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_buildCard(isMalayalam)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(bool isMalayalam) {
    return Container(
      padding: EdgeInsets.all(SpacingScale.lg),
      decoration: BoxDecoration(
        color: ColorPalette.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: ColorPalette.neutral200),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.primaryDark.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isMalayalam ? 'സൈൻ ഇൻ' : 'Sign In',
            style: const TextStyle(
              fontSize: 48 / 1.6,
              fontWeight: FontWeight.w800,
              color: ColorPalette.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: SpacingScale.xs),
          Container(
            width: 92,
            height: 6,
            decoration: BoxDecoration(
              color: ColorPalette.primaryLight,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: SpacingScale.lg),
          // 1. Logo placed at the top (below Sign In title)
          _buildLogoHeader(isMalayalam),
          SizedBox(height: SpacingScale.lg),
          // 2. Segmented Portal Toggle placed right above the email/phone tabs
          _buildPortalToggle(isMalayalam),
          SizedBox(height: SpacingScale.lg),
          if (_step == LoginStep.phone) _buildAuthMethodTabs(isMalayalam),
          if (_step == LoginStep.phone) SizedBox(height: SpacingScale.lg),
          if (_useEmail)
            _buildEmailForm(isMalayalam)
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
                color: ColorPalette.ratingNeedsImprovement.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorPalette.ratingNeedsImprovement.withValues(
                    alpha: 0.35,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: ColorPalette.ratingNeedsImprovement,
                    size: 20,
                  ),
                  SizedBox(width: SpacingScale.sm),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: ColorPalette.ratingNeedsImprovement,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: SpacingScale.lg),
          ],
          _buildPrimaryButton(isMalayalam),
          if (!_useEmail && _step == LoginStep.otp) ...[
            SizedBox(height: SpacingScale.sm),
            TextButton(
              onPressed: _isLoading ? null : _backToPhone,
              child: Text(
                isMalayalam
                    ? 'വേറെ നമ്പർ ഉപയോഗിക്കുക'
                    : 'Use a different number',
              ),
            ),
          ] else ...[
            SizedBox(height: SpacingScale.sm),
            _buildAuthModeSwitch(isMalayalam),
          ],
          SizedBox(height: SpacingScale.md),
          Divider(color: ColorPalette.neutral200, height: 1),
          SizedBox(height: SpacingScale.md),
          Text(
            isMalayalam
                ? '© 2026 അലിഫ് ഓൺലൈൻ മോറൽ സ്കൂൾ'
                : '© 2026 Alif Online Moral School',
            style: TextStyle(fontSize: 12, color: ColorPalette.neutral500),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(bool isMalayalam) {
    final enabled = !_isLoading;
    return Opacity(
      opacity: enabled ? 1 : 0.75,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ColorPalette.primaryDark, ColorPalette.primaryLight],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ColorPalette.primaryDark.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? _handlePrimaryAction : null,
            child: SizedBox(
              height: 56,
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        _primaryLabel(isMalayalam),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== Portal selector & Logo Header =====

  String get _selectedRole =>
      _portal == LoginPortal.teacher ? 'teacher' : 'student';

  IconData get _portalIcon => _portal == LoginPortal.teacher
      ? Icons.co_present_rounded
      : Icons.school_rounded;

  Widget _buildLogoHeader(bool isMalayalam) {
    final subtitle = _isRegister
        ? (isMalayalam
              ? 'ഒരു പുതിയ അക്കൗണ്ട് ഉണ്ടാക്കാം'
              : 'Create your account')
        : (isMalayalam
              ? 'നിങ്ങളുടെ അക്കൗണ്ടിൽ സൈൻ ഇൻ ചെയ്യുക'
              : 'Sign in to your account');

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColorPalette.primaryDark, ColorPalette.primaryLight],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: ColorPalette.primaryDark.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(_portalIcon, size: 28, color: Colors.white),
        ),
        SizedBox(height: SpacingScale.md),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: ColorPalette.textTertiary,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildPortalToggle(bool isMalayalam) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorPalette.neutral100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorPalette.neutral200),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _portal = LoginPortal.studentParent;
                _clearError();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _portal == LoginPortal.studentParent
                      ? ColorPalette.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _portal == LoginPortal.studentParent
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    isMalayalam
                        ? 'വിദ്യാർത്ഥി / രക്ഷിതാവ് പോർട്ടൽ'
                        : 'Student / Parent Portal',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: _portal == LoginPortal.studentParent
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _portal == LoginPortal.studentParent
                          ? ColorPalette.primaryDark
                          : ColorPalette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _portal = LoginPortal.teacher;
                _clearError();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _portal == LoginPortal.teacher
                      ? ColorPalette.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _portal == LoginPortal.teacher
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    isMalayalam ? 'അധ്യാപക പോർട്ടൽ' : 'Teacher Portal',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: _portal == LoginPortal.teacher
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _portal == LoginPortal.teacher
                          ? ColorPalette.primaryDark
                          : ColorPalette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthMethodTabs(bool isMalayalam) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorPalette.neutral100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorPalette.neutral200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _methodTab(
              label: isMalayalam ? 'ഇമെയിൽ' : 'Email',
              selected: _useEmail,
              onTap: _switchToEmail,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _methodTab(
              label: isMalayalam ? 'മൊബൈൽ നമ്പർ' : 'Mobile Number',
              selected: !_useEmail,
              onTap: _switchToPhone,
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? ColorPalette.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: ColorPalette.neutral900.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? ColorPalette.primaryDark
                      : ColorPalette.neutral500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(bool isMalayalam) {
    return AlifInput(
      label: isMalayalam ? 'പൂർണ്ണമായ പേര്' : 'Full Name',
      placeholder: isMalayalam ? 'നിങ്ങളുടെ പേര്' : 'Your name',
      type: InputType.text,
      controller: _nameController,
      required: true,
      validator: _validateName,
      isMalayalam: isMalayalam,
      autofillHints: const [AutofillHints.name],
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => _clearError(),
    );
  }

  Widget _buildPhoneForm(bool isMalayalam) {
    return Form(
      key: _formKey,
      child: _buildFormStepShell(
        accent: ColorPalette.primaryLight,
        child: Column(
          children: [
            if (_isRegister) ...[
              _buildNameField(isMalayalam),
              SizedBox(height: SpacingScale.md),
            ],
            AlifInput(
              label: isMalayalam ? 'ഫോൺ നമ്പർ' : 'Phone Number',
              placeholder: '98XXXXXXXX',
              type: InputType.phone,
              controller: _phoneController,
              maxLength: 10,
              leading: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() => _phone = value);
              },
              required: true,
              validator: _validatePhone,
              isMalayalam: isMalayalam,
              helperText: isMalayalam
                  ? '10 അക്ക മൊബൈൽ നമ്പർ'
                  : '10-digit mobile number',
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
              isMalayalam
                  ? '$_phone എന്ന നമ്പറിലേക്ക് അയച്ച OTP നൽകുക'
                  : 'Enter OTP sent to $_phone',
              style: TextStyle(fontSize: 14, color: ColorPalette.neutral600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SpacingScale.md),
            OtpBoxField(
              length: 4,
              enabled: !_isLoading,
              onChanged: (value) => _otp = value,
              onCompleted: (value) {
                _otp = value;
                _handlePrimaryAction();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailForm(bool isMalayalam) {
    return Form(
      key: _formKey,
      child: _buildFormStepShell(
        accent: ColorPalette.primaryLight,
        child: Column(
          children: [
            if (_isRegister) ...[
              _buildNameField(isMalayalam),
              SizedBox(height: SpacingScale.md),
            ],
            AlifInput(
              label: isMalayalam ? 'ഇമെയിൽ' : 'Email',
              placeholder: 'you@example.com',
              type: InputType.email,
              controller: _emailController,
              required: true,
              validator: _validateEmail,
              isMalayalam: isMalayalam,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) => _clearError(),
            ),
            SizedBox(height: SpacingScale.md),
            AlifInput(
              label: isMalayalam ? 'പാസ്‌വേഡ്' : 'Password',
              placeholder: isMalayalam
                  ? 'നിങ്ങളുടെ പാസ്‌വേഡ്'
                  : 'Your password',
              type: InputType.password,
              controller: _passwordController,
              required: true,
              validator: _validatePassword,
              isMalayalam: isMalayalam,
              autofillHints: const [AutofillHints.password],
              onChanged: (_) => _clearError(),
            ),
            SizedBox(height: SpacingScale.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _onForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isMalayalam ? 'പാസ്‌വേഡ് മറന്നോ?' : 'Forgot Password?',
                  style: const TextStyle(
                    color: ColorPalette.primaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle between sign-in and create-account modes.
  Widget _buildAuthModeSwitch(bool isMalayalam) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isRegister
              ? (isMalayalam ? 'അക്കൗണ്ട് ഉണ്ടോ?' : 'Already have an account?')
              : (isMalayalam ? 'പുതിയ ഉപയോക്താവാണോ?' : 'New here?'),
          style: TextStyle(fontSize: 13, color: ColorPalette.neutral500),
        ),
        TextButton(
          onPressed: _isLoading ? null : _toggleRegister,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _isRegister
                ? (isMalayalam ? 'സൈൻ ഇൻ ചെയ്യുക' : 'Sign in')
                : (isMalayalam ? 'അക്കൗണ്ട് ഉണ്ടാക്കുക' : 'Create account'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  void _toggleRegister() {
    setState(() {
      _isRegister = !_isRegister;
      _step = LoginStep.phone;
      _otp = '';
      _error = null;
    });
  }

  Widget _buildFormStepShell({
    required Color accent,
    IconData? icon,
    required Widget child,
  }) {
    return Column(
      children: [
        if (icon != null) ...[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          SizedBox(height: SpacingScale.md),
        ],
        child,
      ],
    );
  }

  String _primaryLabel(bool isMalayalam) {
    if (!_useEmail && _step == LoginStep.otp) {
      return isMalayalam ? 'പരിശോധിച്ച് സൈൻ ഇൻ' : 'Verify & Sign In';
    }
    if (_isRegister) {
      return isMalayalam ? 'അക്കൗണ്ട് ഉണ്ടാക്കുക' : 'Create Account';
    }
    if (_useEmail) {
      return isMalayalam ? 'സൈൻ ഇൻ' : 'Sign In';
    }
    return isMalayalam ? 'OTP അയക്കുക' : 'Send OTP';
  }

  // ===== Validation =====

  String? _validatePhone(String? value) {
    if (_normalizePhone(value) == null) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? _normalizePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return null;
    }
    return '$_countryCode$digits';
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 4) {
      return 'OTP must be 4 digits';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(raw)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (_isRegister && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  // ===== Method switching =====

  void _switchToEmail() {
    setState(() {
      _useEmail = true;
      _step = LoginStep.phone;
      _otp = '';
      _error = null;
    });
  }

  void _switchToPhone() {
    setState(() {
      _useEmail = false;
      _step = LoginStep.phone;
      _error = null;
    });
  }

  void _backToPhone() {
    setState(() {
      _step = LoginStep.phone;
      _otp = '';
      _error = null;
    });
  }

  // ===== Actions =====

  /// Clears a stale error banner as soon as the user edits a field, so a
  /// previous failure message (e.g. a password rule) does not linger after the
  /// input has already been corrected.
  void _clearError() {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  void _onForgotPassword() {
    final message = context.isMalayalam
        ? 'പാസ്‌വേഡ് റീസെറ്റ് ഓപ്‌ഷൻ ഉടൻ ലഭ്യമാകും'
        : 'Password reset option will be available soon';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handlePrimaryAction() {
    setState(() => _error = null);

    // The OTP step always verifies and signs in, whether the user is signing
    // in or has just registered with a phone number.
    if (!_useEmail && _step == LoginStep.otp) {
      final otpError = _validateOtp(_otp);
      if (otpError != null) {
        setState(() => _error = otpError);
        return;
      }
      setState(() => _isLoading = true);
      _handleOtpSubmit();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isRegister) {
      setState(() => _isLoading = true);
      _handleRegister();
      return;
    }

    if (_useEmail) {
      setState(() => _isLoading = true);
      _handleEmailSubmit();
      return;
    }

    // Phone sign-in -> request an OTP.
    setState(() => _isLoading = true);
    _handlePhoneSubmit();
  }

  void _handleRegister() async {
    final role = _selectedRole;
    final fullName = _nameController.text.trim();

    if (_useEmail) {
      final result = await MobileApiService.register(
        method: 'email',
        fullName: fullName,
        role: role,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      if (!result.success) {
        final message = result.message ?? 'Registration failed';
        // If the account already exists, drop the user straight into sign-in
        // mode (keeping their email) instead of leaving them stuck on the
        // create-account screen.
        final alreadyExists = message.toLowerCase().contains(
          'already registered',
        );
        setState(() {
          _isLoading = false;
          if (alreadyExists) {
            _isRegister = false;
            _useEmail = true;
            _passwordController.clear();
          }
          _error = message;
        });
        return;
      }
      // Account created -> sign in immediately with the same credentials.
      _handleEmailSubmit();
      return;
    }

    // Phone registration.
    final normalizedPhone = _normalizePhone(_phone);
    if (normalizedPhone == null) {
      setState(() {
        _isLoading = false;
        _error = 'Phone number is required';
      });
      return;
    }

    final result = await MobileApiService.register(
      method: 'phone',
      fullName: fullName,
      role: role,
      phone: normalizedPhone,
    );
    if (!mounted) {
      return;
    }
    if (!result.success) {
      final message = result.message ?? 'Registration failed';
      final alreadyExists = message.toLowerCase().contains(
        'already registered',
      );
      if (alreadyExists) {
        // Account exists -> just send an OTP and continue to verification.
        final otpResult = await MobileApiService.requestOtp(normalizedPhone);
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _isRegister = false;
          if (otpResult.success) {
            _step = LoginStep.otp;
            _error = null;
          } else {
            _error = otpResult.message ?? message;
          }
        });
        return;
      }
      setState(() {
        _isLoading = false;
        _error = message;
      });
      return;
    }
    final otpResult = await MobileApiService.requestOtp(normalizedPhone);
    if (!mounted) {
      return;
    }
    if (!otpResult.success) {
      setState(() {
        _isLoading = false;
        _error = otpResult.message ?? 'Failed to request OTP';
      });
      return;
    }
    setState(() {
      _isLoading = false;
      _isRegister = false; // OTP step uses the shared sign-in verification.
      _step = LoginStep.otp;
    });
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

    // The portal chosen at the top decides which board opens; the backend OTP
    // verification still authenticates the phone number. Parent access is
    // always offered inside the student portal as an in-app switch.
    final user = result.data?['user'];
    final backendRole = user is Map ? user['role']?.toString() : null;
    final hasParentAccess =
        _portal == LoginPortal.studentParent ||
        (user is Map && user['has_parent_access'] == true);

    // Remember the signed-in name so the home avatar shows the correct initial
    // (OTP login has no Supabase session to read the name from).
    if (user is Map) {
      MobileGoogleAuthService.rememberSessionUser(
        Map<String, dynamic>.from(user),
      );
    }

    // A guardian account (linked to children, with no student board of its own)
    // opens the parent child-picker directly instead of an empty student board.
    final role =
        (_portal == LoginPortal.studentParent && backendRole == 'parent')
        ? 'parent'
        : _selectedRole;

    widget.onLoginSuccess(role, hasParentAccess: hasParentAccess);
  }

  void _handleEmailSubmit() async {
    try {
      final result = await MobileGoogleAuthService.signInWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      widget.onLoginSuccess(
        _selectedRole,
        hasParentAccess:
            _portal == LoginPortal.studentParent || result.hasParentAccess,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }
}
