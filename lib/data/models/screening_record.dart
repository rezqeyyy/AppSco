class ScreeningRecord {
  ScreeningRecord({
    required this.id,
    required this.date,
    required this.imagePath,
    required this.result,
    this.ownerId,
    this.synced = false,
  });

  final String id; // juga dipakai sebagai client_id di Supabase
  final DateTime date;
  String imagePath; // lokasi foto di HP (bisa diisi belakangan saat foto diunduh dari akun)
  final Map<String, dynamic> result;
  String? ownerId; // id akun pemilik; null = dibuat sebagai tamu
  bool synced; // sudah tersimpan di database akun

  double? get riskScore {
    final dynamic v = result['risk_score'];
    return v is num ? v.toDouble() : null;
  }

  String? get riskLevel => result['risk_level']?.toString();

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'image': imagePath,
      'result': result,
      'owner': ownerId,
      'synced': synced,
    };
  }

  static ScreeningRecord? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final DateTime? date = DateTime.tryParse(raw['date']?.toString() ?? '');
    final dynamic result = raw['result'];
    if (date == null || result is! Map) return null;
    final Map<String, dynamic> resultMap = <String, dynamic>{};
    result.forEach((dynamic key, dynamic value) {
      resultMap[key.toString()] = value;
    });
    return ScreeningRecord(
      id: raw['id']?.toString() ?? date.toIso8601String(),
      date: date,
      imagePath: raw['image']?.toString() ?? '',
      result: resultMap,
      ownerId: raw['owner']?.toString(),
      synced: raw['synced'] == true,
    );
  }
}