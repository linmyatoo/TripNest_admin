import 'package:flutter/material.dart';
import 'features/home/home_page.dart';
import 'features/sales/sales_page.dart';
import 'features/profile/profile_page.dart';
import 'features/create/create_event_page.dart';
import 'features/messages/messages_page.dart';
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
      const MessagesPage(),
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
    // Clear unread when going to messages
    if (i == 2) {
      MessageNotifier().clearUnread();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: idx,
        children: pages,
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: MessageNotifier(),
        builder: (context, _) {
          final unreadCount = MessageNotifier().unreadCount;
          return NavigationBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.primary.withValues(alpha: .12),
            selectedIndex: idx,
            onDestinationSelected: _onTabSelected,
            destinations: [
              const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home'),
              const NavigationDestination(
                  icon: Icon(Icons.add_box_outlined),
                  selectedIcon: Icon(Icons.add_box),
                  label: 'Create'),
              NavigationDestination(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    child: const Icon(Icons.message_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: unreadCount > 0,
                    child: const Icon(Icons.message),
                  ),
                  label: 'Messages'),
              const NavigationDestination(
                  icon: Icon(Icons.local_offer_outlined),
                  selectedIcon: Icon(Icons.local_offer),
                  label: 'Sell'),
              const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile'),
            ],
          );
        },
      ),
    );
  }
}
