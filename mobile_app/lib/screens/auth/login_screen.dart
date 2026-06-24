import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/input.dart';
import '../../components/otp_box_field.dart';
import '../../constants/app_theme.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';
import '../../services/api_service.dart';
import '../../services/google_auth_service.dart';

// ── Minimal sign-in palette (warm cream surface + deep brand green) ─────────
const Color _kCanvas = Color(0xFFEDE8DE);
const Color _kPanel = Color(0xFFF6F3EC);
const Color _kPanelBorder = Color(0xFFE4DED2);
const Color _kBrandGreen = Color(0xFF1B6A5B);
const Color _kHelperText = Color(0xFF9B968B);
const Color _kDisabledBtn = Color(0xFFE7E2D8);
const Color _kDivider = Color(0xFFE5E0D5);

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

  /// Cached locale captured during [build] so event handlers can build
  /// localized messages without doing a listening provider read (which is
  /// illegal outside the widget tree and throws a provider assertion).
  bool _isMalayalam = false;

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
    _isMalayalam = isMalayalam;

    return Scaffold(
      backgroundColor: _kCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: SpacingScale.lg,
              vertical: SpacingScale.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: _buildCard(isMalayalam),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(bool isMalayalam) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingScale.lg,
        vertical: SpacingScale.xl,
      ),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kPanelBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHero(isMalayalam),
          SizedBox(height: SpacingScale.xl),
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

  bool get _canSubmit {
    if (_isLoading) return false;
    if (!_useEmail && _step == LoginStep.phone) {
      return _phone.replaceAll(RegExp(r'\D'), '').length == 10;
    }
    return true;
  }

  Widget _buildPrimaryButton(bool isMalayalam) {
    final active = _canSubmit;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: active ? _kBrandGreen : _kDisabledBtn,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: active ? _handlePrimaryAction : null,
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
                    style: TextStyle(
                      color: active ? Colors.white : _kHelperText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

  /// Returns an error message when the verified [backendRole] does not match
  /// the portal selected at the top of the screen, or null when it is allowed.
  ///
  /// Signing in only proves who the account is (phone ownership via OTP, or
  /// email + password). It must NOT let a student / parent account open the
  /// teacher board, or a teacher open the student board, just because the
  /// wrong tab happened to be selected.
  String? _portalRoleMismatch(String? backendRole, bool isMalayalam) {
    final role = backendRole?.toLowerCase();
    if (_portal == LoginPortal.teacher) {
      if (role == 'teacher' || role == 'admin') return null;
      return isMalayalam
          ? 'ഈ അക്കൗണ്ട് ഒരു അധ്യാപക അക്കൗണ്ട് അല്ല. വിദ്യാർത്ഥി / രക്ഷിതാവ് ടാബിൽ സൈൻ ഇൻ ചെയ്യുക.'
          : 'This is not a teacher account. Use the Student / Parent tab to sign in.';
    }
    // Student / Parent portal: a teacher account belongs on the Teacher tab.
    if (role == 'teacher') {
      return isMalayalam
          ? 'ഇത് ഒരു അധ്യാപക അക്കൗണ്ട് ആണ്. അധ്യാപകൻ ടാബിൽ സൈൻ ഇൻ ചെയ്യുക.'
          : 'This is a teacher account. Use the Teacher tab to sign in.';
    }
    return null;
  }

  /// The board to open, derived from the verified backend [backendRole] so the
  /// correct portal always opens regardless of any UI selection. Falls back to
  /// the selected portal when the backend did not return a role.
  String _resolveRole(String? backendRole) {
    final role = backendRole?.toLowerCase();
    if (role == 'teacher') return 'teacher';
    if (_portal == LoginPortal.studentParent && role == 'parent') return 'parent';
    return _selectedRole;
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
        color: ColorPalette.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _kPanelBorder),
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
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? _kBrandGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : _kHelperText,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _kHelperText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isMalayalam) {
    return Column(
      children: [
        const SizedBox(
          width: 64,
          height: 40,
          child: CustomPaint(painter: _ArchLogoPainter()),
        ),
        const SizedBox(height: 12),
        const Text(
          'Alif',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 30,
            height: 1.0,
            fontWeight: FontWeight.w600,
            color: _kBrandGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isMalayalam ? 'സൈൻ ഇൻ' : 'SIGN IN',
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
            color: _kHelperText,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneForm(bool isMalayalam) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '+91',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: ColorPalette.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                    hintText: '98XXXXXXXX',
                    hintStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: _kHelperText,
                    ),
                  ),
                  onChanged: (value) => setState(() => _phone = value),
                  validator: _validatePhone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: _kDivider),
          const SizedBox(height: 10),
          Text(
            isMalayalam ? '10 അക്ക മൊബൈൽ നമ്പർ' : '10-digit mobile number',
            style: const TextStyle(fontSize: 12.5, color: _kHelperText),
          ),
        ],
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
    final style = TextButton.styleFrom(
      foregroundColor: _kBrandGreen,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
    if (_useEmail) {
      return TextButton.icon(
        onPressed: _isLoading ? null : _switchToPhone,
        style: style,
        icon: const Icon(Icons.phone_iphone, size: 18),
        label: Text(
          isMalayalam
              ? 'ഫോൺ നമ്പർ ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യുക'
              : 'Sign in with phone number',
        ),
      );
    }
    return TextButton.icon(
      onPressed: _isLoading ? null : _switchToEmail,
      style: style,
      icon: const Icon(Icons.mail_outline_rounded, size: 18),
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

    final user = result.data?['user'];
    final backendRole = user is Map ? user['role']?.toString() : null;

    // The OTP only proves ownership of the phone number. Make sure the verified
    // account actually matches the chosen portal before opening any board.
    final mismatch = _portalRoleMismatch(backendRole, _isMalayalam);
    if (mismatch != null) {
      setState(() {
        _isLoading = false;
        _error = mismatch;
      });
      return;
    }

    setState(() => _isLoading = false);

    final hasParentAccess =
        _portal == LoginPortal.studentParent ||
        (user is Map && user['has_parent_access'] == true);

    // Capture the verified user's display name so the portal can greet them by
    // name (a phone/OTP session has no Supabase session to read this from).
    if (user is Map) {
      MobileGoogleAuthService.setSessionDisplayUser(
        name: user['name']?.toString(),
        email: user['email']?.toString(),
      );
    }

    // Route by the verified backend role so the correct board always opens
    // (a guardian account opens the parent child-picker directly).
    final role = _resolveRole(backendRole);

    widget.onLoginSuccess(role, hasParentAccess: hasParentAccess);
  }

  void _handleEmailSubmit() async {
    try {
      final result = await MobileGoogleAuthService.signInWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
        allowedRoles: _portal == LoginPortal.teacher
            ? const {'teacher', 'admin'}
            : const {'student', 'parent'},
      );
      if (!mounted) {
        return;
      }

      // Enforce that the verified account matches the chosen portal; otherwise
      // sign back out so no teacher/student board opens for the wrong account.
      final mismatch = _portalRoleMismatch(result.role, _isMalayalam);
      if (mismatch != null) {
        await MobileGoogleAuthService.signOut();
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _error = mismatch;
        });
        return;
      }

      widget.onLoginSuccess(
        _resolveRole(result.role),
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

/// Thin-line mihrab arch used as the minimal Alif sign-in mark.
class _ArchLogoPainter extends CustomPainter {
  const _ArchLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kBrandGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.12, h)
      ..lineTo(w * 0.12, h * 0.42)
      ..cubicTo(w * 0.12, h * 0.06, w * 0.88, h * 0.06, w * 0.88, h * 0.42)
      ..lineTo(w * 0.88, h);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArchLogoPainter oldDelegate) => false;
}
