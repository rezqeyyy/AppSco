import 'package:flutter/material.dart';

class Article {
  const Article({
    required this.title,
    required this.shortTitle,
    required this.summary,
    required this.icon,
    required this.body,
  });

  final String title;
  final String shortTitle;
  final String summary;
  final IconData icon;
  final List<String> body; // baris yang diawali "- " ditampilkan sebagai butir daftar
}