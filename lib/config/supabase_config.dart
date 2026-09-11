import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Same Supabase project as the mobile app (mech_app) — the admin
/// dashboard reads/writes the same tables, just with an admin-role
/// account that the RLS "Admins have full access to ..." policies
/// (added in supabase_schema.sql) grant full visibility to.
class SupabaseConfig {
  SupabaseConfig._();

  static Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['PUBLISHABLE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    await Supabase.initialize(url: url, anonKey: key);
  }
}

final SupabaseClient supabase = Supabase.instance.client;
