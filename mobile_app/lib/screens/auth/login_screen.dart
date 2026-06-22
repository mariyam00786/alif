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

  String _phone = '';
  String _otp = '';
  String? _error;
  bool _isLoading = false;

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
            colors: [ColorPalette.white, ColorPalette.primaryMuted],
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
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHero(isMalayalam),
                    SizedBox(height: SpacingScale.xl),
                    _buildCard(isMalayalam),
                  ],
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
          _buildPortalSelector(isMalayalam),
          SizedBox(height: SpacingScale.lg),
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
          if (_step == LoginStep.otp && !_useEmail) ...[
            SizedBox(height: SpacingScale.sm),
            TextButton(
              onPressed: _isLoading ? null : _backToPhone,
              child: Text(
                isMalayalam
                    ? 'വേറെ നമ്പർ ഉപയോഗിക്കുക'
                    : 'Use a different number',
              ),
            ),
          ],
          SizedBox(height: SpacingScale.sm),
          _buildMethodSwitch(isMalayalam),
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
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _primaryLabel(isMalayalam),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
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

  // ===== Portal selector =====

  String get _selectedRole =>
      _portal == LoginPortal.teacher ? 'teacher' : 'student';

  IconData get _portalIcon => _portal == LoginPortal.teacher
      ? Icons.co_present_rounded
      : Icons.school_rounded;

  String _portalTitle(bool isMalayalam) {
    switch (_portal) {
      case LoginPortal.teacher:
        return isMalayalam ? 'അധ്യാപക പോർട്ടൽ' : 'Teacher Portal';
      case LoginPortal.studentParent:
        return isMalayalam
            ? 'വിദ്യാർത്ഥി / രക്ഷിതാവ് പോർട്ടൽ'
            : 'Student / Parent Portal';
    }
  }

  void _selectPortal(LoginPortal portal) {
    if (_portal == portal) return;
    setState(() {
      _portal = portal;
      _error = null;
    });
  }

  Widget _buildPortalSelector(bool isMalayalam) {
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
            child: _portalTab(
              label: isMalayalam
                  ? 'വിദ്യാർത്ഥി / രക്ഷിതാവ്'
                  : 'Student / Parent',
              icon: Icons.school_rounded,
              selected: _portal == LoginPortal.studentParent,
              onTap: () => _selectPortal(LoginPortal.studentParent),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _portalTab(
              label: isMalayalam ? 'അധ്യാപകൻ' : 'Teacher',
              icon: Icons.co_present_rounded,
              selected: _portal == LoginPortal.teacher,
              onTap: () => _selectPortal(LoginPortal.teacher),
            ),
          ),
        ],
      ),
    );
  }

  Widget _portalTab({
    required String label,
    required IconData icon,
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
            Icon(
              icon,
              size: 16,
              color: selected
                  ? ColorPalette.primaryDark
                  : ColorPalette.neutral500,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _buildHero(bool isMalayalam) {
    final subtitle = _useEmail
        ? (isMalayalam
              ? 'ഇമെയിലും പാസ്‌വേഡും ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യുക'
              : 'Sign in with your email and password')
        : (isMalayalam
              ? 'ഫോൺ നമ്പറും OTP-യും ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യുക'
              : 'Sign in with your phone number and OTP');

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColorPalette.primaryDark, ColorPalette.primaryLight],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: ColorPalette.primaryDark.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(_portalIcon, size: 34, color: Colors.white),
        ),
        SizedBox(height: SpacingScale.lg),
        Text(
          _portalTitle(isMalayalam),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: ColorPalette.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: SpacingScale.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: ColorPalette.textTertiary,
          ),
        ),
      ],
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
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SpacingScale.md),
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
        icon: Icons.alternate_email,
        child: Column(
          children: [
            AlifInput(
              label: isMalayalam ? 'ഇമെയിൽ' : 'Email',
              placeholder: 'you@example.com',
              type: InputType.email,
              controller: _emailController,
              required: true,
              validator: _validateEmail,
              isMalayalam: isMalayalam,
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
            ),
          ],
        ),
      ),
    );
  }

  /// The link that toggles between the primary phone flow and the optional
  /// email flow.
  Widget _buildMethodSwitch(bool isMalayalam) {
    if (_useEmail) {
      return TextButton.icon(
        onPressed: _isLoading ? null : _switchToPhone,
        icon: Icon(Icons.phone_iphone, size: 18),
        label: Text(
          isMalayalam
              ? 'ഫോൺ നമ്പർ ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യുക'
              : 'Sign in with phone number',
        ),
      );
    }
    return TextButton.icon(
      onPressed: _isLoading ? null : _switchToEmail,
      icon: Icon(Icons.alternate_email, size: 18),
      label: Text(
        isMalayalam ? 'പകരം ഇമെയിൽ ഉപയോഗിക്കുക' : 'Use email instead',
      ),
    );
  }

  Widget _buildFormStepShell({
    required Color accent,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      children: [
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
        child,
      ],
    );
  }

  String _primaryLabel(bool isMalayalam) {
    if (_useEmail) {
      return isMalayalam ? 'സൈൻ ഇൻ' : 'Sign In';
    }
    if (_step == LoginStep.phone) {
      return isMalayalam ? 'OTP അയക്കുക' : 'Send OTP';
    }
    return isMalayalam ? 'പരിശോധിച്ച് സൈൻ ഇൻ' : 'Verify & Sign In';
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

  void _handlePrimaryAction() {
    setState(() => _error = null);

    if (_useEmail) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      setState(() => _isLoading = true);
      _handleEmailSubmit();
      return;
    }

    if (_step == LoginStep.phone) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      setState(() => _isLoading = true);
      _handlePhoneSubmit();
    } else {
      final otpError = _validateOtp(_otp);
      if (otpError != null) {
        setState(() => _error = otpError);
        return;
      }
      setState(() => _isLoading = true);
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

    // The portal chosen at the top decides which board opens; the backend OTP
    // verification still authenticates the phone number. Parent access is
    // always offered inside the student portal as an in-app switch.
    final user = result.data?['user'];
    final backendRole = user is Map ? user['role']?.toString() : null;
    final hasParentAccess =
        _portal == LoginPortal.studentParent ||
        (user is Map && user['has_parent_access'] == true);

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
