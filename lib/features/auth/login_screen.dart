import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import '../../core/i18n/tr_text.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../data/models/user_account.dart';
import '../../data/services/auth_service.dart';
import '../../state/app_data.dart';
import '../shell/home_shell.dart';
import '../splash/widgets/splash_logo_painter.dart';
import 'widgets/auth_message_box.dart';
import 'widgets/google_button.dart';

enum LoginMode {
  firstLaunch, // setelah splash pertama kali: bisa masuk, daftar, atau lanjut sebagai tamu
  signInOnly, // diminta masuk (misalnya skor di atas 60%): tanpa pilihan tamu
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.mode = LoginMode.firstLaunch, this.reason});

  final LoginMode mode;
  final String? reason; // penjelasan kenapa login diminta

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _register = false; // false = form masuk, true = form daftar
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;
  String? _info;

  bool get _firstLaunch => widget.mode == LoginMode.firstLaunch;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _register = !_register;
      _error = null;
      _info = null;
    });
  }

  void _finish(bool signedIn) {
    if (_firstLaunch) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (BuildContext context) => const HomeShell()),
      );
    } else {
      Navigator.of(context).pop(signedIn);
    }
  }

  /// Menjalankan proses login dan menangani loading serta pesan error.
  Future<void> _run(Future<UserAccount?> Function() action, {String? nullMessage}) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final UserAccount? user = await action();
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _busy = false;
          if (nullMessage != null) _info = nullMessage;
        });
        return;
      }
      await appData.onSignedIn(user);
      if (!mounted) return;
      _finish(true);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    if (_register) {
      await _run(
        () => AuthService.instance
            .signUpWithEmail(_nameController.text.trim(), email, password),
        nullMessage: 'Akun dibuat. Kami mengirim link konfirmasi ke $email. '
            'Buka link itu, lalu masuk di sini.',
      );
      if (mounted && _info != null) {
        setState(() {
          _register = false; // pindah ke form masuk, email tetap terisi
          _passwordController.clear();
          _confirmController.clear();
        });
      }
    } else {
      await _run(() => AuthService.instance.signInWithEmail(email, password));
    }
  }

  Future<void> _google() async {
    await _run(AuthService.instance.signInWithGoogle);
  }

  Future<void> _guest() async {
    if (_busy) return;
    await appData.continueAsGuest();
    if (!mounted) return;
    _finish(false);
  }

  InputDecoration _decoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: tr(label),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.ground,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: <Widget>[
                SizedBox(
                  height: 48,
                  child: _firstLaunch
                      ? null
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: tr('Kembali'),
                            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),
                ),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                    child: CustomPaint(painter: SplashLogoPainter(progress: 1)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _register ? 'Buat akun' : (_firstLaunch ? 'Selamat datang' : 'Masuk dulu, ya'),
                  textAlign: TextAlign.center,
                  style: ts(24, weight: FontWeight.w800, height: 30),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.reason ??
                      (_register
                          ? 'Daftar dengan email, atau langsung pakai akun Google.'
                          : 'Masuk dengan email atau akun Google.'),
                  textAlign: TextAlign.center,
                  style: ts(14, color: AppColors.muted, height: 21),
                ),
                const SizedBox(height: 24),
                GoogleButton(
                  onPressed: _busy ? null : _google,
                  label: _register ? 'Daftar dengan Google' : 'Masuk dengan Google',
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    const Expanded(child: Divider(color: AppColors.line)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('atau pakai email', style: ts(12, color: AppColors.muted)),
                    ),
                    const Expanded(child: Divider(color: AppColors.line)),
                  ],
                ),
                const SizedBox(height: 16),
                if (_register) ...<Widget>[
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.name],
                    decoration: _decoration('Nama lengkap'),
                    validator: (String? v) =>
                        (v == null || v.trim().length < 2) ? 'Isi nama lengkap.' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const <String>[AutofillHints.email],
                  decoration: _decoration('Email'),
                  validator: (String? v) {
                    final String value = (v ?? '').trim();
                    final bool ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
                    return ok ? null : 'Isi email yang valid.';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  textInputAction: _register ? TextInputAction.next : TextInputAction.done,
                  autofillHints: <String>[
                    _register ? AutofillHints.newPassword : AutofillHints.password,
                  ],
                  onFieldSubmitted: (String _) {
                    if (!_register) _submitEmail();
                  },
                  decoration: _decoration(
                    'Password',
                    suffix: IconButton(
                      tooltip: _hidePassword ? tr('Tampilkan password') : tr('Sembunyikan password'),
                      onPressed: () {
                        setState(() {
                          _hidePassword = !_hidePassword;
                        });
                      },
                      icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                  validator: (String? v) {
                    if (v == null || v.isEmpty) return 'Isi password.';
                    if (_register && v.length < 6) return 'Minimal 6 karakter.';
                    return null;
                  },
                ),
                if (_register) ...<Widget>[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (String _) => _submitEmail(),
                    decoration: _decoration('Ulangi password'),
                    validator: (String? v) =>
                        v != _passwordController.text ? 'Password tidak sama.' : null,
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 16),
                  AuthMessageBox(text: _error!, isError: true),
                ],
                if (_info != null) ...<Widget>[
                  const SizedBox(height: 16),
                  AuthMessageBox(text: _info!, isError: false),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submitEmail,
                  style: primaryButtonStyle(),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(_register ? 'Daftar' : 'Masuk'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : _toggleMode,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    textStyle: ts(14, weight: FontWeight.w700),
                  ),
                  child: Text(_register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar'),
                ),
                if (_firstLaunch) ...<Widget>[
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: _busy ? null : _guest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkSoft,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.line),
                      minimumSize: const Size.fromHeight(48),
                      shape: const StadiumBorder(),
                      textStyle: ts(14, weight: FontWeight.w700),
                    ),
                    child: const Text('Lanjut sebagai tamu'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tamu tetap bisa screening. Kalau skor risiko di atas 60%, login diperlukan '
                    'untuk mengisi data diri dan melihat rumah sakit terdekat.',
                    textAlign: TextAlign.center,
                    style: ts(12, color: AppColors.muted, height: 17),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}