import 'package:flutter/material.dart';

import '../services/google_auth_service.dart';
import '../components/alif_logo.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  _OtpStep _step = _OtpStep.phone;
  bool _isBusy = false;
  String? _error;
  String _phone = '';
  String _otp = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String? _normalizePhone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }
    final withPlus = raw.startsWith('+') ? raw : '+$raw';
    return RegExp(r'^\+\d{6,15}$').hasMatch(withPlus) ? withPlus : null;
  }

  String? _validatePhone(String? value) {
    if (_normalizePhone(value) == null) {
      return 'Enter a valid phone number with country code, e.g. +9198XXXXXXXX';
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

  @override
  Widget build(BuildContext context) {
    final isOtpStep = _step == _OtpStep.otp;

    return Scaffold(
      body: Container(
        color: const Color(0xFFEDEFF1),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  elevation: 18,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: AlifLogo(height: 84)),
                          const SizedBox(height: 20),
                          const Text(
                            'Admin Sign In',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isOtpStep
                                ? 'Enter the one-time code sent to $_phone on WhatsApp.'
                                : 'Sign in with your registered phone number. A one-time code will be sent to your WhatsApp.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 26),
                          if (!isOtpStep)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFEDEFF2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                enabled: !_isBusy,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                decoration: InputDecoration(
                                  hintText: '+9198XXXXXXXX',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.phone_iphone_rounded,
                                    color: Color(0xFF6B7280),
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 18,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                ),
                                validator: _validatePhone,
                                onFieldSubmitted: (_) => _handleSendOtp(),
                              ),
                            )
                          else
                            OtpBoxField(
                              length: 4,
                              enabled: !_isBusy,
                              onChanged: (value) => _otp = value,
                              onCompleted: (value) {
                                _otp = value;
                                _handleVerifyOtp();
                              },
                            ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _isBusy
                                ? null
                                : (isOtpStep
                                      ? _handleVerifyOtp
                                      : _handleSendOtp),
                            icon: _isBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    isOtpStep
                                        ? Icons.login_rounded
                                        : Icons.sms_rounded,
                                  ),
                            label: Text(
                              _isBusy
                                  ? (isOtpStep
                                        ? 'Verifying...'
                                        : 'Sending code...')
                                  : (isOtpStep ? 'Verify & Sign In' : 'Send OTP'),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          if (isOtpStep) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _isBusy ? null : _backToPhone,
                              child: const Text('Use a different number'),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
