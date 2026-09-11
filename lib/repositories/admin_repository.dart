import '../config/supabase_config.dart';

/// All admin-side Supabase queries live here, behind the RLS "Admins
/// have full access to ..." policies (see supabase_schema.sql) — the
/// mobile app's repositories are per-domain; this one is a single
/// class because the dashboard's queries are comparatively few and
/// mostly simple reads/aggregates.
class AdminRepository {
  const AdminRepository();

  Future<Map<String, int>> fetchOverviewCounts() async {
    final results = await Future.wait([
      supabase.from('profiles').select('id').eq('role', 'customer').count(),
      supabase.from('profiles').select('id').eq('role', 'mechanic').count(),
      supabase.from('bookings').select('id').count(),
      supabase.from('bookings').select('id').eq('status', 'completed').count(),
    ]);
    return {
      'customers': results[0].count,
      'mechanics': results[1].count,
      'bookings': results[2].count,
      'completed': results[3].count,
    };
  }

  Future<double> fetchTotalEarnings() async {
    final rows = await supabase.from('bookings').select('agreed_price').eq('is_paid', true);
    double total = 0;
    for (final row in rows as List) {
      total += (row['agreed_price'] as num? ?? 0).toDouble();
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> fetchRecentBookings({int limit = 8}) async {
    final rows = await supabase
        .from('bookings')
        .select(
          'id, service_title, status, agreed_price, budget_price, created_at, '
          'customer:profiles!bookings_customer_id_fkey(full_name), '
          'mechanic:profiles!bookings_mechanic_id_fkey(full_name)',
        )
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> fetchUsers({String role = 'customer', String? search}) async {
    var query = supabase.from('profiles').select().eq('role', role);
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('full_name', '%${search.trim()}%');
    }
    final rows = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> fetchPendingMechanics() async {
    final rows = await supabase
        .from('profiles')
        .select()
        .eq('role', 'mechanic')
        .eq('is_verified', false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> setMechanicVerified(String mechanicId, bool verified) async {
    await supabase.from('profiles').update({'is_verified': verified}).eq('id', mechanicId);
  }

  Future<List<Map<String, dynamic>>> fetchAllBookings({String? statusFilter}) async {
    var query = supabase.from('bookings').select(
          'id, service_title, status, agreed_price, budget_price, pickup_address, created_at, '
          'customer:profiles!bookings_customer_id_fkey(full_name), '
          'mechanic:profiles!bookings_mechanic_id_fkey(full_name)',
        );
    if (statusFilter != null && statusFilter != 'all') {
      query = query.eq('status', statusFilter);
    }
    final rows = await query.order('created_at', ascending: false).limit(200);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
