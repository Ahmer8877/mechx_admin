import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_atoms.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  String _filter = 'all';

  static const _statuses = ['all', 'pending', 'offered', 'accepted', 'on_the_way', 'in_progress', 'completed', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(allBookingsProvider(_filter));
    final currency = NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bookings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Every booking across the platform', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            DropdownButton<String>(
              value: _filter,
              underline: const SizedBox(),
              items: _statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s == 'all' ? 'All Statuses' : s.replaceAll('_', ' ').toUpperCase())))
                  .toList(),
              onChanged: (v) => setState(() => _filter = v ?? 'all'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          padding: EdgeInsets.zero,
          child: bookingsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Padding(padding: const EdgeInsets.all(20), child: Text('Could not load bookings: $e')),
            data: (bookings) {
              if (bookings.isEmpty) {
                return const Padding(padding: EdgeInsets.all(24), child: Text('No bookings match this filter.'));
              }
              return DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.surface2),
                columns: const [
                  DataColumn(label: Text('Service')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Mechanic')),
                  DataColumn(label: Text('Location')),
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
                    DataCell(SizedBox(width: 160, child: Text(b['pickup_address']?.toString() ?? '—', overflow: TextOverflow.ellipsis))),
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
    );
  }
}
