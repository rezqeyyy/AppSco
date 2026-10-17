import 'package:flutter/material.dart' hide Text;

import '../../state/app_data.dart';
import '../auth/login_screen.dart';
import '../personal_data/personal_data_screen.dart';
import 'hospital_screen.dart';

/// Alur rujukan untuk skor di atas 60%:
/// login Google (kalau belum) -> data diri (kalau belum) -> rumah sakit terdekat.
/// Kalau pengguna mundur di salah satu langkah, alurnya berhenti.
Future<void> startReferral(
  BuildContext context,
  Map<String, dynamic> result, {
  DateTime? date,
}) async {
  final NavigatorState navigator = Navigator.of(context);

  if (!appData.isSignedIn) {
    final bool? signedIn = await navigator.push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const LoginScreen(
          mode: LoginMode.signInOnly,
          reason: 'Skor risiko Anda di atas 60%. Masuk dengan akun Google untuk mengisi '
              'data diri dan melihat rumah sakit terdekat.',
        ),
      ),
    );
    if (signedIn != true || !appData.isSignedIn) return;
  }

  if (appData.personal == null) {
    final bool? saved = await navigator.push<bool>(
      MaterialPageRoute<bool>(builder: (BuildContext context) => const DataDiriScreen()),
    );
    if (saved != true || appData.personal == null) return;
  }

  await navigator.push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext context) =>
          HospitalScreen(result: result, date: date ?? DateTime.now()),
    ),
  );
}