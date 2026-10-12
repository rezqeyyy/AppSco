/// Akun yang sedang masuk (dari Supabase Auth).
class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.provider = 'email',
  });

  final String id; // id pengguna di Supabase (uuid)
  final String name;
  final String email;
  final String? photoUrl;
  final String provider; // 'email' atau 'google'

  bool get isGoogle => provider == 'google';
}