const List<String> _bulan = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String formatDate(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

String formatDayMonth(DateTime d) => '${d.day} ${_bulan[d.month - 1]}';

String formatNumber(double value, int digits) {
  return value.toStringAsFixed(digits).replaceAll('.', ',');
}

String formatPercent(dynamic value) {
  if (value is num) return '${(value * 100).round()}%';
  return '-';
}