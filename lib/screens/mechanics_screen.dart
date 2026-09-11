import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_atoms.dart';

class MechanicsScreen extends ConsumerWidget {
  const MechanicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingMechanicsProvider);
    final allAsync = ref.watch(usersByRoleProvider('mechanic'));

    Future<void> setVerified(String id, bool verified) async {
      await ref.read(adminRepositoryProvider).setMechanicVerified(id, verified);
      ref.invalidate(pendingMechanicsProvider);
      ref.invalidate(usersByRoleProvider('mechanic'));
    }

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const Text('Mechanics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Verify new mechanics and review the full roster', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        const SizedBox(height: 20),

        const Text('Pending Verification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        pendingAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
          error: (e, _) => Text('Could not load: $e'),
          data: (pending) {
            if (pending.isEmpty) {
              return SectionCard(
                child: Row(children: const [
                  Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                  SizedBox(width: 10),
                  Text('No mechanics waiting for verification', style: TextStyle(fontSize: 12.5)),
                ]),
              );
            }
            return Column(
              children: pending.map((m) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surface2,
                        child: Text(
                          (m['full_name']?.toString().trim().isNotEmpty ?? false)
                              ? m['full_name'].toString().trim()[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['full_name']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(
                              'CNIC: ${m['cnic_number'] ?? 'Not provided'} · ${m['phone_number'] ?? '—'}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => setVerified(m['id'] as String, false),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => setVerified(m['id'] as String, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 28),
        const Text('All Mechanics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        SectionCard(
          padding: EdgeInsets.zero,
          child: allAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Padding(padding: const EdgeInsets.all(20), child: Text('Could not load: $e')),
            data: (mechanics) {
              if (mechanics.isEmpty) {
                return const Padding(padding: EdgeInsets.all(24), child: Text('No mechanics registered yet.'));
              }
              return DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.surface2),
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Rating')),
                  DataColumn(label: Text('Jobs')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('')),
                ],
                rows: mechanics.map((m) {
                  final verified = m['is_verified'] == true;
                  return DataRow(cells: [
                    DataCell(Text(m['full_name']?.toString() ?? '—')),
                    DataCell(Text(m['phone_number']?.toString() ?? '—')),
                    DataCell(Text('⭐ ${m['rating'] ?? '—'}')),
                    DataCell(Text('${m['total_jobs'] ?? 0}')),
                    DataCell(StatusBadge(status: verified ? 'completed' : 'pending')),
                    DataCell(
                      TextButton(
                        onPressed: () => setVerified(m['id'] as String, !verified),
                        child: Text(verified ? 'Revoke' : 'Verify'),
                      ),
                    ),
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
