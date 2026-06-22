import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/button.dart';
import '../../components/otp_box_field.dart';
import '../../constants/app_theme.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';
import '../../services/api_service.dart';
import '../../services/google_auth_service.dart';

/// Soft neutral page background used behind the login card (reference design).
const Color _kLoginPageBg = Color(0xFFEDEFF1);
const Color _kLoginShadow = Color(0xFF0F172A);

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
      backgroundColor: _kLoginPageBg,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SpacingScale.lg,
                    vertical: SpacingScale.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 460),
                    child: Container(
                      padding: EdgeInsets.all(SpacingScale.lg + 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: _kLoginShadow.withValues(alpha: 0.08),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPortalSelector(isMalayalam),
                          SizedBox(height: SpacingScale.lg),
                          _buildHeader(isMalayalam),
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
                              ),
                            ),
                            SizedBox(height: SpacingScale.lg),
                          ],
                          AlifButton(
                            label: _primaryLabel(isMalayalam),
                            onPressed: _isLoading ? null : _handlePrimaryAction,
                            isLoading: _isLoading,
                            variant: ButtonVariant.primary,
                            size: ButtonSize.large,
                            width: double.infinity,
                            borderRadius: BorderRadius.circular(30),
                            isMalayalam: isMalayalam,
                          ),
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
                          SizedBox(height: SpacingScale.md),
                          _buildMethodSwitch(isMalayalam),
                          SizedBox(height: SpacingScale.lg),
                          Text(
                            isMalayalam
                                ? '© 2026 അലിഫ് ഓൺലൈൻ മോറൽ സ്കൂൾ'
                                : '© 2026 Alif Online Moral School',
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorPalette.neutral600,
                            ),
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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(16),
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
          color: selected ? ColorPalette.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : ColorPalette.neutral600,
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
                  color: selected ? Colors.white : ColorPalette.neutral600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMalayalam) {
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
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: ColorPalette.primaryDark,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: ColorPalette.primaryDark.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(_portalIcon, size: 30, color: Colors.white),
        ),
        SizedBox(height: SpacingScale.md),
        Text(
          _portalTitle(isMalayalam),
          style: const TextStyle(
            fontSize: 26,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: SpacingScale.xs),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
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
            _loginField(
              icon: Icons.phone_iphone_rounded,
              hint: isMalayalam ? 'ഫോൺ നമ്പർ' : 'Phone number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              validator: _validatePhone,
              onChanged: (value) => setState(() => _phone = value),
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
            _loginField(
              icon: Icons.alternate_email_rounded,
              hint: isMalayalam ? 'ഇമെയിൽ' : 'Email address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            SizedBox(height: SpacingScale.md),
            _loginField(
              icon: Icons.lock_outline_rounded,
              hint: isMalayalam ? 'പാസ്‌വേഡ്' : 'Password',
              controller: _passwordController,
              isPassword: true,
              validator: _validatePassword,
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
    return SizedBox(width: double.infinity, child: child);
  }

  /// Pill-shaped login input matching the reference design: a white field with
  /// a soft shadow, a leading icon and (for passwords) a visibility toggle.
  Widget _loginField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter> formatters = const [],
    bool isPassword = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    String? helperText,
  }) {
    return _LoginField(
      icon: icon,
      hint: hint,
      controller: controller,
      keyboardType: keyboardType,
      formatters: formatters,
      isPassword: isPassword,
      validator: validator,
      onChanged: onChanged,
      helperText: helperText,
      enabled: !_isLoading,
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

/// Private pill-style text field used only by the login screen. Mirrors the
/// reference design: white rounded field with a soft shadow, a leading icon and
/// an optional password visibility toggle. Validation/formatting behaviour is
/// preserved by forwarding the controller, validator and input formatters.
class _LoginField extends StatefulWidget {
  const _LoginField({
    required this.icon,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.formatters = const [],
    this.isPassword = false,
    this.validator,
    this.onChanged,
    this.helperText,
    this.enabled = true,
  });

  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter> formatters;
  final bool isPassword;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final String? helperText;
  final bool enabled;

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEFF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.formatters,
        obscureText: widget.isPassword && _obscure,
        validator: widget.validator,
        onChanged: widget.onChanged,
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
          helperText: widget.helperText,
          helperStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          prefixIcon: Icon(
            widget.icon,
            color: const Color(0xFF6B7280),
            size: 22,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: const Color(0xFF9CA3AF),
                    size: 22,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 18,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }
}
