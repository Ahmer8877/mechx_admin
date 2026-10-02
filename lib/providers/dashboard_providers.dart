import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/admin_repository.dart';
import 'admin_realtime_service.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) => const AdminRepository());

final adminRealtimeProvider = Provider<AdminRealtimeService>((ref) {
  final service = AdminRealtimeService.instance;
  service.start();
  return service;
});

Stream<void> _adminEvents(Ref ref) {
  final realtime = ref.read(adminRealtimeProvider);
  return Stream<void>.periodic(const Duration(seconds: 10))
      .mergeWith(realtime.changes);
}

final overviewCountsProvider = StreamProvider.autoDispose<Map<String, int>>((ref) async* {
  final repo = ref.read(adminRepositoryProvider);
  yield await repo.fetchOverviewCounts();
  await for (final _ in _adminEvents(ref)) {
    yield await repo.fetchOverviewCounts();
  }
});

final totalEarningsProvider = StreamProvider.autoDispose<double>((ref) async* {
  final repo = ref.read(adminRepositoryProvider);
  yield await repo.fetchTotalEarnings();
  await for (final _ in _adminEvents(ref)) {
    yield await repo.fetchTotalEarnings();
  }
});

final recentBookingsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
  final repo = ref.read(adminRepositoryProvider);
  yield await repo.fetchRecentBookings();
  await for (final _ in _adminEvents(ref)) {
    yield await repo.fetchRecentBookings();
  }
});

final usersByRoleProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, role) async* {
  final repo = ref.read(adminRepositoryProvider);
  yield await repo.fetchUsers(role: role);
  await for (final _ in _adminEvents(ref)) {
    yield await repo.fetchUsers(role: role);
  }
});

final pendingMechanicsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
  final repo = ref.read(adminRepositoryProvider);
  yield await repo.fetchPendingMechanics();
  await for (final _ in _adminEvents(ref)) {
    yield await repo.fetchPendingMechanics();
  }
});

final allBookingsProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, statusFilter) async* {
  final repo = ref.read(adminRepositoryProvider);
  yield await repo.fetchAllBookings(statusFilter: statusFilter);
  await for (final _ in _adminEvents(ref)) {
    yield await repo.fetchAllBookings(statusFilter: statusFilter);
  }
});

extension _StreamMerge<T> on Stream<T> {
  Stream<T> mergeWith(Stream<T> other) {
    final controller = StreamController<T>();
    late StreamSubscription<T> a;
    late StreamSubscription<T> b;
    var closed = false;

    void closeIfDone() {
      if (!closed) {
        closed = true;
        controller.close();
      }
    }

    a = listen(controller.add, onError: controller.addError, onDone: closeIfDone);
    b = other.listen(controller.add, onError: controller.addError, onDone: closeIfDone);
    controller.onCancel = () async {
      await a.cancel();
      await b.cancel();
    };
    return controller.stream;
  }
}
