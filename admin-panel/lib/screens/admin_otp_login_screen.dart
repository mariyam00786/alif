import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/google_auth_service.dart';
import '../components/otp_box_field.dart';

/// Phone + OTP sign-in screen for the admin panel.
///
/// Admins enter their registered phone number, receive a one-time password via
/// WhatsApp, and verify it to obtain an app session token. Only profiles with
/// the `admin` role are allowed through.
///
/// The visual style is intentionally minimal: a soft parchment background, a
/// thin mihrab-arch mark, the Alif wordmark, two underline tabs (Phone /
/// Verify) and a single primary action.
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

  // Minimal palette tuned to the reference design.
  static const Color _background = Color(0xFFFFFFFF);
  static const Color _teal = Color(0xFF14635B);
  static const Color _tealSoft = Color(0xFF6E8A85);
  static const Color _muted = Color(0xFF9AA6A1);
  static const Color _gold = Color(0xFFD9A441);
  static const Color _disabledFill = Color(0xFFE7E3D7);
  static const Color _line = Color(0xFFD9D4C6);
  static const Color _danger = Color(0xFFB3261E);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  _OtpStep _step = _OtpStep.phone;
  bool _isBusy = false;
  String? _error;
  String _phone = '';
  String _otp = '';

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String? _normalizePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return null;
    }
    return '$_countryCode$digits';
  }

  String? _validatePhone(String? value) {
    if (_normalizePhone(value) == null) {
      return 'Enter a valid 10-digit mobile number';
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
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
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
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
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

  bool get _isOtpStep => _step == _OtpStep.otp;

  bool get _canContinue {
    if (_isBusy) return false;
    if (_isOtpStep) return _otp.trim().length >= 4;
    return _normalizePhone(_phoneController.text) != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(child: _buildArchMark()),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'Alif',
                        style: TextStyle(
                          fontSize: 38,
                          height: 1.0,
                          fontWeight: FontWeight.w600,
                          color: _teal,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'ADMIN PORTAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _tealSoft,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildTabs(),
                    const SizedBox(height: 28),
                    if (!_isOtpStep) _buildPhoneField() else _buildOtpField(),
                    const SizedBox(height: 14),
                    Text(
                      _isOtpStep
                          ? "Enter the code we sent to $_phone via WhatsApp"
                          : "We'll send a one-time code to this number via WhatsApp",
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: _tealSoft,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _buildContinueButton(),
                    const SizedBox(height: 22),
                    Center(
                      child: TextButton(
                        onPressed: _isBusy
                            ? null
                            : (_isOtpStep ? _backToPhone : _showHelp),
                        style: TextButton.styleFrom(
                          foregroundColor: _teal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          _isOtpStep
                              ? 'Use a different number'
                              : 'Need help signing in?',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _teal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Thin mihrab-arch mark with a small gold dot at the apex.
  Widget _buildArchMark() {
    return const SizedBox(
      width: 56,
      height: 64,
      child: CustomPaint(painter: _ArchPainter(stroke: _teal, dot: _gold)),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(child: _buildTab('PHONE', active: !_isOtpStep)),
        Expanded(child: _buildTab('VERIFY', active: _isOtpStep)),
      ],
    );
  }

  Widget _buildTab(String label, {required bool active}) {
    return GestureDetector(
      onTap: () {
        // Only allow jumping back to the phone tab; verify requires an OTP
        // request first.
        if (!active && label == 'PHONE') _backToPhone();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: active ? _teal : _muted,
              ),
            ),
          ),
          Container(height: 2, color: active ? _teal : _line),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      enabled: !_isBusy,
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: Color(0xFF24302D),
      ),
      cursorColor: _teal,
      decoration: const InputDecoration(
        hintText: 'Phone number',
        hintStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: _muted,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(right: 8, bottom: 2),
          child: Text(
            '$_countryCode ',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF24302D),
            ),
          ),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.only(bottom: 10),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _line, width: 1.4),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _teal, width: 1.6),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _danger, width: 1.4),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _danger, width: 1.6),
        ),
        errorStyle: TextStyle(fontSize: 12, color: _danger),
      ),
      validator: _validatePhone,
      onFieldSubmitted: (_) => _handleSendOtp(),
    );
  }

  Widget _buildOtpField() {
    return OtpBoxField(
      length: 4,
      enabled: !_isBusy,
      onChanged: (value) => setState(() => _otp = value),
      onCompleted: (value) {
        _otp = value;
        _handleVerifyOtp();
      },
    );
  }

  Widget _buildContinueButton() {
    final enabled = _canContinue;
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: enabled
            ? (_isOtpStep ? _handleVerifyOtp : _handleSendOtp)
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _disabledFill,
          disabledForegroundColor: _muted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: _isBusy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(_isOtpStep ? 'Verify & Sign In' : 'Continue'),
      ),
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _background,
        title: const Text('Need help signing in?'),
        content: const Text(
          'Admin access uses your registered phone number. A one-time code is '
          'sent to that number on WhatsApp.\n\nIf you cannot sign in, contact '
          'your Alif system administrator to confirm your number and admin role.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: _teal),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Draws a thin mihrab-style arch (two uprights joined by a rounded crown) with
/// a small filled dot floating above the apex.
class _ArchPainter extends CustomPainter {
  const _ArchPainter({required this.stroke, required this.dot});

  final Color stroke;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final dotR = w * 0.07;
    final top = dotR * 2 + 4; // leave room for the dot above the arch

    final path = Path()
      ..moveTo(w * 0.12, h)
      ..lineTo(w * 0.12, top + h * 0.18)
      // sweep up to the apex
      ..quadraticBezierTo(w * 0.12, top, w * 0.5, top)
      ..quadraticBezierTo(w * 0.88, top, w * 0.88, top + h * 0.18)
      ..lineTo(w * 0.88, h);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = dot
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, dotR + 1), dotR, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ArchPainter oldDelegate) =>
      oldDelegate.stroke != stroke || oldDelegate.dot != dot;
}
