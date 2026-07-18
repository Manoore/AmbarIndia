import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppBackend {
  AppBackend._();
  static final instance = AppBackend._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  SupabaseClient? get client => Supabase.instance.client;
  bool get configured => url.isNotEmpty && anonKey.isNotEmpty;

  Future<void> initialize() async {
    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint(
          'Flutter app running in preview mode. Provide SUPABASE_URL and SUPABASE_ANON_KEY to connect live data.');
      return;
    }
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}

class StaffContext {
  const StaffContext(
      {required this.userId,
      required this.email,
      required this.role,
      required this.organizationId,
      required this.locationIds,
      required this.screenAccess});
  final String userId;
  final String email;
  final String role;
  final String? organizationId;
  final List<String> locationIds;
  final List<String> screenAccess;

  bool canView(String screen) =>
      role == 'owner' || role == 'manager' || screenAccess.contains(screen);
}

Future<StaffContext?> loadStaffContext(SupabaseClient client, User user) async {
  final row = await client
      .from('staff_profiles')
      .select('user_id,email,role,organization_id,location_ids,screen_access')
      .eq('user_id', user.id)
      .maybeSingle();
  if (row == null) return null;
  return StaffContext(
      userId: user.id,
      email: row['email'] as String? ?? user.email ?? '',
      role: row['role'] as String? ?? 'cashier',
      organizationId: row['organization_id'] as String?,
      locationIds: List<String>.from(row['location_ids'] ?? const []),
      screenAccess: List<String>.from(row['screen_access'] ?? const []));
}

class LocationRecord {
  const LocationRecord(
      {required this.id,
      required this.name,
      required this.address,
      required this.services});
  final String id;
  final String name;
  final String address;
  final List<String> services;
}

Future<List<LocationRecord>> loadLocations(SupabaseClient client,
    {String? organizationId}) async {
  final rows = organizationId == null
      ? await client
          .from('locations')
          .select('id,name,address,services')
          .eq('is_active', true)
          .order('name')
      : await client
          .from('locations')
          .select('id,name,address,services')
          .eq('is_active', true)
          .eq('organization_id', organizationId)
          .order('name');
  return (rows as List)
      .map((row) => LocationRecord(
          id: row['id'] as String,
          name: row['name'] as String,
          address: row['address'] as String? ?? '',
          services: List<String>.from(row['services'] ?? const [])))
      .toList();
}
