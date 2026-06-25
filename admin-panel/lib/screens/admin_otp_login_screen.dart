import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/alif_logo.dart';
import '../services/google_auth_service.dart';
import '../components/otp_box_field.dart';

/// Phone + OTP sign-in screen for the admin panel.
///
/// Admins enter their registered phone number, receive a one-time password via
/// WhatsApp, and verify it to obtain an app session token. Only profiles with
/// the `admin` role are allowed through.
class AdminOtpLoginScreen extends StatefulWidget {
  const AdminOtpLoginScreen({super.key, required this.onLoginSuccess});

  final ValueChanged<String> onLoginSuccess;

  @override
  State<AdminOtpLoginScreen> createState() => _AdminOtpLoginScreenState();
}

enum _OtpStep { phone, otp }

class _AdminOtpLoginScreenState extends State<AdminOtpLoginScreen> {
  /// Country code automatically prepended to the 10-digit local number.
  static const String _countryCode = '+91';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  _OtpStep _step = _OtpStep.phone;
  bool _isBusy = false;
  bool _useEmail = false;
  bool _obscurePassword = true;
  String? _error;
  String _phone = '';
  String _otp = '';

  String _friendlyError(Object error) {
    final raw = error.toString().replaceFirst('Bad state: ', '').trim();
    final lower = raw.toLowerCase();

    if (lower.contains('failed to fetch') ||
        lower.contains('clientexception') ||
        lower.contains('request-otp') ||
        lower.contains('verify-otp') ||
        lower.contains('unable to connect')) {
      return 'Cannot reach the server. Please ensure backend API is running on localhost:3000 and try again.';
    }

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Server request timed out. Please try again.';
    }

    return raw.isEmpty ? 'Something went wrong. Please try again.' : raw;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchToEmail() {
    setState(() {
      _useEmail = true;
      _step = _OtpStep.phone;
      _otp = '';
      _otpController.clear();
      _error = null;
    });
  }

  void _switchToPhone() {
    setState(() {
      _useEmail = false;
      _step = _OtpStep.phone;
      _otp = '';
      _otpController.clear();
      _error = null;
    });
  }

  String? _normalizePhone(String? value) {
    var digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    // Tolerate a leading India country code (91) if the user pasted a full
    // number like +919876543210 -> 12 digits. Strip the leading 91 so we keep
    // only the 10-digit local number.
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    if (digits.length != 10) {
      return null;
    }
    return '$_countryCode$digits';
  }

  String? _validatePhone(String? value) {
    if (_normalizePhone(value) == null) {
      return 'Enter your 10-digit mobile number (e.g. 9876543210)';
    }
    return null;
  }

  String? _validateOtp(String? value) {
    final otp = value?.trim() ?? '';
    if (otp.isEmpty) {
      return 'OTP is required';
    }
    if (!RegExp(r'^\d{4,8}$').hasMatch(otp)) {
      return 'Enter the numeric code from WhatsApp';
    }
    return null;
  }

  Future<void> _handleSendOtp() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phone = _normalizePhone(_phoneController.text)!;
    setState(() => _isBusy = true);

