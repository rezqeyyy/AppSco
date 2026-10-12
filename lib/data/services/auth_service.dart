import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_config.dart';
import '../models/user_account.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

/// Login lewat Supabase Auth: email + password, atau akun Google
/// (Google dipilih di HP, lalu ID token-nya diserahkan ke Supabase).
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  bool _supabaseReady = false;
  bool _googleReady = false;

  bool get configured => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Dipanggil sekali saat aplikasi dibuka. Sesi login tersimpan otomatis oleh Supabase.
  Future<void> init() async {
    if (_supabaseReady || !configured) return;
    final Uri? uri = Uri.tryParse(supabaseUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.path.length > 1) {
      _initError = 'supabaseUrl salah. Isi dengan Project URL saja, contoh https://abcd.supabase.co';
      return;
    }
    try {
      await Supabase.initialize(url: supabaseUrl.trim(), publishableKey: supabasePublishableKey.trim());
      _supabaseReady = true;
      _initError = null;
    } catch (e) {
      _initError = 'Supabase gagal disiapkan: $e';
    }
  }

  String? _initError;

  SupabaseClient get client {
    if (!_supabaseReady) {
      throw AuthFailure(
        _initError ??
            'Server akun belum diatur. Isi supabaseUrl dan supabasePublishableKey di app_config.dart.',
      );
    }
    return Supabase.instance.client;
  }

  UserAccount? currentAccount() {
    if (!_supabaseReady) return null;
    final User? user = Supabase.instance.client.auth.currentUser;
    return user == null ? null : _toAccount(user);
  }

  static UserAccount _toAccount(User user) {
    final Map<String, dynamic> meta = user.userMetadata ?? <String, dynamic>{};
    final String name = (meta['full_name'] ?? meta['name'] ?? '').toString();
    final dynamic photo = meta['avatar_url'] ?? meta['picture'];
    return UserAccount(
      id: user.id,
      name: name,
      email: user.email ?? '',
      photoUrl: photo?.toString(),
      provider: user.appMetadata['provider']?.toString() ?? 'email',
    );
  }

  Future<UserAccount> signInWithEmail(String email, String password) async {
    try {
      final AuthResponse res =
          await client.auth.signInWithPassword(email: email, password: password);
      final User? user = res.user;
      if (user == null) throw const AuthFailure('Login gagal. Coba lagi.');
      return _toAccount(user);
    } on AuthException catch (e) {
      throw AuthFailure(_message(e));
    } on SocketException catch (e) {
      throw AuthFailure(_network(e.message));
    }
  }

  /// Hasil null: akun dibuat tapi email perlu dikonfirmasi dulu sebelum bisa masuk.
  Future<UserAccount?> signUpWithEmail(String name, String email, String password) async {
    try {
      final AuthResponse res = await client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{'full_name': name},
      );
      final User? user = res.user;
      // Kalau konfirmasi email aktif, Supabase tidak memberi error untuk email yang
      // sudah terdaftar, tapi daftar identities-nya kosong.
      if (user != null && (user.identities?.isEmpty ?? false)) {
        throw const AuthFailure('Email ini sudah terdaftar. Silakan masuk.');
      }
      if (user == null || res.session == null) return null;
      return _toAccount(user);
    } on AuthException catch (e) {
      throw AuthFailure(_message(e));
    } on SocketException catch (e) {
      throw AuthFailure(_network(e.message));
    }
  }

  /// Hasil null berarti pengguna membatalkan pilihan akun Google.
  Future<UserAccount?> signInWithGoogle() async {
    if (googleServerClientId.isEmpty) {
      throw const AuthFailure(
        'Login Google belum diatur. Isi googleServerClientId di app_config.dart.',
      );
    }
    final SupabaseClient supabase = client;
    try {
      if (!_googleReady) {
        await GoogleSignIn.instance.initialize(serverClientId: googleServerClientId);
        _googleReady = true;
      }
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const AuthFailure('Login Google tidak didukung di perangkat ini.');
      }
      final GoogleSignInAccount google = await GoogleSignIn.instance.authenticate(
        scopeHint: const <String>['email', 'profile'],
      );
      final String? idToken = google.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Google tidak memberi token login. Periksa pengaturan Client ID.');
      }
      String? accessToken;
      try {
        final GoogleSignInClientAuthorization? authorization = await google.authorizationClient
            .authorizationForScopes(const <String>['email', 'profile']);
        accessToken = authorization?.accessToken;
      } catch (_) {
        accessToken = null; // tidak wajib untuk Supabase
      }
      final AuthResponse res = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      final User? user = res.user;
      if (user == null) throw const AuthFailure('Login Google gagal. Coba lagi.');
      return _toAccount(user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthFailure('Login Google gagal (${e.code.name}). Coba lagi sebentar lagi.');
    } on AuthException catch (e) {
      throw AuthFailure(_message(e));
    } on SocketException catch (e) {
      throw AuthFailure(_network(e.message));
    }
  }

  Future<void> signOut() async {
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // abaikan
      }
    }
    if (_supabaseReady) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {
        // Sesi lokal tetap dihapus walaupun server tidak terjangkau.
      }
    }
  }

  /// Pesan untuk gagal terhubung ke server Supabase, dengan detail aslinya
  /// supaya penyebabnya kelihatan (URL salah, izin internet, server sibuk).
  static String _network(String detail) {
    return 'Server akun tidak bisa dihubungi. Periksa koneksi dan supabaseUrl di app_config.dart.\n'
        'Detail: $detail';
  }

  static String _message(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Email atau password salah.';
      case 'email_not_confirmed':
        return 'Email belum dikonfirmasi. Buka link konfirmasi di email Anda dulu.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Email ini sudah terdaftar. Silakan masuk.';
      case 'weak_password':
        return 'Password terlalu lemah. Pakai minimal 6 karakter.';
      case 'email_address_invalid':
        return 'Format email tidak valid.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Terlalu banyak percobaan. Tunggu beberapa menit lalu coba lagi.';
    }
    if (e.code == 'provider_disabled' || e.message.contains('is not enabled')) {
      return 'Login Google belum diaktifkan di server. '
          '(Supabase: Authentication > Sign In / Providers > Google > Enable)';
    }
    if (e is AuthRetryableFetchException) return _network(e.message);
    return 'Login gagal: ${e.message}';
  }
}
