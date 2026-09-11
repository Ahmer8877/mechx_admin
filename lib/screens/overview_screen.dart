import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_atoms.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(overviewCountsProvider);
    final earningsAsync = ref.watch(totalEarningsProvider);
    final bookingsAsync = ref.watch(recentBookingsProvider);
    final currency = NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(overviewCountsProvider);
        ref.invalidate(totalEarningsProvider);
        ref.invalidate(recentBookingsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const Text('Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Live snapshot of your platform', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 22),
          countsAsync.when(
            loading: () => const _StatsSkeleton(),
            error: (e, _) => _ErrorBox(message: 'Could not load stats: $e'),
            data: (counts) => earningsAsync.when(
              loading: () => const _StatsSkeleton(),
              error: (e, _) => const _StatsSkeleton(),
              data: (earnings) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 2.4,
                children: [
                  StatCard(label: 'Total Customers', value: '${counts['customers'] ?? 0}', icon: Icons.people_outline),
                  StatCard(label: 'Total Mechanics', value: '${counts['mechanics'] ?? 0}', icon: Icons.build_circle_outlined, accentColor: AppColors.accent),
                  StatCard(label: 'Total Bookings', value: '${counts['bookings'] ?? 0}', icon: Icons.receipt_long_outlined),
                  StatCard(label: 'Completed Jobs', value: '${counts['completed'] ?? 0}', icon: Icons.check_circle_outline, accentColor: AppColors.success),
                  StatCard(label: 'Total Earnings (Paid)', value: currency.format(earnings), icon: Icons.payments_outlined, accentColor: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Recent Bookings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SectionCard(
            padding: EdgeInsets.zero,
            child: bookingsAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Padding(padding: const EdgeInsets.all(20), child: Text('Could not load bookings: $e')),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(24), child: Text('No bookings yet.'));
                }
                return DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.surface2),
                  columns: const [
                    DataColumn(label: Text('Service')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Mechanic')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Date')),
                  ],
                  rows: bookings.map((b) {
                    final customer = (b['customer'] as Map?)?['full_name'] ?? '—';
                    final mechanic = (b['mechanic'] as Map?)?['full_name'] ?? 'Unassigned';
                    final price = (b['agreed_price'] as num?) ?? (b['budget_price'] as num?) ?? 0;
                    final date = DateTime.tryParse(b['created_at']?.toString() ?? '');
                    return DataRow(cells: [
                      DataCell(Text(b['service_title']?.toString() ?? '—')),
                      DataCell(Text(customer.toString())),
                      DataCell(Text(mechanic.toString())),
                      DataCell(StatusBadge(status: b['status']?.toString() ?? 'pending')),
                      DataCell(Text(currency.format(price))),
                      DataCell(Text(date != null ? DateFormat('d MMM, h:mm a').format(date) : '—')),
                    ]);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 2.4,
      children: List.generate(4, (_) => Container(decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)))),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});
  @override
  Widget build(BuildContext context) {
    return SectionCard(child: Text(message, style: const TextStyle(color: AppColors.danger)));
  }
}
