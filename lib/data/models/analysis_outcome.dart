class AnalysisOutcome {
  const AnalysisOutcome.ok(this.result)
      : notice = null,
        error = null;
  const AnalysisOutcome.notice(this.notice)
      : result = null,
        error = null;
  const AnalysisOutcome.error(this.error)
      : result = null,
        notice = null;

  final Map<String, dynamic>? result; // terisi bila status server "ok"
  final String? notice; // gambar ditolak / punggung tidak terdeteksi (bukan error)
  final String? error; // masalah koneksi atau server
}