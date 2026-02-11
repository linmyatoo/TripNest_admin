import 'package:flutter/material.dart';
import 'features/home/home_page.dart';
import 'features/sales/sales_page.dart';
import 'features/profile/profile_page.dart';
import 'features/create/create_event_page.dart';
import 'core/theme/app_colors.dart';

class AppShell extends StatefulWidget {
  static const route = '/app';
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int idx = 0;
  final _homeKey = GlobalKey<HomePageState>();

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      HomePage(key: _homeKey),
      const CreateEventPage(),
      const SalesPage(),
      const ProfilePage(),
    ];
  }

  void _onTabSelected(int i) {
    setState(() => idx = i);
    // Refresh home page when selecting home tab
    if (i == 0) {
      _homeKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: idx,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(.12),
        selectedIndex: idx,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.add_box_outlined),
              selectedIcon: Icon(Icons.add_box),
              label: 'Create'),
          NavigationDestination(
              icon: Icon(Icons.local_offer_outlined),
              selectedIcon: Icon(Icons.local_offer),
              label: 'Sell'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'My Profile'),
        ],
      ),
    );
  }
}
