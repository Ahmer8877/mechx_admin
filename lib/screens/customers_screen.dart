import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_atoms.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersByRoleProvider('customer'));

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Row(
          children: [
            const Text(
              'Customers',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => ref.invalidate(usersByRoleProvider('customer')),
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Everyone registered as a customer',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),
        SectionCard(
          padding: EdgeInsets.zero,
          child: usersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Could not load customers: $e'),
            ),
            data: (users) {
              if (users.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No customers yet.'),
                );
              }
              return DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.surface2),
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Joined')),
                ],
                rows: users.map((u) {
                  final date = DateTime.tryParse(
                    u['created_at']?.toString() ?? '',
                  );
                  return DataRow(
                    cells: [
                      DataCell(Text(u['full_name']?.toString() ?? '—')),
                      DataCell(Text(u['phone_number']?.toString() ?? '—')),
                      DataCell(Text(u['email']?.toString() ?? '—')),
                      DataCell(
                        Text(
                          date != null
                              ? DateFormat('d MMM yyyy').format(date)
                              : '—',
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
