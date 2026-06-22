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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F766E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: AlifLogo(height: 88)),
                          const SizedBox(height: 18),
                          Text(
                            'Admin Sign In',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isOtpStep
                                ? 'Enter the one-time code sent to $_phone on WhatsApp.'
                                : 'Sign in with your registered phone number. A one-time code will be sent to your WhatsApp.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          if (!isOtpStep)
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              enabled: !_isBusy,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                hintText: '+9198XXXXXXXX',
                                prefixIcon: const Icon(Icons.phone_iphone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              validator: _validatePhone,
                              onFieldSubmitted: (_) => _handleSendOtp(),
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
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
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
