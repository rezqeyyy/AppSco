import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/article.dart';
import '../../data/models/screening_record.dart';
import '../../features/education/article_screen.dart';
import '../../features/result/result_screen.dart';
import '../../features/guide/guide_screen.dart';

void openGuide(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (BuildContext context) => const PanduanScreen()),
  );
}

void openArticle(BuildContext context, Article article) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => ArticleScreen(article: article),
    ),
  );
}

void openRecord(BuildContext context, ScreeningRecord record) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => HasilScreen(
        image: File(record.imagePath),
        result: record.result,
        record: record,
      ),
    ),
  );
}