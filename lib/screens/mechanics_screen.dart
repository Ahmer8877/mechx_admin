import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_atoms.dart';

class MechanicsScreen extends ConsumerStatefulWidget {
  const MechanicsScreen({super.key});

  @override
  ConsumerState<MechanicsScreen> createState() => _MechanicsScreenState();
}

class _MechanicsScreenState extends ConsumerState<MechanicsScreen> {
  String? _loadingId;

  void _showImagePreview(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        child: SizedBox(
          width: 800,
          height: 600,
          child: Column(
            children: [
              AppBar(
                title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              Expanded(
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Padding(
                        padding: EdgeInsets.all(30),
                        child: Text('Image failed to load', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context, String id, String name) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Verification for $name', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter reason for rejection (this will be shown to the mechanic):', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. CNIC photo is blurry, please re-upload clear photos.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject Verification'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _loadingId = id);
      try {
        await ref.read(adminRepositoryProvider).setMechanicVerified(
              id,
              false,
              notes: result.isEmpty ? 'Verification documents declined by admin.' : result,
            );
        ref.invalidate(pendingMechanicsProvider);
        ref.invalidate(usersByRoleProvider('mechanic'));
      } finally {
        if (mounted) setState(() => _loadingId = null);
      }
    }
  }

  Future<void> _approveMechanic(String id) async {
    setState(() => _loadingId = id);
    try {
      await ref.read(adminRepositoryProvider).setMechanicVerified(id, true);
      ref.invalidate(pendingMechanicsProvider);
      ref.invalidate(usersByRoleProvider('mechanic'));
    } finally {
      if (mounted) setState(() => _loadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingMechanicsProvider);
    final allAsync = ref.watch(usersByRoleProvider('mechanic'));

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const Text('Mechanics Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Review submitted CNIC, profile photo, and workshop documents before approving', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
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
                final id = m['id'].toString();
                final name = m['full_name']?.toString() ?? 'Mechanic';
                final rawCnic = m['cnic_number']?.toString() ?? m['cnic']?.toString();
                final cnic = (rawCnic != null && rawCnic.trim().isNotEmpty) ? rawCnic.trim() : 'Not provided';
                final phone = m['phone_number']?.toString() ?? '—';
                final email = m['email']?.toString() ?? '';
                final cnicFront = m['cnic_front_url']?.toString();
                final cnicBack = m['cnic_back_url']?.toString();
                final rawTools = m['workshop_tools_urls'];
                final isLoading = _loadingId == id;

                List<String> tools = [];
                if (rawTools is List) {
                  tools = rawTools.map((e) => e.toString()).toList();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.surface2,
                            backgroundImage: m['avatar_url'] != null && m['avatar_url'].toString().isNotEmpty
                                ? NetworkImage(m['avatar_url'].toString())
                                : null,
                            child: (m['avatar_url'] == null || m['avatar_url'].toString().isEmpty)
                                ? Text(
                                    name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text(
                                  'CNIC: $cnic · Phone: $phone · Email: $email',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          if (isLoading)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          else ...[
                            OutlinedButton(
                              onPressed: () => _showRejectDialog(context, id, name),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _approveMechanic(id),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                              child: const Text('Approve Mechanic'),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('CNIC NUMBER: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(cnic, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text('SUBMITTED CNIC PHOTOS (CLICK TO ZOOM)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (cnicFront != null && cnicFront.isNotEmpty)
                            _DocumentThumbnail(
                              label: 'CNIC Front',
                              imageUrl: cnicFront,
                              onTap: () => _showImagePreview(context, cnicFront, 'CNIC Front - $name'),
                            ),
                          if (cnicBack != null && cnicBack.isNotEmpty)
                            _DocumentThumbnail(
                              label: 'CNIC Back',
                              imageUrl: cnicBack,
                              onTap: () => _showImagePreview(context, cnicBack, 'CNIC Back - $name'),
                            ),
                        ],
                      ),
                      if (tools.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('WORKSHOP & TOOLS PHOTOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: tools.asMap().entries.map((entry) {
                            return _DocumentThumbnail(
                              label: 'Tool #${entry.key + 1}',
                              imageUrl: entry.value,
                              onTap: () => _showImagePreview(context, entry.value, 'Workshop Tool #${entry.key + 1} - $name'),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 28),
        const Text('All Registered Mechanics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
                  DataColumn(label: Text('CNIC')),
                  DataColumn(label: Text('Rating')),
                  DataColumn(label: Text('Jobs')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('')),
                ],
                rows: mechanics.map((m) {
                  final verified = m['is_verified'] == true;
                  final id = m['id'].toString();
                  final rawCnic = m['cnic_number']?.toString() ?? m['cnic']?.toString();
                  final cnic = (rawCnic != null && rawCnic.trim().isNotEmpty) ? rawCnic.trim() : '—';
                  final vStatus = m['verification_status']?.toString();
                  final statusLabel = verified
                      ? 'approved'
                      : (vStatus == 'rejected' ? 'rejected' : 'pending');

                  return DataRow(cells: [
                    DataCell(Text(m['full_name']?.toString() ?? '—')),
                    DataCell(Text(m['phone_number']?.toString() ?? '—')),
                    DataCell(Text(cnic)),
                    DataCell(Text('⭐ ${m['rating'] ?? '—'}')),
                    DataCell(Text('${m['total_jobs'] ?? 0}')),
                    DataCell(StatusBadge(status: statusLabel)),
                    DataCell(
                      TextButton(
                        onPressed: () => _approveMechanic(id),
                        child: Text(verified ? 'Approved' : 'Verify'),
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

class _DocumentThumbnail extends StatelessWidget {
  final String label;
  final String imageUrl;
  final VoidCallback onTap;

  const _DocumentThumbnail({
    required this.label,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 130,
            height: 85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
