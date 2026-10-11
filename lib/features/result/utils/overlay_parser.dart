import 'package:flutter/material.dart';

import '../../../data/models/measured_point.dart';

/// Membaca "keypoints" dari jawaban server. Kalau ada satu saja yang bentuknya
/// tidak sesuai, hasilnya daftar kosong supaya nomor titik tidak bergeser.
List<MeasuredPoint> parseKeypoints(dynamic raw) {
  if (raw is! List) return const <MeasuredPoint>[];
  final List<MeasuredPoint> out = <MeasuredPoint>[];
  for (final dynamic item in raw) {
    if (item is! Map) return const <MeasuredPoint>[];
    final dynamic x = item['x'];
    final dynamic y = item['y'];
    final dynamic conf = item['conf'];
    if (x is! num || y is! num) return const <MeasuredPoint>[];
    out.add(MeasuredPoint(
      item['name']?.toString() ?? 'titik ${out.length + 1}',
      Offset(x.toDouble(), y.toDouble()),
      conf is num ? conf.toDouble() : 1.0,
    ));
  }
  return out;
}

/// Membaca "overlay.pairs": pasangan nomor titik kiri-kanan yang dihubungkan garis.
List<List<int>> parsePairs(dynamic raw, int pointCount) {
  final List<List<int>> out = <List<int>>[];
  if (raw is! List) return out;
  for (final dynamic item in raw) {
    if (item is! List || item.length != 2) continue;
    final dynamic a = item[0];
    final dynamic b = item[1];
    if (a is! int || b is! int) continue;
    if (a < 0 || b < 0 || a >= pointCount || b >= pointCount) continue;
    out.add(<int>[a, b]);
  }
  return out;
}

/// Membaca "overlay.axis": titik-titik sumbu tubuh berurutan dari atas ke bawah.
List<Offset> parseAxis(dynamic raw) {
  final List<Offset> out = <Offset>[];
  if (raw is! List) return out;
  for (final dynamic item in raw) {
    if (item is! List || item.length != 2) continue;
    final dynamic x = item[0];
    final dynamic y = item[1];
    if (x is! num || y is! num) continue;
    out.add(Offset(x.toDouble(), y.toDouble()));
  }
  return out;
}