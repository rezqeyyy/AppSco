//lib\features\dashboard\widgets\language_sheet.dart

import 'package:flutter/material.dart' hide Text;

import '../../../core/i18n/app_language.dart';
import '../../../core/i18n/languages.dart';
import '../../../core/i18n/tr_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Tombol bahasa di bagian atas Beranda.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLanguage,
      builder: (BuildContext context, Widget? child) {
        return Tooltip(
          message: tr('Ganti bahasa'),
          child: Material(
            color: Colors.white,
            shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: appLanguage.downloading ? null : () => showLanguageSheet(context),
              child: SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (appLanguage.downloading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.teal),
                        )
                      else
                        const Icon(Icons.translate, size: 20, color: AppColors.teal),
                      const SizedBox(width: 6),
                      Text(
                        appLanguage.code.toUpperCase(),
                        translate: false,
                        style: ts(14, weight: FontWeight.w800, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showLanguageSheet(BuildContext context) async {
  final String? picked = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext sheetContext) => const _LanguageSheet(),
  );
  if (picked == null || !context.mounted) return;
  await _applyLanguage(context, picked);
}

Future<void> _applyLanguage(BuildContext context, String code) async {
  if (code == appLanguage.code) return;
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
  bool dialogOpen = false;
  if (code != sourceLanguageCode) {
    dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: <Widget>[
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.teal),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      languageByCode(code).nativeName,
                      translate: false,
                      style: ts(15, weight: FontWeight.w800, height: 20),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Menyiapkan bahasa. Paket bahasa diunduh sekali (sekitar 30 MB).',
                      style: ts(13, color: AppColors.muted, height: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  try {
    await appLanguage.setLanguage(code);
  } on LanguageFailure catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Gagal mengganti bahasa: $e')));
  } finally {
    if (dialogOpen) navigator.pop();
  }
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet();

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  String _query = '';

  bool _matches(LanguageOption l) {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return l.nativeName.toLowerCase().contains(q) ||
        l.englishName.toLowerCase().contains(q) ||
        l.code == q;
  }

  @override
  Widget build(BuildContext context) {
    final List<LanguageOption> pinned = <LanguageOption>[
      for (final String c in pinnedLanguageCodes) languageByCode(c),
    ].where(_matches).toList();
    final List<LanguageOption> others = allLanguages
        .where((LanguageOption l) => !pinnedLanguageCodes.contains(l.code))
        .where(_matches)
        .toList()
      ..sort((LanguageOption a, LanguageOption b) => a.englishName.compareTo(b.englishName));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Pilih bahasa', style: ts(20, weight: FontWeight.w800, height: 26)),
                  const SizedBox(height: 4),
                  Text(
                    'Selain Bahasa Indonesia, teks diterjemahkan otomatis oleh mesin di HP, '
                    'jadi mungkin ada kata yang kurang pas.',
                    style: ts(13, color: AppColors.muted, height: 18),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (String v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: tr('Cari bahasa'),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.ground,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                children: <Widget>[
                  if (pinned.isNotEmpty) ...<Widget>[
                    _header('Bahasa utama'),
                    for (final LanguageOption l in pinned) _tile(l),
                  ],
                  if (others.isNotEmpty) ...<Widget>[
                    _header('Bahasa lainnya'),
                    for (final LanguageOption l in others) _tile(l),
                  ],
                  if (pinned.isEmpty && others.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Bahasa tidak ditemukan.',
                        textAlign: TextAlign.center,
                        style: ts(14, color: AppColors.muted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Text(
        text,
        style: ts(12, weight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5),
      ),
    );
  }

  Widget _tile(LanguageOption l) {
    final bool selected = l.code == appLanguage.code;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: selected,
      selectedTileColor: AppColors.tealTint,
      onTap: () => Navigator.of(context).pop(l.code),
      title: Text(
        l.nativeName,
        translate: false,
        style: ts(15, weight: FontWeight.w700, color: AppColors.ink),
      ),
      subtitle: l.nativeName == l.englishName
          ? null
          : Text(l.englishName, translate: false, style: ts(13, color: AppColors.muted)),
      trailing: selected ? const Icon(Icons.check_circle, color: AppColors.teal) : null,
    );
  }
}