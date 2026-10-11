class ScreeningRecord {
  ScreeningRecord({
    required this.id,
    required this.date,
    required this.imagePath,
    required this.result,
  });

  final String id;
  final DateTime date;
  final String imagePath;
  final Map<String, dynamic> result;

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
    );
  }
}