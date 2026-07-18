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

class MenuItemRecord {
  const MenuItemRecord({
    required this.id,
    required this.locationId,
    required this.category,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.available,
  });

  final String id;
  final String locationId;
  final String category;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool available;
}

class OrderRecord {
  const OrderRecord({
    required this.id,
    required this.reference,
    required this.locationId,
    required this.type,
    required this.source,
    required this.status,
    required this.guestName,
    required this.tableNumber,
    required this.total,
    required this.paymentStatus,
    required this.createdAt,
  });

  final String id;
  final String reference;
  final String locationId;
  final String type;
  final String source;
  final String status;
  final String guestName;
  final String? tableNumber;
  final double total;
  final String paymentStatus;
  final DateTime? createdAt;
}

class ReservationRecord {
  const ReservationRecord(
      {required this.id,
      required this.guestName,
      required this.date,
      required this.time,
      required this.partySize,
      required this.status});
  final String id;
  final String guestName;
  final String date;
  final String time;
  final int partySize;
  final String status;
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

Future<List<MenuItemRecord>> loadMenuItems(
    SupabaseClient client, String locationId) async {
  final rows = await client
      .from('menu_items')
      .select(
          'id,location_id,category,name,description,price,image_url,available')
      .eq('location_id', locationId)
      .order('category')
      .order('name');
  return (rows as List)
      .map((row) => MenuItemRecord(
            id: row['id'].toString(),
            locationId: row['location_id'].toString(),
            category: row['category'] as String? ?? 'Menu',
            name: row['name'] as String? ?? 'Menu item',
            description: row['description'] as String? ?? '',
            price: (row['price'] as num?)?.toDouble() ?? 0,
            imageUrl: row['image_url'] as String?,
            available: row['available'] as bool? ?? true,
          ))
      .toList();
}

Future<List<OrderRecord>> loadOrders(SupabaseClient client,
    {String? locationId}) async {
  var query = client.from('orders').select(
      'id,order_reference,location_id,order_type,order_source,status,guest_name,table_number,total,payment_status,created_at');
  if (locationId != null) query = query.eq('location_id', locationId);
  final rows = await query.order('created_at', ascending: false).limit(200);
  return (rows as List)
      .map((row) => OrderRecord(
            id: row['id'].toString(),
            reference:
                row['order_reference'] as String? ?? row['id'].toString(),
            locationId: row['location_id'].toString(),
            type: row['order_type'] as String? ?? 'dine-in',
            source: row['order_source'] as String? ?? 'online',
            status: row['status'] as String? ?? 'new',
            guestName: row['guest_name'] as String? ?? 'Walk-in guest',
            tableNumber: row['table_number'] as String?,
            total: (row['total'] as num?)?.toDouble() ?? 0,
            paymentStatus: row['payment_status'] as String? ?? 'pending',
            createdAt: DateTime.tryParse(row['created_at'].toString()),
          ))
      .toList();
}

Future<void> updateOrderStatus(
    SupabaseClient client, String id, String status) async {
  await client.from('orders').update({'status': status}).eq('id', id);
}

Future<List<ReservationRecord>> loadReservations(
    SupabaseClient client, String locationId) async {
  final rows = await client
      .from('reservations')
      .select(
          'id,guest_name,reservation_date,reservation_time,party_size,status')
      .eq('location_id', locationId)
      .order('reservation_date')
      .order('reservation_time');
  return (rows as List)
      .map((row) => ReservationRecord(
            id: row['id'].toString(),
            guestName: row['guest_name'] as String? ?? 'Guest',
            date: row['reservation_date'].toString(),
            time: row['reservation_time'] as String? ?? '',
            partySize: (row['party_size'] as num?)?.toInt() ?? 1,
            status: row['status'] as String? ?? 'pending',
          ))
      .toList();
}

Future<void> updateReservationStatus(
    SupabaseClient client, String id, String status) async {
  await client.from('reservations').update({'status': status}).eq('id', id);
}

Future<OrderRecord?> createWalkInOrder({
  required SupabaseClient client,
  required String locationId,
  required String orderType,
  required List<MenuItemRecord> items,
  String? guestName,
  String? tableNumber,
}) async {
  if (items.isEmpty) return null;
  final subtotal = items.fold<double>(0, (sum, item) => sum + item.price);
  final reference = 'AD-${DateTime.now().millisecondsSinceEpoch}';
  final row = await client
      .from('orders')
      .insert({
        'location_id': locationId,
        'order_type': orderType,
        'order_source': 'walk-in',
        'guest_name': guestName,
        'table_number': tableNumber,
        'subtotal': subtotal,
        'total': subtotal,
        'payment_method': 'pay-at-counter',
        'payment_status': 'pending',
        'order_reference': reference,
        'access_token': reference,
      })
      .select()
      .single();
  final orderId = row['id'].toString();
  await client.from('order_items').insert(items
      .map((item) => {
            'order_id': orderId,
            'menu_item_id': item.id,
            'name': item.name,
            'unit_price': item.price,
            'quantity': 1,
          })
      .toList());
  return OrderRecord(
      id: orderId,
      reference: reference,
      locationId: locationId,
      type: orderType,
      source: 'walk-in',
      status: 'new',
      guestName: guestName ?? 'Walk-in guest',
      tableNumber: tableNumber,
      total: subtotal,
      paymentStatus: 'pending',
      createdAt: DateTime.now());
}
