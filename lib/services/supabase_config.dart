import 'package:supabase_flutter/supabase_flutter.dart';

/// Connection details for the shared cloud backend. The publishable key is a
/// public client key — it is safe to ship in the app and is protected by the
/// database's row-level security policies. The secret / service_role key is
/// NEVER placed here; it lives only in server-side Edge Functions.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://forcpesacwaektzyslyh.supabase.co';
  static const String publishableKey =
      'sb_publishable_LHfol9Srr5_CmV7HKGuPQg_j6hwE4QV';

  static Future<void> init() async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
