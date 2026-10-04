import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String adminName;
  final VoidCallback onLogout;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.adminName,
    required this.onLogout,
  });

  static const _items = [
    (Icons.dashboard_outlined, 'Overview'),
    (Icons.people_outline, 'Customers'),
    (Icons.build_circle_outlined, 'Mechanics'),
    (Icons.receipt_long_outlined, 'Bookings'),
    (Icons.support_agent_outlined, 'Help & Support'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.primaryStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'M',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'MechX Admin',
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          ..._items.asMap().entries.map((e) {
            final selected = e.key == selectedIndex;
            return InkWell(
              onTap: () => onSelect(e.key),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.12) : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      e.value.$1,
                      size: 19,
                      color: selected ? AppColors.accent : Colors.white70,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      e.value.$2,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  child: Text(
                    adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    adminName,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onLogout,
                  icon: const Icon(
                    Icons.logout,
                    size: 17,
                    color: Colors.white70,
                  ),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
