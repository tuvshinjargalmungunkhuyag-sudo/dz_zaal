import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Алхам: 0=утас, 1=OTP, 2=нэр оруулах
  int _step = 0;

  final _phoneController = TextEditingController();
  final _otpController   = TextEditingController();
  final _nameController  = TextEditingController();

  String _verificationId = '';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ── Алхам 1: OTP илгээх ─────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (phone.length != 8) {
      setState(() => _error = 'Утасны дугаар буруу байна. 8 тоо оруулна уу');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    await AuthService.verifyPhone(
      phone: phone,
      onAutoVerified: (credential) async {
        // Android автоматаар OTP-г унших үед
        await FirebaseAuth.instance.signInWithCredential(credential);
        await _checkName();
      },
      onFailed: (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = _parseAuthError(e.code);
          });
        }
      },
      onCodeSent: (verificationId, _) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
            _step = 1;
          });
        }
      },
    );
  }

  // ── Алхам 2: OTP баталгаажуулах ─────────────────────────────────────────
  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Утасны дугаарт ирсэн 6 оронтой кодоо оруулна уу');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await AuthService.signInWithOtp(_verificationId, otp);
      await _checkName();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = _parseAuthError(e.code);
        });
      }
    }
  }

  // ── Нэр шалгах: auth stream автоматаар MainShell руу явна ───────────────
  Future<void> _checkName() async {
    // Нэр байгаа эсэхээс үл хамааран MainShell руу шилжинэ
    if (mounted) setState(() => _isLoading = false);
  }

  String _parseAuthError(String code) {
    switch (code) {
      case 'invalid-phone-number':  return 'Утасны дугаар буруу байна';
      case 'too-many-requests':     return 'Хэт олон оролдлого. Түр хүлээнэ үү';
      case 'invalid-verification-code': return 'OTP код буруу байна';
      case 'session-expired':       return 'Код хугацаа дууссан. Дахин илгээнэ үү';
      default:                      return 'Алдаа гарлаа ($code)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // ── Logo / гарчиг ─────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.secondary, AppTheme.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text('🏀', style: TextStyle(fontSize: 38)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Говийн Спорт',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _step == 0
                          ? 'Утасны дугаараа оруулна уу'
                          : '+976 ${_phoneController.text} дугаарт илгээсэн\n6 оронтой кодоо оруулна уу',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Алхамын progress indicator ────────────────────────────────
              Row(
                children: List.generate(2, (i) {
                  final isActive = _step >= i;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 1 ? 6 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.secondary
                            : AppTheme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // ── Алхамын мэдэгдэл ─────────────────────────────────────────
              if (_step > 0)
                GestureDetector(
                  onTap: _isLoading ? null : () => setState(() {
                    _step = 0;
                    _otpController.clear();
                    _error = null;
                  }),
                  child: Row(
                    children: const [
                      Icon(Icons.arrow_back_ios_rounded,
                          color: AppTheme.secondary, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Өөр дугаар ашиглах',
                        style: TextStyle(
                            color: AppTheme.secondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),

              if (_step > 0) const SizedBox(height: 20),

              // ── Input хэсэг ───────────────────────────────────────────────
              if (_step == 0) ...[
                _label('Утасны дугаар'),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 18, letterSpacing: 2),
                  decoration: _inputDecoration(
                    hint: '8800 1234',
                    prefix: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Text('+976',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  onSubmitted: (_) => _sendOtp(),
                ),
              ] else if (_step == 1) ...[
                _label('Баталгаажуулах код'),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 24,
                      letterSpacing: 8, fontWeight: FontWeight.w700),
                  decoration: _inputDecoration(hint: '000000'),
                  onSubmitted: (_) => _verifyOtp(),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () {
                      setState(() { _step = 0; _error = null; });
                    },
                    child: const Text(
                      'Код дахин илгээх',
                      style: TextStyle(color: AppTheme.secondary, fontSize: 13),
                    ),
                  ),
                ),
              ],

              // ── Алдаа ─────────────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: AppTheme.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Товч ──────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _step == 0
                          ? _sendOtp
                          : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.divider,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _step == 0 ? 'Код илгээх' : 'Нэвтрэх',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Footer ────────────────────────────────────────────────────
              Center(
                child: Text(
                  'Говийн Спорт • Даланзадгад',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefix,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textSecondary),
      prefixIcon: icon != null
          ? Icon(icon, color: AppTheme.secondary, size: 20)
          : null,
      prefix: prefix,
      filled: true,
      fillColor: AppTheme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5),
      ),
    );
  }
}
