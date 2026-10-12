/// Data diri yang diisi pengguna sebelum melihat rujukan rumah sakit.
class PersonalData {
  const PersonalData({
    required this.fullName,
    required this.birthDate,
    required this.gender,
    this.phone = '',
  });

  final String fullName;
  final DateTime birthDate;
  final String gender; // 'Laki-laki' atau 'Perempuan'
  final String phone;

  int get age {
    final DateTime now = DateTime.now();
    int years = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      years--;
    }
    return years;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fullName': fullName,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'phone': phone,
    };
  }

  static PersonalData? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final dynamic name = raw['fullName'];
    final dynamic gender = raw['gender'];
    final DateTime? birth = DateTime.tryParse(raw['birthDate']?.toString() ?? '');
    if (name is! String || gender is! String || birth == null) return null;
    return PersonalData(
      fullName: name,
      birthDate: birth,
      gender: gender,
      phone: raw['phone']?.toString() ?? '',
    );
  }
}