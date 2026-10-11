import 'package:flutter/material.dart';

/// Satu titik tubuh dari server. [pos] berupa pecahan 0-1 dari lebar dan tinggi foto.
class MeasuredPoint {
  const MeasuredPoint(this.name, this.pos, this.conf);

  final String name;
  final Offset pos;
  final double conf;
}