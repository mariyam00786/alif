import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  /// Country code automatically prepended to the 10-digit local number.
  static const String _countryCode = '+91';

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

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F766E)],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return isWide
              ? _buildWideLayout(context)
              : _buildCompactLayout(context);
        },
      ),
    );
  }

  /// Desktop / large-screen: split-screen with branding on the left and the
  /// sign-in form on a clean surface to the right.
  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildBrandPanel(context)),
        Expanded(
          flex: 4,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildForm(context, showLogo: false),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Phone / narrow-screen: branding gradient background with a floating card.
  ///
  /// The gradient fills the entire viewport and the card is vertically centred,
  /// while still scrolling on very short screens (or when the keyboard opens).
  Widget _buildCompactLayout(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: _gradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Card(
                        elevation: 12,
                        shadowColor: Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _buildForm(context, showLogo: true),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Left branding panel shown on wide screens.
  Widget _buildBrandPanel(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _gradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AlifLogo(height: 96),
              const SizedBox(height: 28),
              Text(
                'Alif Admin Console',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Secure phone-based access for administrators. '
                'Manage students, parents, and activities from one place.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              _buildBrandPoint(
                context,
                Icons.shield_outlined,
                'One-time passcode via WhatsApp',
              ),
              const SizedBox(height: 16),
              _buildBrandPoint(
                context,
                Icons.verified_user_outlined,
                'Admin-only role verification',
              ),
              const SizedBox(height: 16),
              _buildBrandPoint(
                context,
                Icons.devices_outlined,
                'Works across web and desktop',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandPoint(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  /// Step progress indicator (Phone -> Verify).
  Widget _buildStepIndicator(BuildContext context) {
    final isOtpStep = _step == _OtpStep.otp;
    return Row(
      children: [
        _buildStepChip(context, label: '1  Phone', active: !isOtpStep),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        _buildStepChip(context, label: '2  Verify', active: isOtpStep),
      ],
    );
  }

  Widget _buildStepChip(
    BuildContext context, {
    required String label,
    required bool active,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Shared sign-in form used by both layouts.
  Widget _buildForm(BuildContext context, {required bool showLogo}) {
    final isOtpStep = _step == _OtpStep.otp;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLogo) ...[
            const Center(child: AlifLogo(height: 88)),
            const SizedBox(height: 18),
          ],
          _buildStepIndicator(context),
          const SizedBox(height: 22),
          Text(
            'Admin Sign In',
            textAlign: showLogo ? TextAlign.center : TextAlign.left,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            isOtpStep
                ? 'Enter the one-time code sent to $_phone on WhatsApp.'
                : 'Sign in with your registered phone number. A one-time code will be sent to your WhatsApp.',
            textAlign: showLogo ? TextAlign.center : TextAlign.left,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (!isOtpStep)
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
                : (isOtpStep ? _handleVerifyOtp : _handleSendOtp),
            icon: _isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isOtpStep ? Icons.login_rounded : Icons.sms_rounded),
            label: Text(
              _isBusy
                  ? (isOtpStep ? 'Verifying...' : 'Sending code...')
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
              textAlign: showLogo ? TextAlign.center : TextAlign.left,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
