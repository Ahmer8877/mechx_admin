import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) => const AdminRepository());

final overviewCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.read(adminRepositoryProvider).fetchOverviewCounts();
});

final totalEarningsProvider = FutureProvider.autoDispose<double>((ref) {
  return ref.read(adminRepositoryProvider).fetchTotalEarnings();
});

final recentBookingsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).fetchRecentBookings();
});

/// family param: role ('customer' | 'mechanic')
final usersByRoleProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, role) {
  return ref.read(adminRepositoryProvider).fetchUsers(role: role);
});

final pendingMechanicsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).fetchPendingMechanics();
});

/// family param: status filter ('all' or a booking status)
final allBookingsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, statusFilter) {
  return ref.read(adminRepositoryProvider).fetchAllBookings(statusFilter: statusFilter);
});
