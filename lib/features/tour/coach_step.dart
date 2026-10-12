import 'package:flutter/material.dart';

/// Satu langkah tur: bagian layar yang disorot dan penjelasannya.
class CoachStep {
  const CoachStep({
    required this.target,
    required this.title,
    required this.body,
    this.padding = 6,
    this.radius = 16,
  });

  final GlobalKey target; // widget yang disorot
  final String title;
  final String body;
  final double padding; // jarak sorotan dari tepi widget
  final double radius; // sudut lengkung widget yang disorot
}