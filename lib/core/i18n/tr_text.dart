import 'dart:ui' as ui;

import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart' hide Text;

import 'app_language.dart';

export 'app_language.dart' show appLanguage, tr;

/// Pengganti widget Text bawaan Flutter yang otomatis menerjemahkan isinya.
///
/// Cara pakai di file lain: ganti
///   import 'package:flutter/material.dart';
/// menjadi
///   import 'package:flutter/material.dart' hide Text;
///   import '<path>/core/i18n/tr_text.dart';
/// lalu Text('...') ditulis seperti biasa (const juga tetap boleh).
/// Untuk teks yang tidak boleh diterjemahkan (nama orang, nama rumah sakit,
/// nama bahasa), tambahkan translate: false.
class Text extends StatelessWidget {
  const Text(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.translate = true,
  }) : textSpan = null;

  const Text.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.translate = true,
  }) : data = null;

  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final ui.TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  final bool translate;

  @override
  Widget build(BuildContext context) {
    final String? d = data;
    if (d != null) {
      return m.Text(
        translate ? tr(d) : d,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel == null || !translate ? semanticsLabel : tr(semanticsLabel!),
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }
    return m.Text.rich(
      translate ? _translateSpan(textSpan!) : textSpan!,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }

  static InlineSpan _translateSpan(InlineSpan span) {
    if (span is! TextSpan) return span;
    return TextSpan(
      text: span.text == null ? null : tr(span.text!),
      style: span.style,
      recognizer: span.recognizer,
      semanticsLabel: span.semanticsLabel,
      children: span.children?.map(_translateSpan).toList(),
    );
  }
}

/// Dipasang sekali di atas MaterialApp. Setiap kali bahasa diganti atau
/// terjemahan baru selesai, semua layar dibangun ulang supaya teksnya ikut berubah
/// (termasuk widget const, dialog, dan bottom sheet).
class LanguageScope extends StatefulWidget {
  const LanguageScope({super.key, required this.child});

  final Widget child;

  @override
  State<LanguageScope> createState() => _LanguageScopeState();
}

class _LanguageScopeState extends State<LanguageScope> {
  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_rebuildAll);
  }

  @override
  void dispose() {
    appLanguage.removeListener(_rebuildAll);
    super.dispose();
  }

  void _rebuildAll() {
    if (!mounted) return;
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}