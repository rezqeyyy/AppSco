import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Kotak pesan di layar login: kuning untuk error, hijau untuk info.
class AuthMessageBox extends StatelessWidget {
  const AuthMessageBox({super.key, required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final Color foreground = isError ? AppColors.amber : AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? AppColors.amberTint : AppColors.tealTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isError ? Icons.error_outline : Icons.mark_email_read_outlined,
            size: 20,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: ts(13, weight: FontWeight.w600, color: foreground, height: 19),
            ),
          ),
        ],
      ),
    );
  }
}