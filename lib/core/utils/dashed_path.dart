import 'package:flutter/material.dart' hide Text;

void drawDashedPath(Canvas canvas, Path path, Paint paint, double dash, double gap) {
  for (final metric in path.computeMetrics()) {
    double distance = 0;
    while (distance < metric.length) {
      final double end = distance + dash < metric.length ? distance + dash : metric.length;
      canvas.drawPath(metric.extractPath(distance, end), paint);
      distance += dash + gap;
    }
  }
}