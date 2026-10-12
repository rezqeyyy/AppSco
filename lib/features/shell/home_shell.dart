import 'package:flutter/material.dart';

import '../../state/app_data.dart';
import '../dashboard/dashboard_tab.dart';
import '../education/edukasi_tab.dart';
import '../profil/profil_tab.dart';
import '../history/history_tab.dart';
import '../tour/coach_mark_tour.dart';
import '../tour/home_tour_steps.dart';
import 'widgets/app_bottom_nav.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _touring = false;

  @override
  void initState() {
    super.initState();
    // Pengguna baru langsung diajak tur setelah Beranda tampil.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && appData.loaded && !appData.onboardingDone) {
        _startTour();
      }
    });
  }

  void _goTo(int index) {
    setState(() {
      _index = index;
    });
  }

  void _startTour() {
    setState(() {
      _index = 0; // semua yang disorot ada di Beranda dan menu bawah
      _touring = true;
    });
  }

  void _endTour() {
    setState(() {
      _touring = false;
    });
    appData.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (BuildContext context, Widget? child) {
        if (!appData.loaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Stack(
          children: <Widget>[
            Scaffold(
              body: SafeArea(
                bottom: false,
                child: IndexedStack(
                  index: _index,
                  children: <Widget>[
                    BerandaTab(onOpenTab: _goTo),
                    const RiwayatTab(),
                    const EdukasiTab(),
                    ProfilTab(onShowTutorial: _startTour),
                  ],
                ),
              ),
              bottomNavigationBar: AppBottomNav(index: _index, onChanged: _goTo),
            ),
            if (_touring)
              Positioned.fill(
                child: CoachMarkTour(steps: homeTourSteps, onFinish: _endTour),
              ),
          ],
        );
      },
    );
  }
}