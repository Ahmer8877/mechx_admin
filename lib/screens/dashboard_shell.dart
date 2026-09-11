import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_auth_provider.dart';
import '../widgets/admin_sidebar.dart';
import 'overview_screen.dart';
import 'customers_screen.dart';
import 'mechanics_screen.dart';
import 'bookings_screen.dart';

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _index = 0;

  static const _screens = [
    OverviewScreen(),
    CustomersScreen(),
    MechanicsScreen(),
    BookingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthProvider);

    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _index,
            onSelect: (i) => setState(() => _index = i),
            adminName: authState.adminName ?? 'Admin',
            onLogout: () => ref.read(adminAuthProvider.notifier).logout(),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F4EF),
              child: _screens[_index],
            ),
          ),
        ],
      ),
    );
  }
}