    try {
      await AdminAuthService.requestOtp(phone);
      if (!mounted) {
        return;
      }
      setState(() {
        _phone = phone;
        _step = _OtpStep.otp;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() => _error = null);

    final otpError = _validateOtp(_otp);
    if (otpError != null) {
      setState(() => _error = otpError);
      return;
    }

    setState(() => _isBusy = true);

    try {
      final result = await AdminAuthService.verifyOtp(
        phone: _phone,
        otp: _otp.trim(),
      );
      if (!mounted) {
        return;
      }
      widget.onLoginSuccess(result.token);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _handleEmailSignIn() async {
    setState(() => _error = null);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your admin email and password');
      return;
    }

    setState(() => _isBusy = true);

    try {
      final result = await AdminAuthService.signInWithPassword(
        email: email,
        password: password,
      );
      if (!mounted) {
        return;
      }
      widget.onLoginSuccess(result.token);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _backToPhone() {
    setState(() {
      _step = _OtpStep.phone;
      _otp = '';
      _otpController.clear();
      _error = null;
    });
  }

  // ===== Brand palette (matches the Alif admin theme) =====
  static const Color _brandDark = Color(0xFF0F766E);
  static const Color _brandLight = Color(0xFF14B8A6);
  static const Color _bgBottom = Color(0xFFE9F4F1);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textTertiary = Color(0xFF64748B);
  static const Color _neutral100 = Color(0xFFF1F5F9);
  static const Color _neutral200 = Color(0xFFE5E7EB);
  static const Color _neutral500 = Color(0xFF64748B);
  static const Color _neutral600 = Color(0xFF475569);
  static const Color _danger = Color(0xFFDC2626);

  static const LinearGradient _brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_brandDark, _brandLight],
  );

  @override
  Widget build(BuildContext context) {
    final isOtpStep = _step == _OtpStep.otp;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_buildCard(isOtpStep)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(bool isOtpStep) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _neutral200),
        boxShadow: [
          BoxShadow(
            color: _brandDark.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBrandHeader(isOtpStep),
            const SizedBox(height: 18),
            _buildAuthMethodTabs(),
            const SizedBox(height: 18),
            if (_useEmail)
              _buildEmailStep()
            else if (isOtpStep)
              _buildOtpStep()
            else
              _buildPhoneStep(),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _danger.withValues(alpha: 0.32)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: _danger,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: _danger, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            _buildPrimaryButton(isOtpStep),
            if (!_useEmail && isOtpStep) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: _isBusy ? null : _backToPhone,
                child: const Text('Use a different number'),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: _neutral200, height: 1),
            const SizedBox(height: 16),
            const Text(
              '\u00a9 2026 Alif Online Moral School',
              style: TextStyle(fontSize: 12, color: _neutral500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader(bool isOtpStep) {
    final subtitle = _useEmail
        ? 'Sign in with your admin email and password'
        : isOtpStep
        ? 'Enter the one-time code sent to $_phone on WhatsApp'
        : 'Secure phone-based access for administrators';

    return Column(
      children: [
        const AlifLogo(height: 82),
        const SizedBox(height: 14),
        const Text(
          'Admin Portal',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28 / 1.6,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: _textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthMethodTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _neutral100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _neutral200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _methodTab(
              label: 'Email',
              selected: _useEmail,
              onTap: _switchToEmail,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _methodTab(
              label: 'Mobile Number',
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
      onTap: _isBusy ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? _brandDark : _neutral500,
          ),
        ),
      ),
    );
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
          const SizedBox(height: 16),
        ],
        child,
      ],
    );
  }

  Widget _buildPhoneStep() {
    return _buildFormStepShell(
      accent: _brandLight,
      icon: Icons.phone_iphone,
      child: Column(
        children: [
          const Text(
            'Enter your registered phone number',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _neutral600),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            enabled: !_isBusy,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '98XXXXXXXX',
              prefixText: '$_countryCode ',
              prefixIcon: const Icon(Icons.phone_iphone),
              helperText:
                  'Enter 10-digit mobile (e.g. 9876543210). +91 is added automatically.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            validator: _validatePhone,
            onFieldSubmitted: (_) => _handleSendOtp(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return _buildFormStepShell(
      accent: _brandLight,
      child: Column(
        children: [
          const Text(
            'Enter your admin email and password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _neutral600),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isBusy,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !_isBusy,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: _isBusy
                    ? null
                    : () =>
                          setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onFieldSubmitted: (_) => _handleEmailSignIn(),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return _buildFormStepShell(
      accent: _brandLight,
      icon: Icons.verified_user_outlined,
      child: Column(
        children: [
          Text(
            'Enter the OTP sent to $_phone',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _neutral600),
          ),
          const SizedBox(height: 16),
          OtpBoxField(
            length: 4,
            enabled: !_isBusy,
            onChanged: (value) => _otp = value,
            onCompleted: (value) {
              _otp = value;
              _handleVerifyOtp();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(bool isOtpStep) {
    final enabled = !_isBusy;
    return Opacity(
      opacity: enabled ? 1 : 0.75,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _brandGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _brandDark.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled
                ? (_useEmail
                      ? _handleEmailSignIn
                      : (isOtpStep ? _handleVerifyOtp : _handleSendOtp))
                : null,
            child: SizedBox(
              height: 56,
              child: Center(
                child: _isBusy
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
                            _useEmail
                                ? 'Sign In'
                                : isOtpStep
                                ? 'Verify & Sign In'
                                : 'Send OTP',
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
}
