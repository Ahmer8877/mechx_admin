import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) => const AdminRepository());

final overviewCountsProvider = StreamProvider.autoDispose<Map<String, int>>((ref) async* {
  final repo = ref.read(adminRepositoryProvider);
  yield await repo.fetchOverviewCounts();

  try {
    yield* supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .handleError((e) => debugPrint('Overview profiles stream error: $e'))
        .asyncMap((_) => repo.fetchOverviewCounts());
  } catch (_) {}
});

final totalEarningsProvider = StreamProvider.autoDispose<double>((ref) async* {
  final repo = ref.read(adminRepositoryProvider);
  yield await repo.fetchTotalEarnings();

  try {
    yield* supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .handleError((e) => debugPrint('Earnings stream error: $e'))
        .asyncMap((_) => repo.fetchTotalEarnings());
  } catch (_) {}
});

final recentBookingsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
  final repo = ref.read(adminRepositoryProvider);
  yield await repo.fetchRecentBookings();

  try {
    yield* supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .handleError((e) => debugPrint('Recent bookings stream error: $e'))
        .asyncMap((_) => repo.fetchRecentBookings());
  } catch (_) {}
});

/// family param: role ('customer' | 'mechanic')
final usersByRoleProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, role) async* {
  final repo = ref.read(adminRepositoryProvider);
  yield await repo.fetchUsers(role: role);

  try {
    yield* supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .handleError((e) => debugPrint('Users by role stream error: $e'))
        .asyncMap((_) => repo.fetchUsers(role: role));
  } catch (_) {}
});

final pendingMechanicsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
  final repo = ref.read(adminRepositoryProvider);
  yield await repo.fetchPendingMechanics();

  yield* supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .handleError((e) => debugPrint('Pending mechanics stream error: $e'))
      .asyncMap((_) => repo.fetchPendingMechanics());
});

/// family param: status filter ('all' or a booking status)
final allBookingsProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, statusFilter) async* {
  final repo = ref.read(adminRepositoryProvider);
  yield await repo.fetchAllBookings(statusFilter: statusFilter);

  try {
    yield* supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .handleError((e) => debugPrint('All bookings stream error: $e'))
        .asyncMap((_) => repo.fetchAllBookings(statusFilter: statusFilter));
  } catch (_) {}
});
