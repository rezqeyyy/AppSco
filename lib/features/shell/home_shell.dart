import 'package:flutter/material.dart';

import '../../state/app_data.dart';
import '../dashboard/dashboard_tab.dart';
import '../education/edukasi_tab.dart';
import '../profil/profil_tab.dart';
import '../history/history_tab.dart';
import 'widgets/app_bottom_nav.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _goTo(int index) {
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (BuildContext context, Widget? child) {
        if (!appData.loaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _index,
              children: <Widget>[
                BerandaTab(onOpenTab: _goTo),
                const RiwayatTab(),
                const EdukasiTab(),
                const ProfilTab(),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomNav(index: _index, onChanged: _goTo),
        );
      },
    );
  }
}