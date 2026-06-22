import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';
import '../../services/google_auth_service.dart';

/// Which portal the user is signing in to. Student and parent share a single
/// account sign-in ([LoginPortal.account]); the actual role is resolved by the
/// backend and a parent-capable account can switch views from inside the app.
/// Teachers authenticate separately with a username + password.
enum LoginPortal { account, teacher }

class MobileGoogleLoginScreen extends StatefulWidget {
  const MobileGoogleLoginScreen({super.key, required this.onLoginSuccess});

  final void Function(String role, {bool hasParentAccess}) onLoginSuccess;

  @override
  State<MobileGoogleLoginScreen> createState() =>
      _MobileGoogleLoginScreenState();
}

class _MobileGoogleLoginScreenState extends State<MobileGoogleLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginPortal _portal = LoginPortal.account;
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;
    final busy = _loading || _googleLoading;
    final isTeacher = _portal == LoginPortal.teacher;

    final portalTitle = isTeacher
        ? (isMalayalam ? 'അലിഫ് ടീച്ചർ പോർട്ടൽ' : 'Alif Teacher Portal')
        : (isMalayalam ? 'അലിഫ് പോർട്ടൽ' : 'Alif Portal');
    final portalSubtitle = isTeacher
        ? (isMalayalam
              ? 'യൂസർനെയിമും പാസ്‌വേഡും നൽകി സൈൻ ഇൻ ചെയ്യുക.'
              : 'Sign in with your username and password.')
        : (isMalayalam
              ? 'ഇമെയിലും പാസ്‌വേഡും നൽകി സൈൻ ഇൻ ചെയ്യുക. രക്ഷിതാവിലേക്ക് ആപ്പിനുള്ളിൽ മാറാം.'
              : 'Sign in with your email and password. Switch to parent inside the app.');
    final portalIcon = isTeacher ? Icons.co_present_rounded : Icons.school;

    return Scaffold(
      backgroundColor: ColorPalette.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: SpacingScale.lg,
              vertical: SpacingScale.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: EdgeInsets.all(SpacingScale.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: ColorPalette.neutral200),
                  boxShadow: [
                    BoxShadow(
                      color: ColorPalette.primaryDark.withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PortalToggle(
                        portal: _portal,
                        isMalayalam: isMalayalam,
                        enabled: !busy,
                        onChanged: (portal) => setState(() {
                          _portal = portal;
                          _error = null;
                        }),
                      ),
                      SizedBox(height: SpacingScale.lg),
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                ColorPalette.primaryLight,
                                ColorPalette.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: ColorPalette.secondary.withValues(
                                alpha: 0.40,
                              ),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ColorPalette.primaryDark.withValues(
                                  alpha: 0.28,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            portalIcon,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: SpacingScale.md),
                      Text(
                        portalTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: Color(0xFF103B2C),
                        ),
                      ),
                      SizedBox(height: SpacingScale.xs),
                      Text(
                        portalSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: Color(0xFF5F6C65),
                        ),
                      ),
                      SizedBox(height: SpacingScale.xl),

                      // Username / email field
                      _FieldLabel(
                        isTeacher
                            ? (isMalayalam
                                  ? 'യൂസർനെയിം / ഇമെയിൽ'
                                  : 'Username / Email')
                            : (isMalayalam ? 'ഇമെയിൽ' : 'Email'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        enabled: !busy,
                        keyboardType: isTeacher
                            ? TextInputType.text
                            : TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: [
                          isTeacher
                              ? AutofillHints.username
                              : AutofillHints.email,
                        ],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(
                          hint: isTeacher
                              ? (isMalayalam
                                    ? 'യൂസർനെയിം അല്ലെങ്കിൽ ഇമെയിൽ'
                                    : 'username or email')
                              : (isMalayalam
                                    ? 'നിങ്ങളുടെ ഇമെയിൽ'
                                    : 'you@example.com'),
                          icon: isTeacher
                              ? Icons.person_outline_rounded
                              : Icons.mail_outline_rounded,
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return isTeacher
                                ? (isMalayalam
                                      ? 'യൂസർനെയിം നൽകുക'
                                      : 'Enter your username')
                                : (isMalayalam
                                      ? 'ഇമെയിൽ നൽകുക'
                                      : 'Enter your email');
                          }
                          if (!isTeacher &&
                              (!text.contains('@') || !text.contains('.'))) {
                            return isMalayalam
                                ? 'ശരിയായ ഇമെയിൽ നൽകുക'
                                : 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: SpacingScale.md),

                      // Password field
                      _FieldLabel(isMalayalam ? 'പാസ്‌വേഡ്' : 'Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !busy,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        onFieldSubmitted: (_) => _handleEmailLogin(),
                        decoration: _inputDecoration(
                          hint: isMalayalam ? 'പാസ്‌വേഡ്' : 'Your password',
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            tooltip: _obscurePassword
                                ? (isMalayalam ? 'കാണിക്കുക' : 'Show')
                                : (isMalayalam ? 'മറയ്ക്കുക' : 'Hide'),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF6B7280),
                            ),
                            onPressed: busy
                                ? null
                                : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return isMalayalam
                                ? 'പാസ്‌വേഡ് നൽകുക'
                                : 'Enter your password';
                          }
                          return null;
                        },
                      ),

                      if (_error != null) ...[
                        SizedBox(height: SpacingScale.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFB91C1C),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: SpacingScale.xl),
                      FilledButton(
                        onPressed: busy ? null : _handleEmailLogin,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _loading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isMalayalam
                                        ? 'സൈൻ ഇൻ ചെയ്യുന്നു...'
                                        : 'Signing in...',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                isMalayalam ? 'സൈൻ ഇൻ' : 'Sign in',
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),

                      // Google sign-in is only offered to students / parents.
                      // Teachers authenticate with a username + password.
                      if (!isTeacher) ...[
                        SizedBox(height: SpacingScale.lg),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: Color(0xFFE5E7EB)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                isMalayalam ? 'അല്ലെങ്കിൽ' : 'or',
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: Color(0xFFE5E7EB)),
                            ),
                          ],
                        ),
                        SizedBox(height: SpacingScale.lg),
                        OutlinedButton.icon(
                          onPressed: busy ? null : _handleGoogleSignIn,
                          icon: _googleLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login_rounded, size: 22),
                          label: Text(
                            _googleLoading
                                ? (isMalayalam
                                      ? 'സൈൻ ഇൻ ചെയ്യുന്നു...'
                                      : 'Signing in...')
                                : (isMalayalam
                                      ? 'Google ഉപയോഗിച്ച് സൈൻ ഇൻ'
                                      : 'Sign in with Google'),
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            foregroundColor: const Color(0xFF103B2C),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
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
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: ColorPalette.primaryDark, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
      ),
    );
  }

  Future<void> _handleEmailLogin() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Teachers authenticate with a username + password (FRD §4.3, no OTP).
      if (_portal == LoginPortal.teacher) {
        final result = await MobileGoogleAuthService.signInTeacher(
          username: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) {
          return;
        }
        widget.onLoginSuccess(result.role, hasParentAccess: false);
        return;
      }

      // Student and parent share one sign-in: the backend resolves the actual
      // role, and a parent-capable account can switch views inside the app.
      final result = await MobileGoogleAuthService.signInWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      widget.onLoginSuccess(
        result.role,
        hasParentAccess: result.hasParentAccess,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });

    try {
      await MobileGoogleAuthService.signIn();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  Future<void> _restoreSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await MobileGoogleAuthService.restoreSession();
      if (!mounted || result == null) {
        return;
      }
      widget.onLoginSuccess(
        result.role,
        hasParentAccess: result.hasParentAccess,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
      ),
    );
  }
}

/// Segmented selector switching the login page between the shared
/// student/parent account sign-in and the teacher sign-in (teachers use a
/// username + password).
class _PortalToggle extends StatelessWidget {
  const _PortalToggle({
    required this.portal,
    required this.isMalayalam,
    required this.enabled,
    required this.onChanged,
  });

  final LoginPortal portal;
  final bool isMalayalam;
  final bool enabled;
  final ValueChanged<LoginPortal> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _segment(
            label: isMalayalam ? 'വിദ്യാർഥി / രക്ഷിതാവ്' : 'Student / Parent',
            icon: Icons.school_rounded,
            selected: portal == LoginPortal.account,
            onTap: enabled ? () => onChanged(LoginPortal.account) : null,
          ),
          _segment(
            label: isMalayalam ? 'അധ്യാപകൻ' : 'Teacher',
            icon: Icons.co_present_rounded,
            selected: portal == LoginPortal.teacher,
            onTap: enabled ? () => onChanged(LoginPortal.teacher) : null,
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1B6B3A) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
