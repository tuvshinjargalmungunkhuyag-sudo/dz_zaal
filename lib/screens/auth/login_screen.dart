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
  // mode: login / register
  bool _isRegisterMode = false;

  // register алхам: 0=мэдээлэл, 1=код
  int _registerStep = 0;

  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController     = TextEditingController();
  final _codeController     = TextEditingController();

  final _nameFocus     = FocusNode();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();
  final _codeFocus     = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  void _showKeyboard(FocusNode node) {
    node.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  // ── Нэвтрэх ───────────────────────────────────────────────────────────────
  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Зөв email хаяг оруулна уу');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Нууц үг хамгийн багадаа 6 тэмдэгт байх ёстой');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await AuthService.signInWithEmail(email, password);
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = _parseLoginError(e.code); });
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg == 'email-not-verified') {
          setState(() {
            _isLoading = false;
            _error = 'Email баталгаажаагүй байна. Эхлээд бүртгүүлнэ үү';
          });
        } else {
          setState(() { _isLoading = false; _error = msg; });
        }
      }
    }
  }

  // ── Бүртгүүлэх - Алхам 1: Firebase user үүсгэж код илгээх ────────────────
  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      setState(() => _error = 'Нэрээ оруулна уу');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Зөв email хаяг оруулна уу');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Нууц үг хамгийн багадаа 6 тэмдэгт байх ёстой');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await AuthService.registerWithEmail(
        email: email,
        password: password,
        name: name,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = _parseRegisterError(e.code); });
      return;
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      return;
    }

    // Firebase user үүссэн — код илгээхийг оролдоно
    try {
      await AuthService.sendVerificationCode();
      if (mounted) setState(() { _isLoading = false; _registerStep = 1; });
    } catch (e) {
      // Код илгээхэд алдаа → Firebase user-г буцааж устгана (retry боломжтой болгох)
      await AuthService.deleteCurrentUser();
      if (mounted) setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── Бүртгүүлэх - Алхам 2: Код баталгаажуулах ─────────────────────────────
  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Email-д ирсэн 6 оронтой кодоо оруулна уу');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await AuthService.verifyEmailCode(code);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── Код дахин илгээх ──────────────────────────────────────────────────────
  Future<void> _resendCode() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await AuthService.sendVerificationCode();
      if (mounted) setState(() {
        _isLoading = false;
        _codeController.clear(); // хуучин кодыг арилгана
      });
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _parseLoginError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':   return 'Email эсвэл нууц үг буруу байна';
      case 'wrong-password':       return 'Нууц үг буруу байна';
      case 'user-disabled':        return 'Энэ аккаунт хаагдсан байна';
      case 'too-many-requests':    return 'Хэт олон оролдлого. Түр хүлээнэ үү';
      case 'invalid-email':        return 'Email хаяг буруу байна';
      default:                     return 'Нэвтрэхэд алдаа гарлаа ($code)';
    }
  }

  String _parseRegisterError(String code) {
    switch (code) {
      case 'email-already-in-use':  return 'Энэ email аль хэдийн бүртгэлтэй байна';
      case 'invalid-email':         return 'Email хаяг буруу байна';
      case 'weak-password':         return 'Нууц үг хэтэрхий энгийн байна';
      case 'too-many-requests':     return 'Хэт олон оролдлого. Түр хүлээнэ үү';
      case 'operation-not-allowed': return 'Email бүртгэл идэвхгүй байна. Администратортой холбоо барина уу';
      case 'network-request-failed':return 'Интернэт холболт алдаатай байна';
      default:                      return 'Бүртгүүлэхэд алдаа гарлаа ($code)';
    }
  }

  void _switchMode(bool toRegister) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isRegisterMode = toRegister;
      _registerStep = 0;
      _error = null;
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      if (_isRegisterMode && _registerStep == 1) {
                        setState(() { _registerStep = 0; _error = null; _codeController.clear(); });
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppTheme.textSecondary,
                    padding: EdgeInsets.zero,
                  ),
                ),

                // Logo / гарчиг
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
                        _isRegisterMode
                            ? (_registerStep == 0
                                ? 'Шинэ аккаунт үүсгэх'
                                : '${_emailController.text.trim()} хаягт\nилгээсэн 6 оронтой кодоо оруулна уу')
                            : 'Email хаягаараа нэвтэрнэ үү',
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

                // Progress indicator (register mode)
                if (_isRegisterMode) ...[
                  Row(
                    children: List.generate(2, (i) {
                      final isActive = _registerStep >= i;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 1 ? 6 : 0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.secondary : AppTheme.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                ],

                // ── Input хэсэг ─────────────────────────────────────────────

                // Login mode
                if (!_isRegisterMode) ...[
                  _label('Email хаяг'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                    decoration: _inputDecoration(
                      hint: 'name@example.com',
                      icon: Icons.email_outlined,
                    ),
                    onTap: () => _showKeyboard(_emailFocus),
                    onSubmitted: (_) => _showKeyboard(_passwordFocus),
                  ),
                  const SizedBox(height: 16),
                  _label('Нууц үг'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                    decoration: _inputDecoration(
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    onTap: () => _showKeyboard(_passwordFocus),
                    onSubmitted: (_) => _login(),
                  ),
                ],

                // Register mode — step 0: мэдээлэл
                if (_isRegisterMode && _registerStep == 0) ...[
                  _label('Нэр'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                    decoration: _inputDecoration(hint: 'Таны нэр', icon: Icons.person_outline_rounded),
                    onTap: () => _showKeyboard(_nameFocus),
                    onSubmitted: (_) => _showKeyboard(_emailFocus),
                  ),
                  const SizedBox(height: 16),
                  _label('Email хаяг'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                    decoration: _inputDecoration(hint: 'name@example.com', icon: Icons.email_outlined),
                    onTap: () => _showKeyboard(_emailFocus),
                    onSubmitted: (_) => _showKeyboard(_passwordFocus),
                  ),
                  const SizedBox(height: 16),
                  _label('Нууц үг'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                    decoration: _inputDecoration(hint: '••••••••  (6+ тэмдэгт)', icon: Icons.lock_outline_rounded).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    onTap: () => _showKeyboard(_passwordFocus),
                    onSubmitted: (_) => _register(),
                  ),
                ],

                // Register mode — step 1: код
                if (_isRegisterMode && _registerStep == 1) ...[
                  _label('Баталгаажуулах код'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codeController,
                    focusNode: _codeFocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                      letterSpacing: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: _inputDecoration(hint: '000000'),
                    onTap: () => _showKeyboard(_codeFocus),
                    onSubmitted: (_) => _verifyCode(),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _resendCode,
                      child: const Text(
                        'Код дахин илгээх',
                        style: TextStyle(color: AppTheme.secondary, fontSize: 13),
                      ),
                    ),
                  ),
                ],

                // Алдаа
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Үндсэн товч
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _isRegisterMode
                            ? (_registerStep == 0 ? _register : _verifyCode)
                            : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.divider,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isRegisterMode
                                ? (_registerStep == 0 ? 'Бүртгүүлэх' : 'Баталгаажуулах')
                                : 'Нэвтрэх',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Mode switch
                if (!(_isRegisterMode && _registerStep == 1))
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isRegisterMode ? 'Аккаунт байгаа юу? ' : 'Аккаунт байхгүй юу? ',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => _switchMode(!_isRegisterMode),
                          child: Text(
                            _isRegisterMode ? 'Нэвтрэх' : 'Бүртгүүлэх',
                            style: const TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Footer
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

  InputDecoration _inputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textSecondary),
      prefixIcon: icon != null ? Icon(icon, color: AppTheme.secondary, size: 20) : null,
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
