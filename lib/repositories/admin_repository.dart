import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// All admin-side Supabase queries live here, behind the RLS "Admins
/// have full access to ..." policies (see supabase_schema.sql).
class AdminRepository {
  const AdminRepository();

  Future<void> _ensureValidSession() async {
    try {
      final session = supabase.auth.currentSession;
      if (session != null && session.isExpired) {
        await supabase.auth.refreshSession();
      }
    } catch (_) {}
  }

  Future<Map<String, int>> fetchOverviewCounts() async {
    await _ensureValidSession();
    try {
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
    } on PostgrestException catch (pe) {
      if (pe.code == 'PGRST303' || pe.message.contains('JWT expired')) {
        try {
          await supabase.auth.refreshSession();
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
        } catch (_) {}
      }
      debugPrint('AdminRepository.fetchOverviewCounts error: $pe');
      rethrow;
    } catch (e) {
      debugPrint('AdminRepository.fetchOverviewCounts error: $e');
      rethrow;
    }
  }

  Future<double> fetchTotalEarnings() async {
    await _ensureValidSession();
    try {
      final rows = await supabase.from('bookings').select('agreed_price').eq('is_paid', true);
      double total = 0;
      for (final row in rows as List) {
        if (row is Map) {
          final price = row['agreed_price'];
          if (price is num) {
            total += price.toDouble();
          } else if (price is String) {
            total += double.tryParse(price) ?? 0;
          }
        }
      }
      return total;
    } on PostgrestException catch (pe) {
      if (pe.code == 'PGRST303' || pe.message.contains('JWT expired')) {
        try {
          await supabase.auth.refreshSession();
          final rows = await supabase.from('bookings').select('agreed_price').eq('is_paid', true);
          double total = 0;
          for (final row in rows as List) {
            if (row is Map) {
              final price = row['agreed_price'];
              if (price is num) {
                total += price.toDouble();
              } else if (price is String) {
                total += double.tryParse(price) ?? 0;
              }
            }
          }
          return total;
        } catch (_) {}
      }
      debugPrint('AdminRepository.fetchTotalEarnings error: $pe');
      rethrow;
    } catch (e) {
      debugPrint('AdminRepository.fetchTotalEarnings error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecentBookings({int limit = 8}) async {
    await _ensureValidSession();
    try {
      final rows = await supabase
          .from('bookings')
          .select(
            'id, service_title, status, agreed_price, budget_price, created_at, customer_id, mechanic_id, '
            'customer:profiles!bookings_customer_id_fkey(full_name), '
            'mechanic:profiles!bookings_mechanic_id_fkey(full_name)',
          )
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      debugPrint('fetchRecentBookings relational query failed ($e), trying manual join fallback...');
      try {
        final rows = await supabase
            .from('bookings')
            .select('id, service_title, status, agreed_price, budget_price, created_at, customer_id, mechanic_id')
            .order('created_at', ascending: false)
            .limit(limit);
        final list = List<Map<String, dynamic>>.from(rows as List);

        final profileIds = <String>{};
        for (final b in list) {
          if (b['customer_id'] != null) profileIds.add(b['customer_id'].toString());
          if (b['mechanic_id'] != null) profileIds.add(b['mechanic_id'].toString());
        }

        if (profileIds.isNotEmpty) {
          final profilesRes = await supabase
              .from('profiles')
              .select('id, full_name')
              .filter('id', 'in', profileIds.toList());
          final profileMap = {
            for (final p in profilesRes as List) p['id'].toString(): p['full_name']
          };
          for (final b in list) {
            final cId = b['customer_id']?.toString();
            final mId = b['mechanic_id']?.toString();
            b['customer'] = {'full_name': profileMap[cId] ?? '—'};
            b['mechanic'] = {'full_name': profileMap[mId] ?? 'Unassigned'};
          }
        }
        return list;
      } catch (e2) {
        debugPrint('fetchRecentBookings fallback failed: $e2');
        rethrow;
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsers({String role = 'customer', String? search}) async {
    await _ensureValidSession();
    try {
      var query = supabase.from('profiles').select().eq('role', role);
      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('full_name', '%${search.trim()}%');
      }
      final rows = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } on PostgrestException catch (pe) {
      if (pe.code == 'PGRST303' || pe.message.contains('JWT expired')) {
        try {
          await supabase.auth.refreshSession();
          var query = supabase.from('profiles').select().eq('role', role);
          if (search != null && search.trim().isNotEmpty) {
            query = query.ilike('full_name', '%${search.trim()}%');
          }
          final rows = await query.order('created_at', ascending: false);
          return List<Map<String, dynamic>>.from(rows as List);
        } catch (_) {}
      }
      debugPrint('AdminRepository.fetchUsers error: $pe');
      rethrow;
    } catch (e) {
      debugPrint('AdminRepository.fetchUsers error: $e');
      rethrow;
    }
  }

  /// Queries all mechanics waiting for verification (is_verified = false and verification_status != 'rejected')
  Future<List<Map<String, dynamic>>> fetchPendingMechanics() async {
    await _ensureValidSession();
    try {
      final rows = await supabase
          .from('profiles')
          .select()
          .eq('role', 'mechanic')
          .eq('is_verified', false)
          .neq('verification_status', 'rejected')
          .not('cnic_front_url', 'is', null)
          .not('cnic_back_url', 'is', null)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } on PostgrestException catch (pe) {
      if (pe.code == 'PGRST303' || pe.message.contains('JWT expired')) {
        try {
          await supabase.auth.refreshSession();
          final rows = await supabase
              .from('profiles')
              .select()
              .eq('role', 'mechanic')
              .eq('is_verified', false)
              .neq('verification_status', 'rejected')
              .not('cnic_front_url', 'is', null)
              .not('cnic_back_url', 'is', null)
              .order('created_at', ascending: false);
          return List<Map<String, dynamic>>.from(rows as List);
        } catch (_) {}
      }
      debugPrint('AdminRepository.fetchPendingMechanics error: $pe');
      rethrow;
    } catch (e) {
      debugPrint('AdminRepository.fetchPendingMechanics error: $e');
      rethrow;
    }
  }

  Future<void> setMechanicVerified(String mechanicId, bool verified, {String? notes}) async {
    await _ensureValidSession();
    await supabase.from('profiles').update({
      'is_verified': verified,
      'verification_status': verified ? 'approved' : 'rejected',
      'verification_notes': notes,
    }).eq('id', mechanicId);
  }

  Future<List<Map<String, dynamic>>> fetchAllBookings({String? statusFilter}) async {
    await _ensureValidSession();
    try {
      var query = supabase.from('bookings').select(
            'id, service_title, status, agreed_price, budget_price, pickup_address, created_at, customer_id, mechanic_id, '
            'customer:profiles!bookings_customer_id_fkey(full_name), '
            'mechanic:profiles!bookings_mechanic_id_fkey(full_name)',
          );
      if (statusFilter != null && statusFilter != 'all') {
        query = query.eq('status', statusFilter);
      }
      final rows = await query.order('created_at', ascending: false).limit(200);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      debugPrint('fetchAllBookings relational query failed ($e), trying manual join fallback...');
      try {
        var query = supabase.from('bookings').select(
              'id, service_title, status, agreed_price, budget_price, pickup_address, created_at, customer_id, mechanic_id',
            );
        if (statusFilter != null && statusFilter != 'all') {
          query = query.eq('status', statusFilter);
        }
        final rows = await query.order('created_at', ascending: false).limit(200);
        final list = List<Map<String, dynamic>>.from(rows as List);

        final profileIds = <String>{};
        for (final b in list) {
          if (b['customer_id'] != null) profileIds.add(b['customer_id'].toString());
          if (b['mechanic_id'] != null) profileIds.add(b['mechanic_id'].toString());
        }

        if (profileIds.isNotEmpty) {
          final profilesRes = await supabase
              .from('profiles')
              .select('id, full_name')
              .filter('id', 'in', profileIds.toList());
          final profileMap = {
            for (final p in profilesRes as List) p['id'].toString(): p['full_name']
          };
          for (final b in list) {
            final cId = b['customer_id']?.toString();
            final mId = b['mechanic_id']?.toString();
            b['customer'] = {'full_name': profileMap[cId] ?? '—'};
            b['mechanic'] = {'full_name': profileMap[mId] ?? 'Unassigned'};
          }
        }
        return list;
      } catch (e2) {
        debugPrint('fetchAllBookings fallback failed: $e2');
        rethrow;
      }
    }
  }
}
